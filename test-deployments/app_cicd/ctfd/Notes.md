applications: resusable sections in the website ie. blog, wiki, etc.
- to create application: `python3 manage.py startapp <app-name>` 
- settings.py: all website settings, register applications, static files, database login, etc. also has secret_key used in Django security 

**project structure** 
- ./ctfd: entrypoint into website 
- ./ctfd/urls.py: has url mappings, better to defer to each application 