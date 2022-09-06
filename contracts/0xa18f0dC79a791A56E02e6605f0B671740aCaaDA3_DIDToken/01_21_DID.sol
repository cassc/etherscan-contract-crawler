// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/draft-ERC721VotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";


contract DIDToken is Initializable,ERC721Upgradeable, EIP712Upgradeable, ERC721URIStorageUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;

    error TokenIsSoulbound();

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC721_init("DIDToken", "DID");
        __ERC721URIStorage_init();
        __Ownable_init();
        __EIP712_init("DID", "1");
        __UUPSUpgradeable_init();
    }


    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}


    // 1 to 1 bound
    function safeMint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();

        require(balanceOf(to) == 0, "Not reclaimable");
    
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }


    function onlySoulbound(address from, address to) internal pure {
        // Revert if transfers are not from the 0 address and not to the 0 address
        if (from != address(0) && to != address(0)) {
            revert TokenIsSoulbound();
        }
    }

    
    function safeTransferFrom(address from, address to, uint256 id) onlyOwner public override {
        super.safeTransferFrom(from, to, id);
    }


    function safeTransferFrom(address from, address to, uint256 id, bytes memory data) public override {
        onlySoulbound(from, to);
        super.safeTransferFrom(from, to, id, data);
    }


        function transferFrom(address from, address to, uint256 id) public override {
        onlySoulbound(from, to);
        super.transferFrom(from, to, id);
    }


    // The following two functions are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721Upgradeable)
    {
        super._afterTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }


    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }


    function getTokenURI(uint256 tokenId) public view returns (string memory) {
        return tokenURI(tokenId);
    }


    function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyOwner{

        _setTokenURI(tokenId, _tokenURI);
    }

    
    function burn(uint256 tokenId)
        public onlyOwner{
        _burn(tokenId);
        }
}