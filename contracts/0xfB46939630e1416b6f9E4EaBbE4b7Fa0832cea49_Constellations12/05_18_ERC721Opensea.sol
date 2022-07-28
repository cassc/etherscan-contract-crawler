// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}
 
// ERC721 Contract
abstract contract ERC721Opensea is Ownable, ERC721Enumerable {
    string private _contractURI;
    string private _tokenBaseURI;
    address proxyRegistryAddress;

    constructor() {}

    function setProxyRegistryAddress(address proxyAddress) external onlyOwner {
        proxyRegistryAddress = proxyAddress;
    }
    
    // set contract URI
    function setContractURI(string calldata URI) external onlyOwner {
        _contractURI = URI;
    } 

    // set base uri
    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override( ERC721 )
        returns ( bool )
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    } 
    

    function _baseURI()
        internal
        view
        override(ERC721)
        returns (string memory)
    {
        return _tokenBaseURI;
    }

 
}