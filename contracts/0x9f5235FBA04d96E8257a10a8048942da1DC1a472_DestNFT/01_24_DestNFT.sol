//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "./interfaces/IDestNFT.sol";
import "./interfaces/IRandomGenerator.sol";
import "./libraries/String.sol";
import "./libraries/ERC721Snapshot.sol";
import './interfaces/IERC2981Royalties.sol';

contract DestNFT is ERC721,
ERC721URIStorage,
ERC721Snapshot,
IERC2981Royalties,
IDestNFT,
Pausable,
Ownable,
ReentrancyGuard {
    using Strings for uint256;
    using ERC165Checker for address;

    /// @dev royalties
    uint24 royaltyFeesInBips;
    address royaltyAddress;

    /// @dev baseURI
    string internal baseURI;

    /// @dev token id tracker
    uint256 public tokenIdTracker;

    IRandomGenerator public immutable randomGenerator;

    string[] public metadataHashList;

    event MetaHashListInitialized(string[] values);

    event MetadataHashClaimed(address indexed _claimer, string metadataHash);

    event PermanentURI(string _value, uint256 indexed _id);

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        string[] memory metahashes,
        address randomGenerator_,
        address owner
    ) ERC721(name_, symbol_) Ownable() ReentrancyGuard() {
        require(randomGenerator_.supportsInterface(type(IRandomGenerator).interfaceId), "Random generator is invalid");
        baseURI = baseURI_;
        metadataHashList = metahashes;
        randomGenerator = IRandomGenerator(randomGenerator_);
        transferOwnership(owner);
        emit MetaHashListInitialized(metahashes);
    }

    function updateMetadataHashList(string[] memory metahashes) external override onlyOwner {
        metadataHashList = metahashes;
        emit MetaHashListInitialized(metahashes);
    }

    function setRoyalty(address royaltyReceiver_, uint24 royaltyFeesInBips_) external override onlyOwner {
        require(royaltyReceiver_ != address(0), 'zero receiver address');
        require(royaltyFeesInBips_ <= 10000, 'ERC2981Royalties: Too high');
        royaltyAddress = royaltyReceiver_;
        royaltyFeesInBips = royaltyFeesInBips_;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function randomMint(address to) external override onlyOwner nonReentrant {
        require(metadataHashList.length > 0, "All tokens have been claimed");

        randomGenerator.askRandomness(to);
    }

    /**
     * @dev Pausable check
     * Requirements:
     * - the contract must not be paused for redeemers
     * - allow transfers for owner if paused
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Snapshot) {
        super._beforeTokenTransfer(from, to, tokenId);
        require(msg.sender == owner() || !paused(), "ERC721Pausable: token transfer while paused");
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function paused() public view override(IDestNFT, Pausable) returns (bool) {
        return super.paused();
    }

    function pause() public override onlyOwner {
        super._pause();
    }

    function unpause() public override onlyOwner {
        super._unpause();
    }

    function snapshotId() public view override returns (uint256) {
        return super._getCurrentSnapshotId();
    }

    function snapshot() public override onlyOwner returns (uint256) {
        return super._snapshot();
    }

    function calculateRoyalty(uint256 _salePrice) view public returns (uint256) {
        return (_salePrice / 10000) * royaltyFeesInBips;
    }

    /// @dev Get token royalties
    /// @param _salePrice calculated royalty
    function royaltyInfo(
        uint256 /* _tokenId */,
        uint256 _salePrice
    ) external view virtual override returns (address, uint256)
    {
        return (royaltyAddress, calculateRoyalty(_salePrice));
    }

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC721, IERC165) returns (bool)
    {
        return
        interfaceId == type(IERC2981Royalties).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    /**
     * @notice Callback called from RandomGenerator upon random number generation
     * @param randomness random number generated
     * @param recipient token recipient
     */
    function randomMintCallback(
        uint256 randomness,
        address recipient
    ) external override {
        require(msg.sender == address(randomGenerator), "Only random generator");

        uint256 len = metadataHashList.length;
        uint256 rand = randomness % len;
        string memory metadataSelected = metadataHashList[rand];
        string memory last = metadataHashList[len - 1];

        metadataHashList.pop();

        if (rand < metadataHashList.length) {
            metadataHashList[rand] = last;
        }

        _safeMint(recipient, tokenIdTracker);
        _setTokenURI(tokenIdTracker, metadataSelected);
        tokenIdTracker += 1;

        emit MetadataHashClaimed(recipient, metadataSelected);
    }
}