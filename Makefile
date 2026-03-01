VERSION := $(shell grep '^Version:' flit/DEBIAN/control | awk '{print $$2}')

.PHONY: all deb gen-key repo clean

all: flit.c
	$(CC) flit.c -o ./flit/usr/bin/flt -Wall -Wextra -O3 -pedantic -std=c99
	gzip -kf ./flit/usr/share/man/man1/flt.1

deb: all
	mkdir -p ./flit/usr/share/doc/flit
	gzip -c ./flit/DEBIAN/changelog > ./flit/usr/share/doc/flit/changelog.Debian.gz
	chmod 0755 ./flit/usr/bin/flt
	chmod 0644 ./flit/DEBIAN/control ./flit/DEBIAN/copyright ./flit/DEBIAN/changelog
	dpkg-deb --root-owner-group --build flit flt_$(VERSION)_amd64.deb

# Build the full APT repository structure locally in apt-repo/ for testing.
repo: deb
	mkdir -p apt-repo/pool/main apt-repo/dists/stable/main/binary-amd64
	cp flt_$(VERSION)_amd64.deb apt-repo/pool/main/
	cd apt-repo && dpkg-scanpackages --arch amd64 pool > dists/stable/main/binary-amd64/Packages
	gzip -kf apt-repo/dists/stable/main/binary-amd64/Packages
	cd apt-repo && apt-ftparchive \
		-o APT::FTPArchive::Release::Origin=flit \
		-o APT::FTPArchive::Release::Label=flit \
		-o APT::FTPArchive::Release::Suite=stable \
		-o APT::FTPArchive::Release::Codename=stable \
		-o APT::FTPArchive::Release::Architectures=amd64 \
		-o APT::FTPArchive::Release::Components=main \
		release dists/stable > dists/stable/Release
	gpg --default-key "Flit APT Repository" --armor --detach-sign \
		-o apt-repo/dists/stable/Release.gpg apt-repo/dists/stable/Release
	gpg --default-key "Flit APT Repository" --armor --clearsign \
		-o apt-repo/dists/stable/InRelease apt-repo/dists/stable/Release
	cp flit.gpg apt-repo/flit.gpg
	@echo ""
	@echo "==> Local APT repo built in apt-repo/."

clean:
	rm -f ./flit/usr/bin/flt
	rm -f ./flit/usr/share/man/man1/flt.1.gz
	rm -f ./flit/usr/share/doc/flit/changelog.Debian.gz
	rm -f flt_$(VERSION)_amd64.deb
	rm -rf apt-repo
