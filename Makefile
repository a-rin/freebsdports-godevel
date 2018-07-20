# Created by: Devon H. O'Dell <devon.odell@gmail.com>
# $FreeBSD: head/lang/go/Makefile 473326 2018-06-25 15:59:49Z adamw $

PORTNAME=	go-devel
PORTVERSION=	1.11beta2
CATEGORIES=	lang
MASTER_SITES=	https://dl.google.com/go/
DISTNAME=	go${PORTVERSION}.src

MAINTAINER=	a.rin.mix@gmail.com
COMMENT=	Go programming language

LICENSE=	BSD3CLAUSE

BUILD_DEPENDS=	go14>=1.4:lang/go14
CONFLICTS=	lang/go

USES=		shebangfix
SHEBANG_LANG=	sh perl
SHEBANG_FILES=	src/*.bash \
		doc/articles/wiki/*.bash \
		lib/time/*.bash \
		misc/benchcmp \
		misc/nacl/go_nacl_*_exec \
		src/cmd/go/*.sh \
		src/net/http/cgi/testdata/*.cgi \
		src/regexp/syntax/*.pl

sh_OLD_CMD=	"/usr/bin/env bash"
sh_CMD=		${SH}

WRKSRC=		${WRKDIR}/go
ONLY_FOR_ARCHS=	i386 amd64 armv6 armv7

OPTIONS_DEFINE=	GO387
GO387_DESC=	Do not generate code with SSE2 (for old x86 CPU)

.include <bsd.port.pre.mk>

.if ${ARCH} == i386
GOARCH=386
.elif ${ARCH} == "amd64"
GOARCH=amd64
.elif ${ARCH} == armv6 || ${ARCH} == armv7
GOARCH=arm
.else
IGNORE=		unknown arch ${ARCH}
.endif

.if ${PORT_OPTIONS:MGO387}
GO386=387
.endif

PLIST_SUB+=	opsys_ARCH=${OPSYS:tl}_${GOARCH}

post-patch:
	@cd ${WRKSRC} && ${FIND} . -name '*.orig' -delete

do-build:
	cd ${WRKSRC}/src && \
		GOROOT=${WRKSRC} GOROOT_FINAL=${PREFIX}/go \
		GOROOT_BOOTSTRAP=${LOCALBASE}/go14 \
		GOBIN= GOARCH=${GOARCH} GOOS=${OPSYS:tl} \
		GO386=${GO386} \
		${SH} make.bash -v
	${RM} -r ${WRKSRC}/pkg/obj

do-install:
	@${CP} -a ${WRKSRC} ${STAGEDIR}${PREFIX}
.for f in go gofmt
	@${LN} -sf ../go/bin/${f} ${STAGEDIR}${PREFIX}/bin/${f}
.endfor

do-test:
	cd ${WRKSRC}/src && GOROOT=${WRKSRC} PATH=${WRKSRC}/bin:${PATH} ${SH} run.bash --no-rebuild --banner

pkg-plist: stage
	${RM} ${WRKDIR}/pkg-plist
.for command in go gofmt
	${ECHO_CMD} bin/${command} >> ${WRKDIR}/pkg-plist
.endfor
	cd ${WRKDIR} && ${FIND} go -type f | \
		${SED} -e "s/\/${OPSYS:tl}_${GOARCH}\//\/%%opsys_ARCH%%\//g" | \
		${SORT} >> ${WRKDIR}/pkg-plist
	${CP} ${WRKDIR}/pkg-plist ${.CURDIR}/pkg-plist

.include <bsd.port.post.mk>
