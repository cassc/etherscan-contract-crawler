// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./ProxyRegistry.sol";

contract VandalizedHeart is ERC721, Ownable {
    using Counters for Counters.Counter;

    address proxyRegistryAddress;

    Counters.Counter private _tokenSupply;

    string private baseUri;

    constructor(
        address _proxyRegistryAddress,
        string memory _baseUri
    ) ERC721("VandalizedHeart", "OMVH") {
        proxyRegistryAddress = _proxyRegistryAddress;
        baseUri = _baseUri;
    }

    function reserve(address[] calldata to) public onlyOwner {
        for (uint256 i = 0; i < to.length; i++) {
            _safeMint(to[i], _tokenSupply.current());
            _tokenSupply.increment();
        }
    }

    function totalSupply() public view returns (uint256) {
        return _tokenSupply.current();
    }

    function contractURI() public pure returns (string memory) {
        return "ipfs://bafybeibvqqurax2qxppkay5ely6v5qkr2l3doidr32veirgx67hjwuh54m";
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function setBaseURI(string memory _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }

    function walletOfOwner(address owner) public view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](balanceOf(owner));
        uint256 i = 0;

        for (uint256 tokenId = 0; tokenId < _tokenSupply.current(); tokenId++) {
            if (_exists(tokenId) && ownerOf(tokenId) == owner) {
                result[i] = tokenId;
                i += 1;
            }
        }
        return result;
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }
}