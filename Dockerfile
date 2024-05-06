# Fetch custom bitcoinj (as a separate step because there's no public chainguard images containing both git and gradle)
FROM cgr.dev/chainguard/git:latest AS bitcoinj-git
RUN git clone https://github.com/natzei/bitcoinj.git \
        && cd bitcoinj \
        && git checkout lib


# Build custom bitcoinj
FROM cgr.dev/chainguard/gradle:latest AS bitcoinj
COPY --from=bitcoinj-git --chown=gradle:gradle /home/git/bitcoinj/ bitcoinj/
RUN cd bitcoinj && ./gradlew publishToMavenLocal -x test


# Fetch specific antlr-generator jar
FROM cgr.dev/chainguard/git:latest AS antlr
RUN wget -O .antlr-generator-3.2.0-patch.jar http://download.itemis.com/antlr-generator-3.2.0-patch.jar


# Compile Balzac
FROM cgr.dev/chainguard/maven:openjdk-17 AS build
ENV MAVEN_OPTS="--add-opens java.base/java.lang=ALL-UNNAMED"

COPY --from=bitcoinj --chown=maven:maven /home/gradle/.m2/ /home/maven/.m2/
COPY --from=antlr --chown=maven:maven /home/git/.antlr-generator-3.2.0-patch.jar balzac/xyz.balzaclang.balzac/

ADD --chown=maven:maven . balzac/

RUN cd balzac && mvn -f xyz.balzaclang.balzac.parent/ clean package && mv xyz.balzaclang.balzac.web/target/*.war xyz.balzaclang.balzac.web/target/balzac.war


# Set up tomcat to run the compiled war
FROM cgr.dev/chainguard/tomcat:latest
ARG WAR_FILE_ARG=balzac.war
ENV WAR_FILE=WAR_FILE_ARG

EXPOSE 8080
HEALTHCHECK CMD curl --fail http://localhost:8080/balzac/version || exit 1
CMD ["run"]

COPY --from=build /home/build/balzac/xyz.balzaclang.balzac.web/target/balzac.war /usr/local/tomcat/webapps/
