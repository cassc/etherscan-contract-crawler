// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;


library Registry {
    
    // =============================================================
    // about role
    // =============================================================

    // SUPER_ADMIN_ROLE
    bytes32 internal constant SUPER_ADMIN_ROLE = 0x0000000000000000000000000000000000000000000000000000000000000000;

    // keccak256("ADMIN_ROLE");
    bytes32 internal constant ADMIN_ROLE = 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775;

    // keccak256("minter.role")
    bytes32 internal constant MINTER_ROLE = 0xb7400b17e52d343f741138df9e91f7b1f847b285f261edc36ddf5d104892f80d;
    // keccak256("burner.role")
    bytes32 internal constant BURNER_ROLE = 0x67ddb8e48ce0d66032a44701598dde318e9e357db26bb3a846b15f87ffdb8369;
    // keccak256("transfer.role")
    bytes32 internal constant TRANSFER_ROLE = 0xd9075b04fc9576b33d6513403323ecc334609c7afb3004ab47244ebef1d5ccd1;

    // keccak256("blacklist.role")
    bytes32 internal constant BLACKLIST_ROLE = 0xeceef7797af2e02f3081f740231d7a12b7f97400383d3ffdfa8953c62acb4708;

    // keccak256("pauser.role")
    bytes32 internal constant PAUSER_ROLE = 0xa67d36adcd6e3e45eaf6d65fa285a008bff25153247f18ac567589f1f32c3460;

    // =============================================================
    // about KV
    // =============================================================

    // keccak256("treasurywallet.key");
    bytes32 internal constant TREASURYWALLET_KEY = 0xe3bb4fe41787a18688c48ea64caf92a2bae2555227aaef6d464b886efb453118;
    // keccak256("operationwallet.key")
    bytes32 internal constant OPERATIONWALLET_KEY = 0x265545640c0c4e566d10fc3f1073314df9d9f30336f39c054903d28124930538;
    // keccak256("hotwallet.key")
    bytes32 internal constant HOTWALLET_KEY = 0x5a9627b84796698a4e50d2d61a91ce59358fe3945a467b2b94968cb135c41531;


    // keccak256("uint256");
    bytes32 internal constant UINT256_HASH = 0xec13d6d12b88433319b64e1065a96ea19cd330ef6603f5f6fb685dde3959a320;
    // keccak256("address");
    bytes32 internal constant ADDRESS_HASH = 0x421683f821a0574472445355be6d2b769119e8515f8376a1d7878523dfdecf7b;

}