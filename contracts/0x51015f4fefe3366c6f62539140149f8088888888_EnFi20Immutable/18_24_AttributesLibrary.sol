// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

library TimeLock {
    // If FEATURE is set at Contract level, it means that contract need to check for timelock at wallet level.
    uint256 public constant FEATURE = 1 << 96;

    function set(
        uint256 _attributes,
        uint256 _timestamp
    ) internal pure returns (uint256) {
        require(_timestamp <= 4294967295, "ts_overflow");
        return (_attributes & ~uint256(0xFFFFFFFF)) | _timestamp;
    }

    function get(uint256 _attributes) internal pure returns (uint256) {
        return _attributes & ((1 << 32) - 1);
    }

    function remove(uint256 _attributes) internal pure returns (uint256) {
        uint256 mask = ((1 << 32) - 1);
        return _attributes & ~mask;
    }
}

library EarlyReleaseFee {
    uint256 public constant FEATURE = 1 << 97;
    uint256 public constant PRECISION = 100;

    function has(
        uint256 _attributes,
        uint256 _attribute
    ) internal pure returns (bool) {
        return (_attributes & _attribute) == _attribute;
    }

    function set(
        uint256 _attributes,
        uint32 _duration,
        uint8 _percentage
    ) internal pure returns (uint256) {
        require(_duration <= 2 ** 25 - 1, "duration_overflow");
        require(_percentage <= 100, "percentage_overflow");
        uint256 penalty = (_duration << 7) | _percentage;
        uint256 mask = 0xffffffff00000000;
        uint256 clearedAttributes = _attributes & ~(mask);
        return clearedAttributes | (penalty << 32);
    }

    function get(
        uint256 _attributes
    ) internal pure returns (uint32 duration, uint8 percentage) {
        uint256 penalty = (_attributes >> 32) & ((1 << 32) - 1);
        duration = uint32(penalty >> 7);
        percentage = uint8(penalty & ((1 << 7) - 1));
    }

    function remove(uint256 _attributes) internal pure returns (uint256) {
        uint256 mask = (((1 << 32) - 1) << 32);
        return _attributes & ~mask;
    }
}

// third 32 bits are reserved for another uint32

// bits 96, 97, 98 are reserved as wallet activation flags for first 96 bits

library Role {
    // next 29 bits: roles. Wallets with a role can perform certain actions
    uint256 public constant ADD_ROLE = 1 << 99;
    uint256 public constant REMOVE_ROLE = 1 << 100;
    uint256 public constant ACCESS_CONTROL = 1 << 101;
    uint256 public constant ATTRIBUTES = 1 << 102;
    uint256 public constant DEPLOY_LIQUIDITY = 1 << 103;
    uint256 public constant LOCK_CHANGE = 1 << 104;
    uint256 public constant ALLOCATE_FUNDS = 1 << 105;
    uint256 public constant RETURN_FUNDS = 1 << 106;
    uint256 public constant RECOVER = 1 << 107;
    uint256 public constant XTRANSFER = 1 << 108;
    uint256 public constant XAPPROVE = 1 << 109;
    uint256 public constant WITHDRAW_ETH = 1 << 110;
    uint256 public constant MINTER = 1 << 111;
    // uint256 public constant DEPOSIT_RECEIVER = 1 << 112;
    uint256 public constant CREATE_AUCTION = 1 << 113;
    uint256 public constant REMOVE_AUCTION = 1 << 114;
    uint256 public constant ADMIN = 1 << 115;
    uint256 public constant OWNER = 1 << 116;
    uint256 public constant SET_SWAP_PATH = 1 << 117;
}

library Attribute {
    // recap
    // If time lock is set at Contract level, it means that contract need to check for timelock at wallet level.
    // reserved for feature time lock 1 << 96;
    // reserved for feature penalty  = 1 << 97; activated in the data fields
    //uint256 public constant BLOCKED = 1 << 128; not used anymore
    uint256 public constant BLOCK_TRANSFER = 1 << 139;
    uint256 public constant BLOCK_MINT = 1 << 140;
    uint256 public constant BLOCK_BURN = 1 << 141;
    //uint256 public constant PENALTY = 1 << 143;
    uint256 public constant FROZEN = 1 << 144;
    // OVERRIDE BLOCKING FEATURE
    // (CHECK WALLET LEVEL IF ACTIVATED AT CONTRACT LEVEL, AND WALLET LEVEL DEFINE IF IT IS ACTIVATED OR NOT)
    uint256 public constant WHITELIST_TRANSFER_FROM = 1 << 145;
    uint256 public constant WHITELIST_TRANSFER_TO = 1 << 146;

    // next 32 bits: is the corresponding feature enabled?
    // this property lets us know wether we should perform a wallet level check
    //uint256 public constant WL_BLOCKED = 1 << 160; not used
    uint256 public constant WL_BLOCK_TRANSFER = 1 << 161;
    uint256 public constant WL_BLOCK_MINT = 1 << 162;
    uint256 public constant WL_BLOCK_BURN = 1 << 163;
    //uint256 public constant WL_PENALTY = 1 << 164; not used
    // uint256 public constant WL_FROZEN = 1 << 165; not used

    // next 32 bits nothing yet

    // next 32 bits: misc flags
    uint256 public constant IS_LIQUIDITY_DEPLOYED = 1 << 224;
}

library Attributes {
    function has(
        uint256 _attributes,
        uint256 _attribute
    ) internal pure returns (bool) {
        return (_attributes & _attribute) == _attribute;
    }

    function hasAny(
        uint256 _attributes,
        uint256 _attribute
    ) internal pure returns (bool) {
        return (_attributes & _attribute) != 0;
    }

    function set(
        uint256 _attributes,
        uint256 _attribute
    ) internal pure returns (uint256) {
        return _attributes | _attribute;
    }

    function remove(
        uint256 _attributes,
        uint256 _attribute
    ) internal pure returns (uint256) {
        return _attributes & ~_attribute;
    }
}