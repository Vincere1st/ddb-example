local ddb = import 'ddb.docker.libjsonnet';

local domain_ext = std.extVar("core.domain.ext");
local domain_sub = std.extVar("core.domain.sub");

local domain = std.join('.', [domain_sub, domain_ext]);

ddb.Compose({
	services: {
		db: ddb.Build("postgres") + ddb.User() +
		    ddb.Binary("psql", "/project", "psql --dbname=postgresql://postgres:ddb@db/postgres") +
		    ddb.Binary("pg_dump", "/project", "pg_dump --dbname=postgresql://postgres:ddb@db/postgres") +
		  {
		    environment+: {POSTGRES_PASSWORD: "ddb"},
		    volumes+: [
          'db-data:/var/lib/postgresql/data',
          ddb.path.project + ':/project'
		    ]
		  },
    php: ddb.Build("php") +
         ddb.User() +
         ddb.Binary("composer", "/var/www/html", "composer") +
         ddb.Binary("php", "/var/www/html", "php") +
         ddb.Binary("symfony", "/var/www/html", "symfony") +
         ddb.XDebug() +
         {
          volumes+: [
             ddb.path.project + ":/var/www/html",
             ddb.path.project + "/.docker/php/conf.d/php-config.ini:/usr/local/etc/php/conf.d/php-config.ini:ro",
             "php-composer-cache:/composer/cache",
             "php-composer-vendor:/composer/vendor"
          ]
         },
    node: ddb.Build("node") +
              ddb.User() +
              ddb.Binary("node", "/app", "node", exe=true) +
              ddb.Binary("npm", "/app", "npm", exe=true) +
              ddb.Binary("npx", "/app", "npx", exe=true) +
              ddb.Binary("vue", "/app", "vue", exe=true) +
              ddb.Binary("ncu", "/app", "ncu", exe=true) +
              (if ddb.env.is("dev") then ddb.VirtualHost("8080", ddb.domain, "main") else {}) +
             {
                  volumes+: [
                     ddb.path.project + ":/app",
                     "node-cache:/home/node/.cache",
                     "node-npm-packages:/home/node/.npm-packages"
                  ],
                  tty: true
              },
    web: ddb.Build("web") +
             ddb.VirtualHost("80", ddb.subDomain("api"), "api") +
   		     (if !ddb.env.is("dev") then ddb.VirtualHost("80", ddb.domain, "main") else {}) +
             {
                  volumes+: [
                     ddb.path.project + ":/var/www/html",
                     ddb.path.project + "/.docker/web/apache.conf:/usr/local/apache2/conf/custom/apache.conf"
                  ]
              },
    },
})