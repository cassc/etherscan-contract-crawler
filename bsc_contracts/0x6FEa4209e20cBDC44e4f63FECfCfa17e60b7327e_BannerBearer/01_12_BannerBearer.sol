// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./ERC721NoTransferibleUpgradeable.sol";

contract BannerBearer is
    Initializable,
    ERC721NoTransferibleUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable
{
    //============= LIBRARIES =============//
    using CountersUpgradeable for CountersUpgradeable.Counter;

    //============= VARIABLES =============//
    CountersUpgradeable.Counter private _tokenIdCounter;

    //============= EVENTS =============//
    event Minted(address indexed to, uint256 indexed tokenId);
    event URIGeneration(uint256 tokenId, string tokenURI);

    constructor() {
        _disableInitializers();
    }

    function initialize() external initializer {
        __ERC721NoTransferible_init("Outer Ring Banner Bearer", "ORBB");
        __Ownable_init();
    }

    function safeMint(address to, string calldata uri) external onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _mint(to, tokenId);
        emit Minted(to, tokenId);
        _setTokenURI(tokenId, uri);
        emit URIGeneration(tokenId, uri);
    }

    function setTokenURI(uint256 tokenId, string calldata uri) external onlyOwner {
        _setTokenURI(tokenId, uri);
        emit URIGeneration(tokenId, uri);
    }
}