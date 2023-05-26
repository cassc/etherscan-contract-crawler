// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;


library Registry {
    
    // keccak256("platform.assets.contract.key");
    bytes32 internal constant PLATFORM_ASSETS_CONTRACT_KEY = 0xc33c8716707b901a5897f5b0eb3bfd4928388fae53a418d46ab0875723c1dcd5;
    
    // keccak256("self.burn.key")
    bytes32 internal constant SELF_BURN_KEY = 0x75194dd2030e024bec7157fbb11d88254cd93866bea6f28460cb1a3f4ece16a8;

    // keccak256("ADMIN_ROLE");
    bytes32 internal constant ADMIN_ROLE = 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775;

    // keccak256("nft.freemint.role")
    bytes32 internal constant NFT_FREE_MINT_ROLE = 0x0767cc7d475698a20da8b9c9ab30101036be6749f2bf86a72d06268a5b3f1e5a;

    // keccak256("nft.group.minter.role")
    bytes32 internal constant NFT_GROUP_MINTER_ROLE = 0xd9d808b7856857a3760215b224352383987bacfc5008c9dca860116bcc2c8f0c;

    // keccak256("nft.group.burner.role")
    bytes32 internal constant NFT_GROUP_BURNER_ROLE = 0xe83fe28a8b39dca556b6801067344bab81e98ce23ce9aff4628a4103b6b6bb2d;

    // keccak256("nft.group.transferer.role")
    bytes32 internal constant NFT_GROUP_TRANSFER_ROLE = 0xdc24745d8f4fef6bd3d099210f61e8dbf7dc40d6062869098e8607ba57770b15;

    // keccak256("blacklist.restrictions.from.role")
    bytes32 internal constant BLACKLIST_RESTRICTIONS_FROM_ROLE = 0xec0348d8f67c17b6a4f0d5fe690f13320db186c52b5d6496aada586aef1fba09;

    // keccak256("blacklist.restrictions.to.role")
    bytes32 internal constant BLACKLIST_RESTRICTIONS_TO_ROLE = 0xba36acc39ec3d3132500f85961bb78d126e633601d0ab49bb3612560538a7e2a;

}