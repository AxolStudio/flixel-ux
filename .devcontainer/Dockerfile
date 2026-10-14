FROM haxe:4.3.6

RUN apt-get update \
	&& apt-get install -y --no-install-recommends git sudo openjdk-17-jre-headless \
	&& rm -rf /var/lib/apt/lists/* \
	&& useradd --create-home --uid 1000 --shell /bin/bash vscode \
	&& echo "vscode ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/vscode \
	&& chmod 0440 /etc/sudoers.d/vscode

USER vscode

RUN haxelib setup /home/vscode/haxelib \
	&& haxelib install flixel 6.1.2 \
	&& haxelib install actuate \
	&& haxelib install formatter 1.18.0
