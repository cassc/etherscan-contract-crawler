// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Nft is ERC721, ERC721Enumerable, ERC721Burnable, AccessControl {
    using Counters for Counters.Counter;
    using Strings for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADE_ROLE = keccak256("UPGRADE_ROLE");

    Counters.Counter private _tokenIdCounter;

    string public baseURI;

    struct NftInfo {
        uint256 rarity;
        uint256 lvl;
    }

    mapping(uint256 => NftInfo) private nftInfo;

    event NftRarityUpgradedEvent(uint256 indexed _tokenId, uint256 _prevRarity, uint256 _newRarity);
    event NftLvlUpgradedEvent(uint256 indexed _tokenId, uint256 _prevLvl, uint256 _newLvl);

    event NftDepositEvent(uint256 indexed _tokenId, address indexed _ref);
    event NftWithdrawEvent(uint256 indexed _tokenId, address indexed _ref);

    event BaseURIUpdatedEvent(string _oldBaseURI, string _baseURI);

    constructor(string memory _name, string memory _symbol, string memory _baseURI) ERC721(_name, _symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(UPGRADE_ROLE, msg.sender);

        setBaseURI(_baseURI);
    }

    function nftInfoOf(uint256 _tokenId) external view returns (bool exists, bool isBurned, address owner, NftInfo memory nft, bytes32 hash) {
        nft = nftInfo[_tokenId];

        exists = _exists(_tokenId);
        isBurned = !_exists(_tokenId) && nft.rarity > 0 && nft.rarity > 0;
        owner = _ownerOf(_tokenId);

        hash = keccak256(abi.encodePacked(nft.rarity, nft.lvl));
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        _requireMinted(_tokenId);

        NftInfo storage nft = nftInfo[_tokenId];

        if (bytes(baseURI).length > 0) {
            return string(
                abi.encodePacked(
                    baseURI,
                    nft.rarity.toString(),
                    "/",
                    nft.lvl.toString(),
                    "/",
                    _tokenId.toString(),
                    ".json"
                )
            );
        }
        return "";
    }

    function safeMint(address _to, uint256 _rarity, uint256 _lvl) public onlyRole(MINTER_ROLE) {
        require(_lvl >= 1, "lvl is not valid");
        require(_rarity >= 1, "rarity is not valid");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_to, tokenId);

        nftInfo[tokenId].rarity = _rarity;
        nftInfo[tokenId].lvl = _lvl;
    }

    function upgradeRarity(uint256 _tokenId, uint256 _rarity) external onlyRole(UPGRADE_ROLE) {
        _requireMinted(_tokenId);
        require(_rarity >= 1, "rarity is not valid");

        uint256 _oldRarity = nftInfo[_tokenId].rarity;

        nftInfo[_tokenId].rarity = _rarity;

        emit NftRarityUpgradedEvent(_tokenId, _oldRarity, _rarity);
    }

    function upgradeLvl(uint256 _tokenId, uint256 _lvl) external onlyRole(UPGRADE_ROLE) {
        _requireMinted(_tokenId);
        require(_lvl >= 1, "lvl is not valid");

        uint256 _oldLvl = nftInfo[_tokenId].lvl;

        nftInfo[_tokenId].lvl = _lvl;

        emit NftLvlUpgradedEvent(_tokenId, _oldLvl, _lvl);
    }

    function onDeposit(uint256 _tokenId, address _ref) external onlyRole(UPGRADE_ROLE) {
        _requireMinted(_tokenId);
        emit NftDepositEvent(_tokenId, _ref);
    }

    function onWithdraw(uint256 _tokenId, address _ref) external onlyRole(UPGRADE_ROLE) {
        _requireMinted(_tokenId);
        emit NftWithdrawEvent(_tokenId, _ref);
    }

    function setBaseURI(string memory _baseURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        string memory oldBaseURI = baseURI;

        baseURI = _baseURI;

        emit BaseURIUpdatedEvent(oldBaseURI, _baseURI);
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId, uint256 _batchSize) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(_from, _to, _tokenId, _batchSize);
    }

    function supportsInterface(bytes4 _interfaceId) public view override(ERC721, ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(_interfaceId);
    }
}