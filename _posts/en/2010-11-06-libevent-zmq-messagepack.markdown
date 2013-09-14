---
layout: post
lang: en
date: 2010-11-06 00:30:45
permalink: /archives/77
tags: [tech]
title: Dispatching flood GET requests from web browsers with libevent, ØMQ(zeromq/zmq) and MessagePack.
wordpress_id: 77
---
This is a simple sample code which recieves request from web browser with libevent and dispatch messages with ØMQ(zeromq/zmq) and MessagePack.

- When web server receives GET request, get paramter is converted to msgpack's map and it is sent to a client.
- Web server returns JSON. If get parameter `callback' is specified, it returns JSONP of which function name is the `callback' parameter.
- The client recieves msgpack's map and print it to stdout. You can write some logics like logging instead printing.

Web server
<pre class="prettyprint linenums lang-c">
#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <sys/time.h>
#include <stdlib.h>
#include <err.h>

#include <sys/queue.h>
#ifndef TAILQ_FOREACH
#define TAILQ_FOREACH(var, head, field) \
  for ((var) = ((head)->tqh_first); \
    (var); \
    (var) = ((var)->field.tqe_next))
#endif /* LIST_FOREACH */
#include <zmq.h>
#include <event.h>
#include <evhttp.h>
#include <msgpack.h>

#define PORT 8080

void
generic_handler(struct evhttp_request *req, void *zmq_sock)
{
  struct evkeyvalq args;
  char *jsonp_func = NULL;

  if (!req->uri) { return; }

  {
    char *uri = evhttp_decode_uri(req->uri);
    evhttp_parse_query(uri, &args);
    free(uri);
  }

  {
    struct evkeyval *get;
    msgpack_packer pk;
    msgpack_sbuffer sbuf;

    msgpack_sbuffer_init(&sbuf);
    msgpack_packer_init(&pk, &sbuf, msgpack_sbuffer_write);
    {
      unsigned int cnt = 0;
      TAILQ_FOREACH(get, &args, next) {
        if (!strcmp(get->key, "callback")) {
          jsonp_func = get->value;
        } else {
          cnt++;
        }
      }
      msgpack_pack_map(&pk, cnt);
    }
    TAILQ_FOREACH(get, &args, next) {
      if (get->value != jsonp_func) {
        unsigned int l;
        l = strlen(get->key);
        msgpack_pack_raw(&pk, l);
        msgpack_pack_raw_body(&pk, get->key, l);
        l = strlen(get->value);
        msgpack_pack_raw(&pk, l);
        msgpack_pack_raw_body(&pk, get->value, l);
      }
    }
    {
      zmq_msg_t msg;
      if (!zmq_msg_init_size(&msg, sbuf.size)) {
        memcpy((void *)zmq_msg_data(&msg), sbuf.data, sbuf.size);
        zmq_send(zmq_sock, &msg, 0);
        zmq_msg_close(&msg);
      }
    }
    msgpack_sbuffer_destroy(&sbuf);
  }
  {
    struct evbuffer *res_buf;
    if (!(res_buf = evbuffer_new())) {
      err(1, "failed to create response buffer");
    }

    evhttp_add_header(req->output_headers,
      "Content-Type", "text/javascript; charset=UTF-8");
    evhttp_add_header(req->output_headers, "Connection", "close");

    if (jsonp_func) {
      char num_buf[16];
      unsigned int jsonp_func_len = strlen(jsonp_func);
      evbuffer_add(res_buf, jsonp_func, jsonp_func_len);
      evbuffer_add(res_buf, "({});", 5);
      snprintf(num_buf, 16, "%d", jsonp_func_len + 5);
      evhttp_add_header(req->output_headers, "Content-Length", num_buf);
    } else {
      evbuffer_add(res_buf, "{}", 2);
      evhttp_add_header(req->output_headers, "Content-Length", "2");
    }
    evhttp_send_reply(req, HTTP_OK, "OK", res_buf);
    evbuffer_free(res_buf);
  }
  evhttp_clear_headers(&args);
}

int
main(int argc, char **argv)
{
  struct evhttp *httpd;

  event_init();

  if (httpd = evhttp_start("0.0.0.0", PORT)) {
    void *zmq_ctx, *zmq_sock;

    if (!(zmq_ctx = zmq_init(1))) {
      fprintf(stderr, "cannot create zmq context.");
    } else {
      if (!(zmq_sock = zmq_socket(zmq_ctx, ZMQ_PUB))) {
        fprintf(stderr, "cannot create zmq_socket.");

      } else if (zmq_connect(zmq_sock, "tcp://127.0.0.1:1234")) {
        fprintf(stderr, "cannot connect zmq_socket.");
      } else {
        evhttp_set_gencb(httpd, generic_handler, zmq_sock);
        event_dispatch();

        evhttp_free(httpd);
      }
      zmq_term(zmq_ctx);
    }
  } else {
    fprintf(stderr, "cannot bind port %d", PORT);
  }
  return 0;
}
</pre>

client
<pre class="prettyprint linenums lang-c">
#include <zmq.h>
#include <stdio.h>
#include <msgpack.h>

int
main(int argc, char **argv)
{
  msgpack_zone *mempool;

  if (!(mempool = msgpack_zone_new(MSGPACK_ZONE_CHUNK_SIZE))) {
    fprintf(stderr, "cannot create msgpack zone.");
  } else {
    void *zmq_ctx, *zmq_sock;
    if (!(zmq_ctx = zmq_init(1))) {
      fprintf(stderr, "cannot create zmq context.");
    } else {
      if (!(zmq_sock = zmq_socket(zmq_ctx, ZMQ_SUB))) {
        fprintf(stderr, "cannot create zmq_socket.");

      } else if (zmq_bind(zmq_sock, "tcp://*:1234")) {
        fprintf(stderr, "cannot bind zmq_socket.");
      } else {
        zmq_pollitem_t items[] = {
          { zmq_sock, 0, ZMQ_POLLIN, 0}
        };
        zmq_setsockopt(zmq_sock, ZMQ_SUBSCRIBE, "", 0);
        while (1) {
          zmq_poll(items, 1, -1);
          if (items[0].revents & ZMQ_POLLIN) { /* always true */
            zmq_msg_t msg;
            if (zmq_msg_init(&msg)) {
              fprintf(stderr, "cannot init zmq message.");
            } else {
              if (zmq_recv(zmq_sock, &msg, 0)) {
                fprintf(stderr, "cannot recv zmq message.");
              } else {
                msgpack_object obj;
                msgpack_unpack_return ret;
                ret = msgpack_unpack(zmq_msg_data(&msg), zmq_msg_size(&msg), NULL, mempool, &obj);
                if (MSGPACK_UNPACK_SUCCESS == ret) {
                  msgpack_object_print(stdout, obj);
                  printf("\n");
                }
              }
              zmq_msg_close(&msg);
            }
          }
        }
      }
      zmq_term(zmq_ctx);
    }
    msgpack_zone_free(mempool);
  }
  return 0;
}
</pre>

Makefile
<pre class="prettyprint linenums lang-makefile">
all: suggest-client suggest-server

suggest-server: suggest-server.c
  gcc -O3 -ggdb -o suggest-server suggest-server.c -lzmq -levent -lmsgpack

suggest-client: suggest-client.c
  gcc -O3 -ggdb -o suggest-client suggest-client.c -lzmq -levent -lmsgpack
</pre>
