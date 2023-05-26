// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../advanced/1155/DigitalNFT1155Advanced.sol";

/// @title Digital NFT Gallery
/// @author DigitalNFT.it
/// @notice Developed by DigitalNFT.it (https://digitalnft.it/)
contract DigitalNFTGallery is DigitalNFT1155Advanced {

    // ============================== Functions ============================== //

    /**
    * @dev Initializes the contract by setting the following parameters:
    * - `name`: the name of the token collection;
    * - `symbol`: the symbol of the token collection;
    * - `contractUri`: the URI of the token collection contract;
    * - `royalty receiver`: the address that receive the royalties;
    * - `royalty amount`: the value of royalties.
    */
    constructor() ERC1155("") {
        name = "Digital NFT Gallery";
        symbol = "DNG";
        _contractUri = "ipfs://QmQqiqtfVez27edqicvTCz7tFnxVKmmNB5fzCWZsWVoce9";
        _setDefaultRoyalty(msg.sender, 250);
    }
}