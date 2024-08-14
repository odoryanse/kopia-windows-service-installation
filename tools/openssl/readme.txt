-----------------------------------------------------------------------
OpenSSL v3.3.1 Win64 for ICS, http://www.overbyte.be
-----------------------------------------------------------------------

More recent versions may be available from:

https://wiki.overbyte.eu/wiki/index.php/ICS_Download#Download_OpenSSL_Binaries

Only supports Windows Vista/Server 2008, and later, not Windows XP.

The legacy.dll provider is optional to support deprecated algorithms,
it needs to be loaded specifically before the following algorithms are
available: ciphers CAST, IDEA, SEED, RC2, RC4, RC5, DESX and DES and
digests MD2, MD4, MDC2 and WHIRLPOOL.

ICS V8.67 or later are required to use these DLLs.

The OpenSSL DLLs and EXE files are digitally code signed 'Magenta
Systems Ltd', one of the organisations that maintains ICS.  ICS can be
set to optonally check the DLLs are correctly signed when opening them.
Beware that Windows needs recent root certificates to check newly signed
code, and may give an error if the root store has not been kept current
by Windows Update, particularly on older versions of Windows such as
Vista, 7 and Windows 2008.

In addition to the three DLL files, the zip includes a compiled RES
resource file that contains the same DLLs, text files and version
information, see the RC file. The RES file may be linked into application
EXE files and code then used to extract the DLLs from the resource to a
temporary directory to avoid distributing them separately.

ICS V9.1 and later optionally support loading the resource file.

Built with:
                  Visual Studio Build Tools 2017
                  The Netwide Assembler (NASM) v2.14.02
                  Strawberry Perl v5.20.3.1

Build Commands:
                  perl configure VC-WIN64A-rtt
                  nmake

Custom configuration file (.conf file at the "Configurations" folder):

## -*- mode: perl; -*-
## Personal configuration targets

%targets = (
    "VC-WIN32-rtt" => {
        inherit_from     => [ "VC-WIN32" ],
        cflags           => sub{my $v=pop; $v=~ s/\/MD/\/MT/ig; return $v},
        lflags           => "/nologo /release",
    },
    "VC-WIN64A-rtt" => {
        inherit_from     => [ "VC-WIN64A" ],
        cflags           => sub{my $v=pop; $v=~ s/\/MD/\/MT/ig; return $v},
        lflags           => "/nologo /release",
    },
);
