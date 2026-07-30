FROM supabase/studio:latest

ENV HOSTNAME=0.0.0.0
ENV PORT=3000

COPY scripts/diagnose-start.js /diagnose-start.js

# Keep the base image CMD as args to this entrypoint
ENTRYPOINT ["node", "/diagnose-start.js"]

EXPOSE 3000
