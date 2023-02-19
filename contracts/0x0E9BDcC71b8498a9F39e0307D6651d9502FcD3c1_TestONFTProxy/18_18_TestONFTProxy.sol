// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./src/tokens/ProxyONFTERC721.sol";

// NOTE: this ONFT contract has no public minting logic.
// must implement your own minting logic in child classes
contract TestONFTProxy is ProxyONFT721 {
    constructor(uint256 _minGasToTransfer, address _lzEndpoint, address _token) 
    ProxyONFT721(_minGasToTransfer, _lzEndpoint, _token) {}

}