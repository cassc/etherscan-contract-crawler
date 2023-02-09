// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./HERC721Layout.sol";
import "../erc165/HERC165Storage.sol";
import "../context/ContextStorage.sol";

//this is an endpoint module, only can be directly inherited all the way to the end
contract HERC721Storage is HERC721Layout, HERC165Storage, ContextStorage {

    constructor (
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    )
    HERC165Storage()
    ContextStorage()
    {
        _name = name_;
        _symbol = symbol_;
        _baseURI = baseURI_;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }
}