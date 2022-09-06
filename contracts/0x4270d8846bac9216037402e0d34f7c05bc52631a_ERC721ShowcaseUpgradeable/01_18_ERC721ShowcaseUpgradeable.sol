// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721PausableUpgradeable.sol";

contract ERC721ShowcaseUpgradeable is Initializable, ContextUpgradeable, OwnableUpgradeable, ERC721EnumerableUpgradeable, ERC721BurnableUpgradeable, ERC721PausableUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    // ERC2981 interface id
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    // Nft token id tracker
    CountersUpgradeable.Counter private _tokenIdTracker;
    uint256 private constant _PER_MINT_LIMIT = 30;

    // Nft token URIs
    mapping(uint256 => string) private _tokenURIs;

    // Nft token royalty params
    address private _royaltyAddress;
    uint256 private _royaltyPercent;
    uint256 private constant _100_PERCENT = 10000; // 10000 equal 100%

    // Emitted when token URI updated.
    event TokenURIUpdated(uint256 tokenId, string tokenURI);

    // Emitted when royalty params updated
    event RoyaltyParamsUpdated(address royaltyAddress, uint256 royaltyPercent);

    function initialize(
        string memory name_,
        string memory symbol_,
        address royaltyAddress_,
        uint256 royaltyPercent_
    ) public virtual initializer {
        __ERC721Showcase_init(name_, symbol_, royaltyAddress_, royaltyPercent_);
    }

    function __ERC721Showcase_init(
        string memory name_,
        string memory symbol_,
        address royaltyAddress_,
        uint256 royaltyPercent_
    ) internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
        __ERC721Enumerable_init_unchained();
        __ERC721Burnable_init_unchained();
        __Pausable_init_unchained();
        __ERC721Pausable_init_unchained();
        __ERC721Showcase_init_unchained(royaltyAddress_, royaltyPercent_);
    }

    function __ERC721Showcase_init_unchained(
        address royaltyAddress_,
        uint256 royaltyPercent_
    ) internal initializer {
        updateRoyaltyParams(royaltyAddress_, royaltyPercent_);
    }

    function getOwner() external view virtual returns (address) {
        return owner();
    }

    function getTotalSupply() external view virtual returns (uint256) {
        return _tokenIdTracker.current();
    }

    function exists(uint256 tokenId_) external view virtual returns (bool) {
        return _exists(tokenId_);
    }

    function tokenURI(uint256 tokenId_) public view virtual override returns (string memory) {
        require(_exists(tokenId_), "ERC721Showcase: URI query for nonexistent token");
        return _tokenURIs[tokenId_];
    }

    function royaltyParams() external view virtual returns (address royaltyAddress, uint256 royaltyPercent) {
        return (
            _royaltyAddress,
            _royaltyPercent
        );
    }

    function royaltyInfo(
        uint256 /*tokenId_*/,
        uint256 salePrice_
    ) external view virtual returns (
        address receiver,
        uint256 royaltyAmount
    ) {
        receiver = _royaltyAddress;
        royaltyAmount = salePrice_ * _royaltyPercent / _100_PERCENT;
        return (
            receiver,
            royaltyAmount
        );
    }

    function supportsInterface(bytes4 interfaceId_) public view virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable) returns (bool) {
        return interfaceId_ == _INTERFACE_ID_ERC2981 || super.supportsInterface(interfaceId_);
    }

    function pause() external virtual onlyOwner {
        _pause();
    }

    function unpause() external virtual onlyOwner {
        _unpause();
    }

    function setTokenURI(uint256 tokenId_, string memory tokenURI_) external virtual onlyOwner {
        require(tokenId_ != 0, "ERC721Showcase: invalid token id");
        _tokenURIs[tokenId_] = tokenURI_;
        emit TokenURIUpdated(tokenId_, tokenURI_);
    }

    function updateRoyaltyParams(address royaltyAddress_, uint256 royaltyPercent_) public virtual onlyOwner {
        require(royaltyAddress_ != address(0), "ERC721Showcase: invalid address");
        require(royaltyPercent_ <= _100_PERCENT, "ERC721Showcase: invalid percent");
        _royaltyAddress = royaltyAddress_;
        _royaltyPercent = royaltyPercent_;
        emit RoyaltyParamsUpdated(royaltyAddress_, royaltyPercent_);
    }

    function mintTokenBatch(address recipient_, uint256 tokenCount_) external virtual onlyOwner {
        _mintTokenBatch(recipient_, tokenCount_);
    }

    function _mintTokenBatch(address recipient_, uint256 tokenCount_) internal virtual {
        require(recipient_ != address(0), "ERC721Showcase: invalid address");
        require(tokenCount_ > 0 && tokenCount_ <= _PER_MINT_LIMIT, "ERC721Showcase: invalid token count");
        for (uint256 i = 0; i < tokenCount_; ++i) {
            _tokenIdTracker.increment();
            _mint(recipient_, _tokenIdTracker.current());
        }
    }

    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 tokenId_
    ) internal virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721PausableUpgradeable) {
        super._beforeTokenTransfer(from_, to_, tokenId_);
    }
}