server {
    listen {{ app.port }};

    server_tokens off;
    # Redirect HTTP to HTTPS - {{ app.https }}
    if ($scheme = https) {
       return 301 http://$server_name$request_uri;
    }

    server_name {{ app.name_index }} {{ app.domain_name }};
    root {{ app.docroot }};

    index {{ app.index }}; 
    location / {

       try_files $uri /{{ app.index }}?$query_string; 
    }

    location @rewrite {
       rewrite ^/(.*)$ /{{ app.index }}?q=$1 last;
    }

    # PROD
    location ~ \.php$ {
      try_files $uri =404;
      fastcgi_pass {{ app.fastcgi_pass }};
      fastcgi_split_path_info ^(.+\.php)(/.*)$;
      include fastcgi_params;
      aio threads;
      fastcgi_index  {{ app.index }};
      fastcgi_param  SCRIPT_FILENAME  $realpath_root$fastcgi_script_name;
      fastcgi_param DOCUMENT_ROOT     $realpath_root;
      fastcgi_param  SCRIPT_NAME      $fastcgi_script_name;
      fastcgi_param  QUERY_STRING     $query_string;
      fastcgi_param  REQUEST_METHOD   $request_method;
      fastcgi_param  CONTENT_TYPE     $content_type;
      fastcgi_param  CONTENT_LENGTH   $content_length;
      fastcgi_intercept_errors        on;
      fastcgi_ignore_client_abort     off;
      fastcgi_connect_timeout 60;
      fastcgi_send_timeout 180;
      fastcgi_read_timeout 180;
      fastcgi_buffer_size 128k;
      fastcgi_buffers 4 256k;
      fastcgi_busy_buffers_size 256k;
      fastcgi_temp_file_write_size 256k; 

      # configurações da aplicacao
      fastcgi_param APP_ENV {{ app.env }};
      fastcgi_param APP_DEBUG {{ app.debug }};
      fastcgi_param APP_SECRET {{ app.secret }};
      fastcgi_param DATABASE_URL "{{ app.database_url }}";
      fastcgi_param MAILER_URL "{{ app.smtp }}";
      fastcgi_param GOOGLE_APPLICATION_CREDENTIALS "{{ app.path }}/{{ app.google_credentials }}";
      fastcgi_param APP_BUCKET "{{ app.bucket }}";
      fastcgi_param APP_NAME "{{ app.name }}";
      fastcgi_param WKHTMLTOPDF_PATH /usr/bin/wkhtmltopdf;
      fastcgi_param WKHTMLTOIMAGE_PATH /usr/bin/wkhtmltoimage;
   } 
    location ~* \.(js|css|png|jpg|jpeg|gif|ico)$ {
        expires max;
        log_not_found off;
    }

    error_log /var/log/nginx/{{ app.name_index }}-error.log;
    access_log /var/log/nginx/{{ app.name_index }}-access.log combined;
}