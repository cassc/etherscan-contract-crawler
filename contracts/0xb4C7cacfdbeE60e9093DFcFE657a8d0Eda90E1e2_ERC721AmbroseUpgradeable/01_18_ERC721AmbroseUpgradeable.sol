// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721PausableUpgradeable.sol";

contract ERC721AmbroseUpgradeable is Initializable, ContextUpgradeable, OwnableUpgradeable, ERC721EnumerableUpgradeable, ERC721BurnableUpgradeable, ERC721PausableUpgradeable {
    using StringsUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    // ERC2981 interface id
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    // Nft metadata params
    bool private _metadataLocked;
    string private _defaultUri;
    string private _mainUri;

    // Nft random params
    bool private _randomDataLocked;
    uint256 private _randomData;

    // Nft tokens max total supply and token id tracker
    uint256 private _maxTotalSupply;
    CountersUpgradeable.Counter private _tokenIdTracker;

    // Nft token collection royalty params
    address private _royaltyAddress;
    uint256 private _royaltyPercent;
    uint256 private constant _100_PERCENT = 10000; // 10000 equal 100%

    // Mapping for nft token trusted minters
    mapping(address => bool) private _trustedMinterList;

    // Emitted when metadata locked
    event MetadataLocked(string mainUri);
    // Emitted when metadata unlocked
    event MetadataUnlocked();
    // Emitted when default uri update
    event DefaultUriUpdated(string defaultUri);
    // Emitted when main uri update
    event MainUriUpdated(string mainUri);

    // Emitted when random data locked
    event RandomDataLocked(uint256 randomData);

    // Emitted when max token total supply update
    event MaxTotalSupplyUpdated(uint256 maxTotalSupply);

    // Emitted when royalty params updated
    event RoyaltyParamsUpdated(address account, uint256 percent);

    // Emitted when `account` added to trusted minter list.
    event AddToTrustedMinterList(address account);
    // Emitted when `account` removed from trusted minter list.
    event RemoveFromTrustedMinterList(address account);

    modifier notLockedMetadata() {
        require(!_metadataLocked, "ERC721Ambrose: metadata is locked");
        _;
    }

    modifier notLockedRandomData() {
        require(!_randomDataLocked, "ERC721Ambrose: randomData is locked");
        _;
    }

    modifier onlyTrustedMinter() {
        require(_trustedMinterList[_msgSender()], "ERC721Ambrose: caller is not trusted minter");
        _;
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        string memory defaultUri_,
        uint256 maxTotalSupply_
    ) public virtual initializer {
        __ERC721Ambrose_init(name_, symbol_, defaultUri_, maxTotalSupply_);
    }

    function __ERC721Ambrose_init(
        string memory name_,
        string memory symbol_,
        string memory defaultUri_,
        uint256 maxTotalSupply_
    ) internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
        __ERC721Enumerable_init_unchained();
        __ERC721Burnable_init_unchained();
        __Pausable_init_unchained();
        __ERC721Pausable_init_unchained();
        __ERC721Ambrose_init_unchained(defaultUri_, maxTotalSupply_);
    }

    function __ERC721Ambrose_init_unchained(string memory defaultUri_, uint256 maxTotalSupply_) internal initializer {
        require(bytes(defaultUri_).length != 0, "ERC721Ambrose: invalid default uri");
        require(maxTotalSupply_ != 0, "ERC721Ambrose: invalid max total supply");
        _defaultUri = defaultUri_;
        _maxTotalSupply = maxTotalSupply_;
    }

    function getOwner() external view virtual returns (address) {
        return owner();
    }

    function metadataInfo() external view virtual returns (bool metadataLocked, string memory defaultUri, string memory mainUri) {
        return (
            _metadataLocked,
            _defaultUri,
            _mainUri
        );
    }

    function randomDataInfo() external view virtual returns (bool randomDataLocked, uint256 randomData) {
        return (
            _randomDataLocked,
            _randomData
        );
    }

    function getMaxTotalSupply() public view virtual returns (uint256) {
        return _maxTotalSupply;
    }

    function getTotalSupply() public view virtual returns (uint256) {
        return _tokenIdTracker.current();
    }

    function stats() external view virtual returns (uint256 maxTotalSupply, uint256 totalSupply, uint256 supplyLeft) {
        maxTotalSupply = getMaxTotalSupply();
        totalSupply = getTotalSupply();
        return (
            maxTotalSupply,
            totalSupply,
            maxTotalSupply - totalSupply
        );
    }

    function exists(uint256 tokenId_) external view virtual returns (bool) {
        return _exists(tokenId_);
    }

    function tokenURI(uint256 tokenId_) public view virtual override returns (string memory) {
        require(_exists(tokenId_), "ERC721Ambrose: URI query for nonexistent token");
        return _metadataLocked ? string(abi.encodePacked(_mainUri, tokenId_.toString(), ".json")) : _defaultUri;
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

    function isTrustedMinter(address account_) external view virtual returns (bool) {
        return _trustedMinterList[account_];
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

    function lockMetadata() external virtual onlyOwner notLockedMetadata {
        require(bytes(_mainUri).length != 0, "ERC721Ambrose: invalid main uri");
        _metadataLocked = true;
        emit MetadataLocked(_mainUri);
    }

    function unlockMetadata() external virtual onlyOwner {
        require(_metadataLocked, "ERC721Ambrose: metadata is not locked");
        _metadataLocked = false;
        emit MetadataUnlocked();
    }

    function updateDefaultUri(string memory defaultUri_) external virtual onlyOwner notLockedMetadata {
        require(bytes(defaultUri_).length != 0, "ERC721Ambrose: invalid default uri");
        _defaultUri = defaultUri_;
        emit DefaultUriUpdated(defaultUri_);
    }

    function updateMainUri(string memory mainUri_) external virtual onlyOwner notLockedMetadata {
        require(bytes(mainUri_).length != 0, "ERC721Ambrose: invalid main uri");
        _mainUri = mainUri_;
        emit MainUriUpdated(mainUri_);
    }

    function lockRandomData() external virtual onlyOwner notLockedRandomData {
        _randomDataLocked = true;
        emit RandomDataLocked(_randomData);
    }

    function updateMaxTotalSupply(uint256 maxTotalSupply_) external virtual onlyOwner {
        require(maxTotalSupply_ >= getTotalSupply(), "ERC721Ambrose: invalid max total supply");
        _maxTotalSupply = maxTotalSupply_;
        emit MaxTotalSupplyUpdated(maxTotalSupply_);
    }

    function updateRoyaltyParams(address account_, uint256 percent_) external virtual onlyOwner {
        require(account_ != address(0), "ERC721Ambrose: invalid address");
        require(percent_ <= _100_PERCENT, "ERC721Ambrose: invalid percent");
        _royaltyAddress = account_;
        _royaltyPercent = percent_;
        emit RoyaltyParamsUpdated(account_, percent_);
    }

    function addToTrustedMinterList(address account_) external virtual onlyOwner {
        require(account_ != address(0), "ERC721Ambrose: invalid address");
        _trustedMinterList[account_] = true;
        emit AddToTrustedMinterList(account_);
    }

    function removeFromTrustedMinterList(address account_) external virtual onlyOwner {
        require(account_ != address(0), "ERC721Ambrose: invalid address");
        _trustedMinterList[account_] = false;
        emit RemoveFromTrustedMinterList(account_);
    }

    function mintTokenBatch(address recipient_, uint256 tokenCount_) external virtual onlyTrustedMinter {
        _mintTokenBatch(recipient_, tokenCount_);
    }

    function _mintTokenBatch(address recipient_, uint256 tokenCount_) internal virtual {
        require(recipient_ != address(0), "ERC721Ambrose: invalid address");
        require(tokenCount_ != 0, "ERC721Ambrose: invalid token count");
        require((tokenCount_ + getTotalSupply()) <= getMaxTotalSupply(), "ERC721Ambrose: max total supply limit reached");
        for (uint256 i = 0; i < tokenCount_; ++i) {
            _tokenIdTracker.increment();
            _mint(recipient_, _tokenIdTracker.current());
        }
        _updateRandomData(recipient_, tokenCount_);
    }

    function _updateRandomData(address account_, uint256 tokenCount_) internal virtual {
        if (!_randomDataLocked) {
            _randomData = (_randomData >> 128) ^ uint256(keccak256(abi.encodePacked(
                address(this),
                _randomData,
                block.difficulty,
                block.number,
                block.timestamp,
                account_,
                tokenCount_
            )));
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