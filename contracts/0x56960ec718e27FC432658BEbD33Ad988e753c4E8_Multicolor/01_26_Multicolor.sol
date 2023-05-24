// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../../advanced/1155/DigitalNFT1155Advanced.sol";

/// @title Multicolor
/// @author Stefania Pinci
/// @notice Developed by DigitalNFT.it (https://digitalnft.it/)
contract Multicolor is DigitalNFT1155Advanced {

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
        name = "Multicolor";
        symbol = "MC";
        _contractUri = "ipfs://QmSUHBz16QpLnDXYkfgnLXDTkZaKDxnRmTwaRXd4cX6ngM/Contract";
        _setDefaultRoyalty(msg.sender, 250);
    }
}