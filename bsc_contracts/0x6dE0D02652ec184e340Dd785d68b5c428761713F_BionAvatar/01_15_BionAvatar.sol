// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract BionAvatar is ERC721Enumerable, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Counters for Counters.Counter;

    string public baseURI;
    Counters.Counter public tokenIdCounter;
    uint256 public immutable maxSupply;
    uint256 public startIndex;

    // whitelist
    bool public isWhitelistEnabled = true;
    EnumerableSet.AddressSet private _whitelist;
    mapping(address => bool) public claimeds;

    constructor(uint256 _maxSupply, uint256 _startIndex) ERC721("Bitendo Gameboy", "BG") {
        maxSupply = _maxSupply;
        startIndex = _startIndex;
    }

    function setStartIndex(uint256 _startIndex) external onlyOwner {
        startIndex = _startIndex;
    }

    function getNextTokenId() public view returns (uint256) {
        return tokenIdCounter.current() + startIndex;
    }

    function getWhitelist() public view returns (address[] memory) {
        uint256 length = _whitelist.length();
        address[] memory whitelist = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            whitelist[i] = _whitelist.at(i);
        }
        return whitelist;
    }

    function addWhitelistMany(address[] memory addresses) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _whitelist.add(addresses[i]);
        }
    }

    function removeWhitelistMany(address[] memory addresses) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _whitelist.remove(addresses[i]);
        }
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _whitelist.contains(account);
    }

    function setWhitelistEnabled(bool enabled) public onlyOwner {
        isWhitelistEnabled = enabled;
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function mint() public {
        require(msg.sender == tx.origin, "CONTRACT_NOT_ALLOWED");
        require(!isWhitelistEnabled || _whitelist.contains(msg.sender), "NOT_WHITELISTED");
        require(tokenIdCounter.current() < maxSupply, "MAX_SUPPLY_REACHED");
        require(!claimeds[msg.sender], "ALREADY_CLAIMED");

        claimeds[msg.sender] = true;
        _safeMint(msg.sender, getNextTokenId());
        tokenIdCounter.increment();
    }

    function extendedMint(address _to, uint256 _tokenId) public onlyOwner {
        require(_tokenId < startIndex || _tokenId > startIndex + maxSupply - 1, "CANNOT_MINT_IN_SUPPLY_RANGE");

        _safeMint(_to, _tokenId);
    }
}