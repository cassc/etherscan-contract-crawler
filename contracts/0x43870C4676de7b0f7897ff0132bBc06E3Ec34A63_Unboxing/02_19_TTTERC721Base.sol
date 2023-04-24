// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../opensea/ContextMixin.sol";
import "../opensea/NativeMetaTransaction.sol";

contract OpenSeaOwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
    mapping(address => OpenSeaOwnableDelegateProxy) public proxies;
}

contract TTTERC721Base is
    ContextMixin,
    ERC721Enumerable,
    Ownable,
    NativeMetaTransaction
{
    bool public isSealed;
    string public openseaContractUri;
    address public openseaProxyRegistryAddress;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory openSeaContractUri_,
        address openseaProxyRegistryAddress_
    ) ERC721(name_, symbol_) {
        openseaContractUri = openSeaContractUri_;
        openseaProxyRegistryAddress = openseaProxyRegistryAddress_;
    }

    //
    //
    // ERC165
    //
    //
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable)
        returns (bool)
    {
        return ERC721Enumerable.supportsInterface(interfaceId);
    }

    //
    //
    // SEAL CONTRACT
    //
    //
    modifier onlyUnsealed() {
        require(!isSealed, "tokens are sealed");
        _;
    }

    modifier onlySealed() {
        require(isSealed, "tokens are not sealed");
        _;
    }

    function sealTokens() public onlyOwner onlyUnsealed {
        isSealed = true;
    }

    //
    //
    // TOKEN MINT / BURN
    //
    //
    function mint(address to, uint256 tokenId)
        public
        virtual
        onlyOwner
        onlyUnsealed
    {
        _safeMint(to, tokenId);
    }

    function burn(uint256 tokenId) public virtual {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "TTTERC721Base: caller is neither owner nor approved"
        );
        _burn(tokenId);
    }

    // opensea contract uri
    function contractURI() public view returns (string memory) {
        return openseaContractUri;
    }

    //
    //
    // OPENSEA PROXY
    //
    //
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        if (openseaProxyRegistryAddress != address(0)) {
            // Whitelist OpenSea proxy contract for easy trading.
            OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(
                openseaProxyRegistryAddress
            );
            if (address(proxyRegistry.proxies(owner)) == operator) {
                return true;
            }
        }
        return super.isApprovedForAll(owner, operator);
    }

    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
    }
}