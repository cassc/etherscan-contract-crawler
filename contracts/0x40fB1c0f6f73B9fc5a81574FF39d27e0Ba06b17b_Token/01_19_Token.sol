// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

/**
 * @title The Mike Tyson NFT Collection by Cory Van Lew 
 * An NFT powered by Ether Cards - https://ether.cards
 */

 
contract Token is ERC721Tradable {

    string      _tokenURI = "https://client-metadata.ether.cards/api/tyson/";
    string      _contractURI = "https://client-metadata.ether.cards/api/tyson/contract";
    uint256      public       HG2G = 42;
     constructor(address _proxyRegistryAddress)
        ERC721Tradable("The Mike Tyson NFT Collection by Cory Van Lew", "TYSON", _proxyRegistryAddress)
    {}

    function baseTokenURI() override public view returns (string memory) {
        return _tokenURI;
    }

    function setTokenURI(string memory _uri) external onlyOwner {
        _tokenURI = _uri;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string memory _uri) external onlyOwner {
        _contractURI = _uri;
    }

}