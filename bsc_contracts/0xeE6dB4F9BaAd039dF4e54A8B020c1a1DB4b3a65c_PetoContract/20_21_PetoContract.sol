// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import "hardhat/console.sol";

// contract PetoContract is Initializable, ERC721Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
contract PetoContract is Initializable, ERC721Upgradeable, OwnableUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using StringsUpgradeable for uint256;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(string memory name_, string memory symbol_) public initializer {
        __ERC721_init(name_, symbol_);
        __Ownable_init();
    }

    CountersUpgradeable.Counter private _tokenIdCounter;

    mapping(uint32 => TokenItem) private _tokenItems;

    string private _uri;

    struct TokenItem {
        uint32 tokenId;
        address owner;
    }

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        CreateItem(uint32(tokenId), to);
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function CreateItem(uint32 tokenId, address owner_) private onlyOwner {
        _tokenItems[tokenId] = TokenItem(tokenId, owner_);
    }

    function createTokens(uint32 tokenCount) external onlyOwner {
        for (uint32 i = 0; i < tokenCount; i++) {
            safeMint(_msgSender());
        }
    }

    function fetchTokens() external view returns (TokenItem[] memory) {
        uint32 tokenItemCount = uint32(_tokenIdCounter.current());
        TokenItem[] memory tokens = new TokenItem[](tokenItemCount);
        for (uint32 i = 0; i < tokenItemCount; i++) {
            tokens[i] = _tokenItems[i];
        }
        return tokens;
    }

    function fetchToken(uint32 tokenId) public view returns (TokenItem memory) {
        return _tokenItems[tokenId];
    }

    function getTokenCount() public view returns (uint32) {
        return uint32(_tokenIdCounter.current());
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        TokenItem storage token = _tokenItems[uint32(tokenId)];
        token.owner = to;
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        TokenItem storage token = _tokenItems[uint32(tokenId)];
        token.owner = to;
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function setURI(string memory uri) external onlyOwner {
        _uri = uri;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string.concat(_uri, tokenId.toString(), ".json");
    }

    function contractURI() public view returns (string memory) {
        return string.concat(_uri, "contract.json");
    }
}