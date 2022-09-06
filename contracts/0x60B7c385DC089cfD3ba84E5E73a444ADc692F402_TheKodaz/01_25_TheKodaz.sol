// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@chocolate-factory/contracts/token/ERC721/presets/Free.sol";

contract TheKodaz is Free {
    function initialize(
        bytes32 whitelistMerkleTreeRoot_,
        address royaltiesRecipient_,
        uint256 royaltiesValue_
    ) public initializerERC721A initializer {
        __ERC721A_init("TheKodaz", "TK");
        __Ownable_init();
        __AdminManager_init_unchained();
        __Supply_init_unchained(3000);
        __AdminMint_init_unchained();
        __Whitelist_init_unchained();
        __BalanceLimit_init_unchained();
        __UriManager_init_unchained("", "");
        __Royalties_init_unchained(royaltiesRecipient_, royaltiesValue_);
        updateMerkleTreeRoot(uint8(Stage.Whitelist), whitelistMerkleTreeRoot_);
        updateBalanceLimit(uint8(Stage.Whitelist), 1);
        updateBalanceLimit(uint8(Stage.Public), 1);
    }
}