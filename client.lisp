;;; client of github api call
(defpackage #:client
  (:use #:CL #:api-doc)
  (:shadow #:get) ;; shadow get from CL
  (:export #:token-p
           #:token
           #:token-p-or-input
           #:api-client
           #:http-call
           #:api-call))

(in-package #:client)

(defclass api-client ()
  ((token
    :initarg :token
    :type string
    :initform ""
    :accessor token)))

(defmethod token-p ((clt api-client))
  "check if client has token"
  (declare (api-client clt))
  (not (string= "" (token clt))))

(defmethod token-p-or-input ((clt api-client))
  "check if client has token, if not, ask to input"
  (if (not (token-p clt))
      (progn
        (format t "Please input your token~%")
        (setf (token clt) (read-line)))))


(defgeneric http-call (client url &rest args &key method &allow-other-keys))

(defmethod http-call ((clt api-client) url &rest args &key (method "get") &allow-other-keys)
  ;; check content and headers first
  (destructuring-bind
      (&key
         content
         (headers '(("Accept" . "application/json")) headers-p)
       &allow-other-keys)
      args
    ;; add the default header when receive the custom ones
    (when headers-p
      (push '("Accept" . "application/json") headers))
    
    (let* ((lambda-list '())
           (call-func (cond
                        ((string= (string-downcase method) "get") #'dex:get)
                        ((string= (string-downcase method) "post")
                         (progn (setf lambda-list (append lambda-list (list :content content)))
                                #'dex:post))
                        ((string= (string-downcase method) "delete") #'dex:delete)
                        ((string= (string-downcase method) "head") #'dex:head)
                        ((string= (string-downcase method) "put") #'dex:put)
                        ((string= (string-downcase method) "patch") #'dex:patch)
                        ((string= (string-downcase method) "fetch") #'dex:fetch))))

      (destructuring-bind
          (&key
             (token (token clt) token-p)
             (user-name "")
             (passd "" passd-p)
             (proxy "" proxy-p)
           &allow-other-keys)
          args
        (cond
          ;; If has token, use token first
          ;; If has token input, use input token, or use client token
          ((or token-p (token-p clt))
           (push (cons "Authorization"
                       (format nil "token ~a" token))
                 headers))

          ;; If neither client's token or keyword token is given
          ;; try use user-name and password
          (passd-p
           (setf lambda-list (append lambda-list (list :basic-auth (cons user-name passd)))))

          ;; give proxy
          (proxy-p
           (setf lambda-list (append lambda-list (list :proxy proxy :insecure t)))))


        (setf lambda-list (append lambda-list (list :headers headers)))

        (apply call-func url lambda-list)))))


(defgeneric api-call (client api &rest args &key &allow-other-keys))

;; Except token, user-name, and passd, all other keywords are parameters for this api
(defmethod api-call ((clt api-client) (api api-doc) &rest args)
  (let* ((url (apply #'make-call-url api args))
         (parameters (apply #'make-call-parameters api args))
         (whole-url (concatenate 'string url parameters)))

    (apply #'http-call
           clt
           whole-url
           :method (http-method api)
           args)))
