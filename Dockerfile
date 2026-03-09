# Używamy oficjalnego obrazu Nginx opartego na lekkim Linuksie Alpine
FROM nginx:alpine

# Kopiujemy nasz plik do katalogu serwera
COPY index.html /usr/share/nginx/html/index.html

# Port, na którym aplikacja nasłuchuje (dokumentacja dla innych programistów)
EXPOSE 80