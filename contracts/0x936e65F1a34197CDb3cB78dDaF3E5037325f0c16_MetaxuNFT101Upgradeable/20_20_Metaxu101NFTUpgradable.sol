// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

contract MetaxuNFT101Upgradeable is Initializable, ERC721Upgradeable, ERC721URIStorageUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;
    string private _contractURI;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(string memory contractURI_) initializer public {
        __ERC721_init("Metaxu", "METAXU");
        __ERC721URIStorage_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        _tokenIdCounter.increment();
        _contractURI = contractURI_;
    }

    function safeMint(address to_, string memory uri_) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to_, tokenId);
        _setTokenURI(tokenId, uri_);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    // The following functions are overrides required by Solidity.

    function burn (uint256 tokenId_) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId_);
    }

    function _burn(uint256 tokenId_)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId_);
    }

    function tokenURI(uint256 tokenId_)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId_);
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string memory uri_) public onlyOwner {
        _contractURI = uri_;
    }

    function setTokenURI(uint256 tokenId_, string memory uri_) public onlyOwner {
        _setTokenURI(tokenId_, uri_);
    }
}