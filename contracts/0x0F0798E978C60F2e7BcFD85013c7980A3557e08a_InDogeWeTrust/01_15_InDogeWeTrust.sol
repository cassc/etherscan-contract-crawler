// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";


contract InDogeWeTrust is Initializable, ERC721Upgradeable, PausableUpgradeable, OwnableUpgradeable, ERC721BurnableUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;

    string public _baseTokenURI;
    address pixelAddress;
    mapping(address => bool) public whitelistClaimed;
    mapping(uint256 => bool) public pixelClaimed;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _pixelAddress) initializer public {
        __ERC721_init("In Doge We Trust", "IDWT");
        __Pausable_init();
        __Ownable_init();
        __ERC721Burnable_init();
        pixelAddress = _pixelAddress;
    }

    function safeMint(uint256 _pixelId) public whenNotPaused {
        // make sure address has not already claimed
        require(!whitelistClaimed[msg.sender], "Address has already claimed");

        // make sure pixel has not already claimed
        require(!pixelClaimed[_pixelId], "Pixel already used to claimed");
        require(ERC721Upgradeable(pixelAddress).ownerOf(_pixelId) == msg.sender, "You do not own this pixel");

        uint256 tokenId = _tokenIdCounter.current();

        // mark address as claimed
        whitelistClaimed[msg.sender] = true;

         // mark pixel as claimed
        pixelClaimed[_pixelId] = true;

        // increment token ID counter & mint token
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
    }

    function hasClaimed(address _whitelist) public view returns (bool) {
        return whitelistClaimed[_whitelist];
    }

    function hasPixelClaimed(uint256 _pixelId) public view returns (bool) {
        return pixelClaimed[_pixelId];
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _baseURI();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    whenNotPaused
    override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function totalSupply() public view returns(uint256) {
        return _tokenIdCounter.current();
    }
}