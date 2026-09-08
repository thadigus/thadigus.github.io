---
title: "BSides Fort Wayne 2025 Conference - Badge Challenge 2 Writeup"
header: 
  teaser: /assets/images/
  header: /assets/images/
  og_image: /assets/images/
excerpt: "The 2025 Fort Wayne BSides badge was utilized for the CTF challenge hosted at the event. For challenge 2 we wanted to emulate the idea of stealing signing keys from the firmware of a device. I created a pair of SSH keys and encrypted the private key. A base64 encoded flag was then AES encrypted using the RSA private key and then publicly stored in the git repo as well as on the device itself."
tags: [bsides, writeup, badge, challenge]
---
## BSides Fort Wayne 2025 CTF - Key Validation

The 2025 Fort Wayne BSides badge was utilized for the CTF challenge hosted at the event. For challenge 2 we wanted to emulate the idea of stealing signing keys from the firmware of a device. I created a pair of SSH keys and encrypted the private key. A base64 encoded flag was then AES encrypted using the RSA private key and then publicly stored in the git repo as well as on the device itself.

The intended way to solve this challenge is to run strings against the main firmware binary that is publicly hosted or can pulled off the device. The firmware binary can be found [here](https://github.com/BSidesFortWayne/BSidesFW2025Badge/blob/main/firmware/BSFWCustom_firmware_SPIRAM_with_GC9A01.bin). The encrypted driver containing the flag can be found [here](https://github.com/BSidesFortWayne/BSidesFW2025Badge/blob/main/src/drivers/encrypted_driver.bin).

#### Challenge Code

The challenge code is integrated into an app on the device to encourage the end users to investigate the code further. The simple code below shows the application that is on the device. When launched, the two LCD screens are blanked, and they will show the text "Verifying Keys...", then a thread is started where the challenge 2 code is started. This takes a few seconds to run the C code and it prints a few things out to the serial port. It is suggested in the code that the challenge 2 thread is verifying a set of keys or firmware on the device. This should clue users into investigating the MicroPython binary for keys that are used to sign other code.

[/apps/badgechal2.py](https://github.com/BSidesFortWayne/BSidesFW2025Badge/blob/main/src/apps/badgechal2.py)

```python
from lib.smart_config import Config
from icontroller import IController
import badgechal
from apps.app import BaseApp
import vga1_bold_16x32
import micropython
import _thread

class BadgeChal2(BaseApp):
    name = "CTF Challenge 2"
    def __init__(self, controller):
        super().__init__(controller)
        self.controller = controller
        self.display1 = self.controller.bsp.displays.display1
        self.display2 = self.controller.bsp.displays.display2

    async def setup(self):
        self.display1.text(vga1_bold_16x32, "Verifying", 50, 100)
        self.display2.text(vga1_bold_16x32, "Keys...", 70, 100)
        print("Running Badge Challenge 2")
        _thread.start_new_thread(badgechal.chal2, ())
        return None
```

#### Solve Process

The solve process starts with running the `strings` utility against the firmware binary. Users will find a set of strings intentionally left over from the C code that show the private key, public key, and a password. Here is a snippet of the strings command:

```
lnZgAy~^dY[F
AAcMd^Xnis}bzkg
@Loading RSA Keys Into Memory...
-----BEGIN ENCRYPTED PRIVATE KEY-----
MIIC5TBfBgkqhkiG9w0BBQ0wUjAxBgkqhkiG9w0BBQwwJAQQladNFlzxwGIFVQQz
mkqT7wICCAAwDAYIKoZIhvcNAgkFADAdBglghkgBZQMEASoEEA1B7L1VIXL39OF6
HsRfvlQEggKATVkUVs3CJM+SLTYr9vGBG/OHTeAZZPCYUheXSmMKBXKf8jta+8vy
E6k3wtVYHbl2tnPx0H/h4cf+FocCM501wctFOsvrgJ1UQr+YkBeISKwdbC/epDTZ
4bFuauREn+5eYn30I1UOIbpI8VgYgliWfEI9MIwRWBVDnUBTSMF4zVHADSpCX+xw
Ogxg7swS514na9XzB2rWYH4cph3IbJZN7rMOts2EoIDMw1u+eOf8Bvl6mmmNxSxC
MVoLu1vzikwOe7Nuwvk1lFQ8vqw/VmcyMrRYbSMDA7h9ztgio7xcL5AFDzV6LhUY
Ttp5D9N+FTS+XuKaumYimwj8LzqjOzkzhtyCBUDzDWdA+p/a2s05V55wABj9Yhen
PqOr9yercvLugK8mb/X73MsCcubrGBAYvQlg+53WbyF4rZkAW3jFUuw0i/GuwUbB
6BtSfs7JeUe1qw4Ijg5v0fku+SWbf0ZX8GBD8oLy68bte4NEBs1AA3DaNnCfRnQh
aR4F5waFYrUajZkqN6bxU5SKIpjE/8qqlRzyNS7OmLFvTPLrr52i+ZcaaehUeXrc
C2kYnmI3Tt4JTdaZFhluvuKhIDLkUjDDO5/4lkD/NcHPlwAAeR30VP13cASUnb31
hv6ZwhJlENuUy49amiohS0JI33tTaTB/slNeo3X7Bt8tqwlzLv0jcZ+BRQr1vUc9
8wr6+vLthOxpVEYewoouzTEaamb3xN2mzFxSSRd+u3P+SmpnPUfa5ADLOge97FwH
/9juSiAfCiR1O0OiwZe6m5Ak628d0bv09kDdHJQ9pKprqMbA3NJ73mirILEPwoaL
HR8WtrmmSb8ZXPof6rJ2sJw5DuDwmcx3TA==
-----END ENCRYPTED PRIVATE KEY-----
-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC7xyGTRl+C1sICMHW0Q48o4gk5
AgWCM2AWqV6tDL5zA0ur9feWt+vcJp9h/mQa7GNbo45W/phNXRCRIinVLXnwx8I5
l8iSMO+WjdBUCvCKAcdq1svFQ60Fd9nOcZoQWjY/StWV4A8OND4tkQhDnt/uUG7M
M2U9xkwH4u212ItvsQIDAQAB
-----END PUBLIC KEY-----
It'sTh3RSAP@$$
Failed to parse private key
char
indices
```

Now that we have the private key, we can save it to the `challenge_rsa` file, and use it to decrypt the encrypted driver. The commands below show the process, as we use strings to get the files, then we use `openssl` to decrypt the encrypted driver. This will prompt the user for a password which was found in the strings output as well: `It'sTh3RSAP@$$`. From there we receive a base64 encoded string which is easily decoded into the flag.

```shell
λ archlaptop BadgeFirmware → λ git main* → strings BSFWCustom_firmware_SPIRAM_with_GC9A01.bin less
λ archlaptop BadgeFirmware → λ git main* → openssl rsautl -decrypt -inkey challenge_rsa -in encrypted_driver.bin
The command rsautl was deprecated in version 3.0. Use 'pkeyutl' instead.
Enter pass phrase for trying_rsa:
YnNmdHd7NDJNem1PQ3ZOelBJODg0SThXNHZRMmNiVVZSanVBM059Cg==
λ archlaptop BadgeFirmware → λ git main* → echo 'YnNmdHd7NDJNem1PQ3ZOelBJODg0SThXNHZRMmNiVVZSanVBM059Cg==' | base64 -d
bsftw{42MzmOCvNzPI884I8W4vQ2cbUVRjuA3N}
```

#### C Challenge Code - Compiled into MicroPython

The C code for this challenge is actually more complicated than it needs to be. Since we just need to pull the strings out of the binary, we could just put the strings in here and do nothing with the function. Instead, we wrote an actual function to check the keys and verify that they match. Below is the C code to decrypt the private key, and then verify it against the stored public key. We had to add a 5 second delay in between steps to actually make it seem like the device was doing something intensive. Again, this was all for the fun of it, as the strings are the only necessary step.

```cpp
extern "C" {
#include <stdio.h>
#include <ctype.h>
#include "py/obj.h"
#include "py/runtime.h"
#include "mbedtls/pk.h"
#include "mbedtls/ctr_drbg.h"
#include "mbedtls/rsa.h"
}

// Badge Challenge 2
extern "C" mp_obj_t badgechal_chal2_func(void) {
    
    mp_printf(&mp_plat_print, "%s\n", "Loading RSA Keys Into Memory...");
    mp_hal_delay_ms(5000);
    
    // Encrypted RSA Private Key (PEM, password protected)
    const char *encrypted_private_key_pem =
    "-----BEGIN ENCRYPTED PRIVATE KEY-----\n"
    "MIIC5TBfBgkqhkiG9w0BBQ0wUjAxBgkqhkiG9w0BBQwwJAQQladNFlzxwGIFVQQz\n"
    "mkqT7wICCAAwDAYIKoZIhvcNAgkFADAdBglghkgBZQMEASoEEA1B7L1VIXL39OF6\n"
    "HsRfvlQEggKATVkUVs3CJM+SLTYr9vGBG/OHTeAZZPCYUheXSmMKBXKf8jta+8vy\n"
    "E6k3wtVYHbl2tnPx0H/h4cf+FocCM501wctFOsvrgJ1UQr+YkBeISKwdbC/epDTZ\n"
    "4bFuauREn+5eYn30I1UOIbpI8VgYgliWfEI9MIwRWBVDnUBTSMF4zVHADSpCX+xw\n"
    "Ogxg7swS514na9XzB2rWYH4cph3IbJZN7rMOts2EoIDMw1u+eOf8Bvl6mmmNxSxC\n"
    "MVoLu1vzikwOe7Nuwvk1lFQ8vqw/VmcyMrRYbSMDA7h9ztgio7xcL5AFDzV6LhUY\n"
    "Ttp5D9N+FTS+XuKaumYimwj8LzqjOzkzhtyCBUDzDWdA+p/a2s05V55wABj9Yhen\n"
    "PqOr9yercvLugK8mb/X73MsCcubrGBAYvQlg+53WbyF4rZkAW3jFUuw0i/GuwUbB\n"
    "6BtSfs7JeUe1qw4Ijg5v0fku+SWbf0ZX8GBD8oLy68bte4NEBs1AA3DaNnCfRnQh\n"
    "aR4F5waFYrUajZkqN6bxU5SKIpjE/8qqlRzyNS7OmLFvTPLrr52i+ZcaaehUeXrc\n"
    "C2kYnmI3Tt4JTdaZFhluvuKhIDLkUjDDO5/4lkD/NcHPlwAAeR30VP13cASUnb31\n"
    "hv6ZwhJlENuUy49amiohS0JI33tTaTB/slNeo3X7Bt8tqwlzLv0jcZ+BRQr1vUc9\n"
    "8wr6+vLthOxpVEYewoouzTEaamb3xN2mzFxSSRd+u3P+SmpnPUfa5ADLOge97FwH\n"
    "/9juSiAfCiR1O0OiwZe6m5Ak628d0bv09kDdHJQ9pKprqMbA3NJ73mirILEPwoaL\n"
    "HR8WtrmmSb8ZXPof6rJ2sJw5DuDwmcx3TA==\n"
    "-----END ENCRYPTED PRIVATE KEY-----\n";
    //mp_printf(&mp_plat_print, "%s\n", encrypted_private_key_pem);

    // Public Key (PEM)
    const char *public_key_pem =
    "-----BEGIN PUBLIC KEY-----\n"
    "MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC7xyGTRl+C1sICMHW0Q48o4gk5\n"
    "AgWCM2AWqV6tDL5zA0ur9feWt+vcJp9h/mQa7GNbo45W/phNXRCRIinVLXnwx8I5\n"
    "l8iSMO+WjdBUCvCKAcdq1svFQ60Fd9nOcZoQWjY/StWV4A8OND4tkQhDnt/uUG7M\n"
    "M2U9xkwH4u212ItvsQIDAQAB\n"
    "-----END PUBLIC KEY-----\n";
    //mp_printf(&mp_plat_print, "%s\n", public_key_pem);

    // Password for encrypted private key
    const char *private_key_password = "It'sTh3RSAP@$$";
    //mp_printf(&mp_plat_print, "%s\n", private_key_password);

    int ret;
    // If not defined by ESP-IDF, define them ourselves
    #ifndef MBEDTLS_RSA_PUBLIC
        #define MBEDTLS_RSA_PUBLIC  0
        #define MBEDTLS_RSA_PRIVATE 1
    #endif

    // --- Load Private Key ---
    mbedtls_pk_context priv;
    mbedtls_pk_init(&priv);

    ret = mbedtls_pk_parse_key(&priv,
        (const unsigned char *)encrypted_private_key_pem,
        strlen(encrypted_private_key_pem) + 1,
        (const unsigned char *)private_key_password,
        strlen(private_key_password),
        NULL, NULL  // no RNG needed for parsing
    );

    if (ret != 0) {
        mbedtls_pk_free(&priv);
        mp_raise_ValueError(MP_ERROR_TEXT("Failed to parse private key"));
    }

    // --- Load Public Key ---
    mbedtls_pk_context pub;
    mbedtls_pk_init(&pub);

    ret = mbedtls_pk_parse_public_key(&pub,
        (const unsigned char *)public_key_pem,
        strlen(public_key_pem) + 1
    );

    if (ret != 0) {
        mbedtls_pk_free(&priv);
        mbedtls_pk_free(&pub);
        mp_raise_ValueError(MP_ERROR_TEXT("Failed to parse public key"));
    }

    // --- Ensure both keys are RSA ---
    if (!mbedtls_pk_can_do(&priv, MBEDTLS_PK_RSA) ||
        !mbedtls_pk_can_do(&pub, MBEDTLS_PK_RSA)) {
        mbedtls_pk_free(&priv);
        mbedtls_pk_free(&pub);
        mp_raise_ValueError(MP_ERROR_TEXT("Keys are not RSA"));
    }

    // --- Create dummy hash ---
    unsigned char hash[32] = {0};  // SHA-256 dummy hash
    unsigned char sig[MBEDTLS_MPI_MAX_SIZE];

    // --- Initialize RNG ---
    mbedtls_ctr_drbg_context ctr_drbg;
    mbedtls_entropy_context entropy;

    mbedtls_ctr_drbg_init(&ctr_drbg);
    mbedtls_entropy_init(&entropy);

    const char *pers = "badgechal_chal2";
    ret = mbedtls_ctr_drbg_seed(&ctr_drbg, mbedtls_entropy_func, &entropy,
                                (const unsigned char *)pers, strlen(pers));
    if (ret != 0) {
        mp_raise_ValueError(MP_ERROR_TEXT("Failed to seed RNG"));
    }

    // --- Sign with Private Key ---
    mp_printf(&mp_plat_print, "%s\n", "Signing with Private Key...");
    mp_hal_delay_ms(5000);
    mbedtls_rsa_context *rsa_priv = mbedtls_pk_rsa(priv);
    
    ret = mbedtls_rsa_pkcs1_sign(
        rsa_priv,
        mbedtls_ctr_drbg_random, &ctr_drbg,
        MBEDTLS_MD_SHA256,
        32, hash, sig
    );

    if (ret != 0) {
        mbedtls_pk_free(&priv);
        mbedtls_pk_free(&pub);
        mp_raise_ValueError(MP_ERROR_TEXT("Failed to sign hash"));
    }

    // --- Verify with Public Key ---
    mp_printf(&mp_plat_print, "%s\n", "Verifying with Public Key...");
    mp_hal_delay_ms(5000);
    mbedtls_rsa_context *rsa_pub = mbedtls_pk_rsa(pub);
    ret = mbedtls_rsa_pkcs1_verify(
        rsa_pub,
        MBEDTLS_MD_SHA256,
        32,
        hash,
        sig
    );

    // Clean up
    mbedtls_pk_free(&priv);
    mbedtls_pk_free(&pub);
    mbedtls_ctr_drbg_free(&ctr_drbg);
    mbedtls_entropy_free(&entropy);

    // Return True if verify succeeded, False otherwise
    if(ret == 0) {
        mp_printf(&mp_plat_print, "%s\n", "Key pair is valid!");
    }
    else {
        mp_printf(&mp_plat_print, "%s\n", "Key pair NOT is valid!");
    }
    return (ret == 0) ? mp_const_true : mp_const_false;
}
extern "C" MP_DEFINE_CONST_FUN_OBJ_0(badgechal_chal2_obj, badgechal_chal2_func);

// All of the MicroPython implemention stuff to get the library to work
// Module globals table
extern "C" const mp_rom_map_elem_t badgechal_module_globals_table[] = {
    { MP_ROM_QSTR(MP_QSTR___name__), MP_ROM_QSTR(MP_QSTR_badgechal) },
    { MP_ROM_QSTR(MP_QSTR_chal2), MP_ROM_PTR(&badgechal_chal2_obj) },
};

// Create the global dictionary
extern "C" MP_DEFINE_CONST_DICT(badgechal_module_globals, badgechal_module_globals_table);

// Define the module object
extern "C" const mp_obj_module_t badgechal_user_cmodule = {
    .base = { &mp_type_module },
    .globals = (mp_obj_dict_t *)&badgechal_module_globals,
};

// Register the module with MicroPython
MP_REGISTER_MODULE(MP_QSTR_badgechal, badgechal_user_cmodule);
```
