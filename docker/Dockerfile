FROM eclipse-temurin:21-jre-jammy
RUN useradd --uid 10001 --create-home lineage
WORKDIR /server
COPY --chown=lineage:lineage dist/ /server/
COPY docker/entrypoint.sh /entrypoint.sh
RUN sed -i 's/\r$//' /entrypoint.sh && mkdir -p /server/gameserver/data/crests && chown lineage:lineage /server/gameserver/data/crests
USER lineage
ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
