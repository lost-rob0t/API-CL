# README #

This repo is a simple client for simple Rest API. i noticed how easy it was to define api via json or making a new api-doc

So i forked it to allow you to create it for any host.



I didn't find a full API on one page, so I gathered it from many pages. You might have to put API details into a JSON file yourself. Check out `api.json` to see how.


## How to Use ##

Please refer to `./example`

### Dependencies ###

I use [yason](https://github.com/phmarek/yason) for json parser, [dexador](https://github.com/fukamachi/dexador) for http client.

### Install ###

This repo has already been deployed to quicklisp. You can simply use `(ql:quickload "api-cl")` to install it.

### Read api.json file ###

Suppose we have `api.json` looks like:

``` json
{
    "repositories": {
        "repositories": {
          "List repositories for a user": {
                "parameters": [
                  ["type", "string"],
                  ["sort","string"],
                  ["direction","string"]
                ],
                "api": "GET /users/:username/repos",
                "link": "https://developer.github.com/v3/repos/#list-repositories-for-a-user"
            }
        }
    }
}
```
**Examples:**

```lisp
;; load system first
(ql:quickload "api-cl")

;; read api.json in this repo, path var is api-doc::*api-json-file-path*
(api-doc:read-api-json) ;; => return a hashtable of this json

;; OR you can give path specially
(api-doc:read-api-json #P"/path/to/api.json")
```

### Generate api instance ###

After read api.json file, you can generate api instance by using `api-doc:make-api-doc-from-json`

**Examples:**

``` lisp
;; read api.json
(defparameter *api-docs* (api-doc:read-api-json))

;; &rest arguments are the steps of reading json
(defparameter *api-doc* (api-doc:make-api-doc-from-json *api-docs* "repositories" "repositories" "List repositories for a user"))

;; Get api-doc: 
;;api-doc object:
;;  api: GET /users/:username/repos,
;;  http method: GET,
;;  slots: (:username),
;;  fmt-control: (/users/~a/repos)
;;  parameters: ((type string) (sort string) (direction string))

;; OR, you can make instance manually
(setf *api-doc* (make-instance 'api-doc
                               :api "GET /users/:username/repos"
                               :parameters '(("type" "string") 
                                             ("sort" "string") 
                                             ("direction" "string")))
```

The `api.json` file is very flexible as it's just a JSON file. You don't have to stick to the GitHub API structure if you don't want to. The only part that `api-cl` is concerned with is this section:

```json
{
  "parameters": [
    ["type", "string"],
    ["sort","string"],
    ["direction","string"]
  ],
  "api": "GET /users/:username/repos",
}
```

You can read this json file and `(api-doc:make-api-doc-from-json (api-doc:read-api-json #P"this-simple-api.json"))`

### Make api client ###

Making api client:

```lisp
;; make instance of api-client
(defparameter *client-without-token* (make-instance 'client:api-client))

;; if you have token for github rest api call, make like this
(defparameter *client-with-token* (make-instance 'client:api-client :token "123"))
```

### Call api ###

With client and api, now we can call api in our code:

```lisp
;; call api with client and api we made before
(client:api-call *client-without-token*
                               *api-doc*)

;;; REPL will ask you to input `:username`, `type`, `sort`, and `direction`
;;; Then, it will return the dex:http-response, you can find this MULTIPLE-VALUEs 
;;; return format in https://github.com/fukamachi/dexador#following-redirects-get-or-head

;; call POST method api with additional :content keyword
(client:api-call *client-without-token*
                               *api-doc*
                               :headers '((header0 . value0) (header1 . value1))
                               :content "this argument pass to dexador directly")
```

`api-call` will call api with the default headers `'(("Accept" . "application/vnd.github+json"))`. Any other headers pass to `:headers` will been added `("Accept" . "application/vnd.github+json")`.

From now, `api-cl`'s job is done, left all http response back to you, you can do whatever you want.

Wait, if you do not want REPL ask you to input every slots and parameters:

```lisp
(client:api-call *client-without-token*
                               *api-doc*
                               :username "lisp"
                               :type "public"
                               :direction "test"
                               :neither-slots-nor-parameter 1) ;; last keyword is redundant
```

With keywords input, REPL won't ask you anything, just call `https://api.github.com/users/lisp/repos?type=\"public\"&direction=\"test\"`. 

As example shows, `:username` fills **api slot**, `:type` & `:direction`  are used for **parameters**. Meanwhile `:neither-slots-nor-parameter` doesn't play any role in this API.

For `POST` method api, `:content` is the keyword for add the content. It pass to `:content` keyword of `dexador`'s `POST` [method](https://github.com/fukamachi/dexador#function-post). Check `./example/gist-cl` to find how to create the gist.

### Authorization ###

**Token, user-name, and passd**

When you need authorization, you can include `:token`, `:user-name` and `:passd` in `client:api-call` as keywords. 

Here's how it works:

+ If you input `:token`, will use token you provided
+ If no `:token` given but client has token already, it will use token stored in client
+ If neither `:token` nor client's token is given, but has `:passd` keyword, will use `:user-name` & `passd` as authorization. (I just assume you give `:user-name` too, when you give `:passd`)
