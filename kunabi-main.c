/*
 * kunabi-main.c — Custom entry point for kunabi.
 *
 * Boot files (petite.boot, scheme.boot, app.boot) are embedded as C byte
 * arrays and registered via Sregister_boot_file_bytes.
 *
 * The program is included in the app boot file, so Sscheme_start runs it
 * directly after Sbuild_heap — no memfd or Sscheme_script needed.
 */

#include <stdlib.h>
#include <stdio.h>
#include "scheme.h"
#include "kunabi_petite_boot.h"
#include "kunabi_scheme_boot.h"
#include "kunabi_app_boot.h"

int main(int argc, char *argv[]) {
    Sscheme_init(NULL);
    Sregister_boot_file_bytes("petite", (void*)petite_boot_data, petite_boot_size);
    Sregister_boot_file_bytes("scheme", (void*)scheme_boot_data, scheme_boot_size);
    Sregister_boot_file_bytes("app", (void*)kunabi_app_boot_data, kunabi_app_boot_size);

    Sbuild_heap("kunabi", NULL);
    int status = Sscheme_start(argc, (const char **)argv);

    Sscheme_deinit();
    return status;
}
