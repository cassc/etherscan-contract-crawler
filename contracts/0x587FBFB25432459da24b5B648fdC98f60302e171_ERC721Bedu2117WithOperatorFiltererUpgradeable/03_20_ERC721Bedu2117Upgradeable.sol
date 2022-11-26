// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";

contract ERC721Bedu2117Upgradeable is Initializable, ContextUpgradeable, OwnableUpgradeable, ERC721EnumerableUpgradeable, ERC721BurnableUpgradeable {
    using StringsUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    // ERC2981 interface id
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    // Nft token id tracker
    CountersUpgradeable.Counter private _tokenIdTracker;
    uint256 private constant _BATCH_LIMIT = 50;

    // Nft token URIs
    string private _defaultURI;
    string private _mainURI;

    // Contract's work modes
    bool private _mintingEnabled;
    bool private _transferEnabled;
    bool private _metadataRetrievalEnabled;

    // Mapping for frozen tokens
    mapping(uint256 => bool) private _frozenTokens;

    // Mapping for trusted minters
    mapping(address => bool) private _trustedMinters;

    // Mapping for trusted admins
    mapping(address => bool) private _trustedAdmins;

    // Nft token collection royalty params
    address private _royaltyAddress;
    uint256 private _royaltyPercent;
    uint256 private constant _100_PERCENT = 10000; // 10000 equal 100%

    // Emitted when default URI updated
    event DefaultURIUpdated(string uri);
    // Emitted when main URI updated.
    event MainURIUpdated(string uri);

    // Emitted when updated c contract's work modes
    event ContractWorkModesUpdated(bool mintingEnabled, bool transferEnabled, bool metadataRetrievalEnabled);

    // Emitted when list of `tokenIds` frozen status updated
    event FrozenTokenStatusUpdated(uint256[] tokenIds, bool freeze);

    // Emitted when address `account` trusted minter status updated
    event TrustedMinterStatusUpdated(address account, bool isTrustedMinter);

    // Emitted when address `account` trusted admin status updated
    event TrustedAdminStatusUpdated(address account, bool isTrustedAdmin);

    // Emitted when royalty params updated
    event RoyaltyParamsUpdated(address account, uint256 percent);

    modifier onlyTrustedMinter() {
        require(_trustedMinters[_msgSender()], "ERC721Bedu2117: caller is not trusted minter");
        _;
    }

    modifier onlyTrustedAdmin() {
        require(_trustedAdmins[_msgSender()], "ERC721Bedu2117: caller is not trusted admin");
        _;
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        string memory defaultURI_,
        string memory mainURI_
    ) public virtual initializer {
        __ERC721Bedu2117_init(name_, symbol_, defaultURI_, mainURI_);
    }

    function __ERC721Bedu2117_init(
        string memory name_,
        string memory symbol_,
        string memory defaultURI_,
        string memory mainURI_
    ) internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
        __ERC721Enumerable_init_unchained();
        __ERC721Burnable_init_unchained();
        __ERC721Bedu2117_init_unchained(defaultURI_, mainURI_);
    }

    function __ERC721Bedu2117_init_unchained(
        string memory defaultURI_,
        string memory mainURI_
    ) internal initializer {
        _mintingEnabled = true;
        _transferEnabled = true;
        _metadataRetrievalEnabled = true;
        setDefaultURI(defaultURI_);
        setMainURI(mainURI_);
    }

    function getTotalSupply() external view virtual returns (uint256) {
        return _tokenIdTracker.current();
    }

    function exists(uint256 tokenId_) external view virtual returns (bool) {
        return _exists(tokenId_);
    }

    function defaultURI() external view virtual returns (string memory) {
        return _defaultURI;
    }

    function mainURI() external view virtual returns (string memory) {
        return _mainURI;
    }

    function tokenURI(uint256 tokenId_) public view virtual override returns (string memory) {
        require(_exists(tokenId_), "ERC721Bedu2117: URI query for nonexistent token");
        return _metadataRetrievalEnabled ? string(abi.encodePacked(_mainURI, tokenId_.toString())) : _defaultURI;
    }

    function getContractWorkModes() external view virtual returns (bool mintingEnabled, bool transferEnabled, bool metadataRetrievalEnabled) {
        return (
            _mintingEnabled,
            _transferEnabled,
            _metadataRetrievalEnabled
        );
    }

    function checkFrozenTokenStatusesBatch(uint256[] memory tokenIds_) external view virtual returns (bool[] memory frozenTokenStatuses) {
        frozenTokenStatuses = new bool[](tokenIds_.length);
        for (uint256 i = 0; i < tokenIds_.length; ++i) {
            frozenTokenStatuses[i] = _frozenTokens[tokenIds_[i]];
        }
        return (
            frozenTokenStatuses
        );
    }

    function isTrustedMinter(address account_) external view virtual returns (bool) {
        return _trustedMinters[account_];
    }

    function isTrustedAdmin(address account_) external view virtual returns (bool) {
        return _trustedAdmins[account_];
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

    function setDefaultURI(string memory uri_) public virtual onlyOwner {
        require(bytes(uri_).length != 0, "ERC721Bedu2117: invalid uri");
        _defaultURI = uri_;
        emit DefaultURIUpdated(uri_);
    }

    function setMainURI(string memory uri_) public virtual onlyOwner {
        require(bytes(uri_).length != 0, "ERC721Bedu2117: invalid uri");
        _mainURI = uri_;
        emit MainURIUpdated(uri_);
    }

    function setContractWorkModes(bool mintingEnabled_, bool transferEnabled_, bool metadataRetrievalEnabled_) external virtual onlyOwner {
        _mintingEnabled = mintingEnabled_;
        _transferEnabled = transferEnabled_;
        _metadataRetrievalEnabled = metadataRetrievalEnabled_;
        emit ContractWorkModesUpdated(mintingEnabled_, transferEnabled_, metadataRetrievalEnabled_);
    }

    function updateTrustedMinterStatus(address account_, bool isMinter_) external virtual onlyOwner {
        require(account_ != address(0), "ERC721Bedu2117: invalid address");
        _trustedMinters[account_] = isMinter_;
        emit TrustedMinterStatusUpdated(account_, isMinter_);
    }

    function updateTrustedAdminStatus(address account_, bool isAdmin_) external virtual onlyOwner {
        require(account_ != address(0), "ERC721Bedu2117: invalid address");
        _trustedAdmins[account_] = isAdmin_;
        emit TrustedAdminStatusUpdated(account_, isAdmin_);
    }

    function updateRoyaltyParams(address account_, uint256 percent_) external virtual onlyOwner {
        require((account_ != address(0) && percent_ > 0 && percent_ <= _100_PERCENT) || (account_ == address(0) && percent_ == 0), "ERC721Bedu2117: invalid percent");
        _royaltyAddress = account_;
        _royaltyPercent = percent_;
        emit RoyaltyParamsUpdated(account_, percent_);
    }

    function mintTokenBatchByTrustedMinter(address recipient_, uint256 tokenCount_) external virtual onlyTrustedMinter {
        require(recipient_ != address(0), "ERC721Bedu2117: invalid address");
        require(tokenCount_ > 0 && tokenCount_ <= _BATCH_LIMIT, "ERC721Bedu2117: invalid token count");
        for (uint256 i = 0; i < tokenCount_; ++i) {
            _tokenIdTracker.increment();
            _mint(recipient_, _tokenIdTracker.current());
        }
    }

    function freezeTokenTransferBatchByTrustedAdmin(uint256[] memory tokenIds_, bool freeze_) external virtual onlyTrustedAdmin {
        require(tokenIds_.length != 0, "ERC721Bedu2117: invalid tokenIds length");
        for (uint256 i = 0; i < tokenIds_.length; ++i) {
            _frozenTokens[tokenIds_[i]] = freeze_;
        }
        emit FrozenTokenStatusUpdated(tokenIds_, freeze_);
    }

    function burnTokenBatchByTrustedAdmin(uint256[] memory tokenIds_) external virtual onlyTrustedAdmin {
        require(tokenIds_.length > 0 && tokenIds_.length <= _BATCH_LIMIT, "ERC721Bedu2117: invalid tokenIds length");
        for (uint256 i = 0; i < tokenIds_.length; ++i) {
            require(_exists(tokenIds_[i]), "ERC721Bedu2117: query for nonexistent token");
            require(_frozenTokens[tokenIds_[i]], "ERC721Bedu2117: query for unfrozen token");
            _burn(tokenIds_[i]);
        }
    }

    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 tokenId_
    ) internal virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from_, to_, tokenId_);
        if (from_ == address(0)) {
            require(_mintingEnabled, "ERC721Bedu2117: Minting is disabled");
        } else {
            require(_transferEnabled, "ERC721Bedu2117: Transfers are disabled");
            require(!_frozenTokens[tokenId_] || (to_ == address(0) && _trustedAdmins[_msgSender()]), "ERC721Bedu2117: Token transfers are frozen");
        }
    }
}