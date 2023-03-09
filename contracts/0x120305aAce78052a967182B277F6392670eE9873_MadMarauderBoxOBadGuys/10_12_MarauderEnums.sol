// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

enum Phase {
    // 0: the sale has not started. No mints allowed
    NOT_STARTED,

    // 1: allowlisted nerds can mint for a discounted price
    NERDS_ONLY,

    // 2: allowlisted friends and family can mint for a discounted price
    FRIENDS_AND_FAMILY,

    // 3: all allowlisted addresses can mint
    PUBLIC_ALLOWLIST,

    // 4: anybody can mint
    PUBLIC
}

enum Item {
    // 0: box o bad guys
    BOX_O_BAD_GUYS,

    // 1: enforcers
    ENFORCER,

    // 2: warlords
    WARLORD,

    // 3: serums
    MYSTERY_SERUM
}