// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721PausableUpgradeable.sol";

contract ERC721BeduDffUpgradeable is Initializable, ContextUpgradeable, OwnableUpgradeable, ERC721EnumerableUpgradeable, ERC721BurnableUpgradeable, ERC721PausableUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    // ERC2981 interface id
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    // Nft token id tracker
    CountersUpgradeable.Counter private _tokenIdTracker;
    uint256 private constant _MINT_LIMIT = 50;

    // Nft token URIs
    string private _defaultURI;
    mapping(uint256 => string) private _tokenURIs;

    // Nft token collection royalty params
    address private _royaltyAddress;
    uint256 private _royaltyPercent;
    uint256 private constant _100_PERCENT = 10000; // 10000 equal 100%

    // Mapping for nft token trusted minters
    mapping(address => bool) private _trustedMinterList;

    // Mapping for trusted admins
    mapping(address => bool) private _trustedAdminList;

    // Global transfer mode: 0 - AnyTransferForbidden, 1 - AnyTransferAllowed, 2 - TransferAllowedPerTokenSettings
    enum GlobalTransferMode {
        AnyTransferForbidden,
        AnyTransferAllowed,
        TransferAllowedPerTokenSettings
    }
    GlobalTransferMode private _globalTransferMode;

    // Mapping for token transfer settings. Token transfer mode: 0 - AnyTransferForbidden, 1 - AnyTransferAllowed, 2 - TransferAllowedToSingleAddress
    enum TokenTransferMode {
        AnyTransferForbidden,
        AnyTransferAllowed,
        TransferAllowedToSingleAddress
    }
    struct TokenTransferSetting {
        TokenTransferMode transferMode;
        address singleAddress;
    }
    mapping(uint256 => TokenTransferSetting) private _tokenTransferSettings;

    // Emitted when default URI updated
    event DefaultURIUpdated(string defaultURI);
    // Emitted when token URI updated.
    event TokenURIUpdated(uint256 tokenId, string tokenURI);

    // Emitted when royalty params updated
    event RoyaltyParamsUpdated(address account, uint256 percent);

    // Emitted when `account` added to trusted minter list.
    event AddToTrustedMinterList(address account);
    // Emitted when `account` removed from trusted minter list.
    event RemoveFromTrustedMinterList(address account);

    // Emitted when `account` added to trusted admin list.
    event AddToTrustedAdminList(address account);
    // Emitted when `account` removed from trusted admin list.
    event RemoveFromTrustedAdminList(address account);

    // Emitted when updated global transfer mode
    event GlobalTransferModeUpdated(GlobalTransferMode transferMode);

    // Emitted when token `tokenIds` transfer setting updated
    event TokenTransferSettingUpdated(uint256[] tokenIds, TokenTransferMode transferMode, address singleAddress);

    modifier onlyTrustedMinter() {
        require(_trustedMinterList[_msgSender()], "ERC721BeduDff: caller is not trusted minter");
        _;
    }

    modifier onlyTrustedAdmin() {
        require(_trustedAdminList[_msgSender()], "ERC721BeduDff: caller is not trusted admin");
        _;
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        string memory defaultURI_
    ) public virtual initializer {
        __ERC721BeduDff_init(name_, symbol_, defaultURI_);
    }

    function __ERC721BeduDff_init(
        string memory name_,
        string memory symbol_,
        string memory defaultURI_
    ) internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
        __ERC721Enumerable_init_unchained();
        __ERC721Burnable_init_unchained();
        __Pausable_init_unchained();
        __ERC721Pausable_init_unchained();
        __ERC721BeduDff_init_unchained(defaultURI_);
    }

    function __ERC721BeduDff_init_unchained(string memory defaultURI_) internal initializer {
        _globalTransferMode = GlobalTransferMode.TransferAllowedPerTokenSettings;
        updateDefaultURI(defaultURI_);
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

    function defaultURI() external view virtual returns (string memory) {
        return _defaultURI;
    }

    function tokenURI(uint256 tokenId_) public view virtual override returns (string memory) {
        require(_exists(tokenId_), "ERC721BeduDff: URI query for nonexistent token");
        return bytes(_tokenURIs[tokenId_]).length > 0 ? _tokenURIs[tokenId_] : _defaultURI;
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

    function isTrustedAdmin(address account_) external view virtual returns (bool) {
        return _trustedAdminList[account_];
    }

    function globalTransferMode() external view virtual returns (GlobalTransferMode) {
        return _globalTransferMode;
    }

    function getTokenTransferSettingsBatch(uint256[] memory tokenIds_)
        external
        view
        virtual
        returns (
            TokenTransferMode[] memory transferModeList,
            address[] memory singleAddressList
        )
    {
        transferModeList = new TokenTransferMode[](tokenIds_.length);
        singleAddressList = new address[](tokenIds_.length);
        for (uint256 i = 0; i < tokenIds_.length; ++i) {
            TokenTransferSetting storage transferSetting = _tokenTransferSettings[tokenIds_[i]];
            transferModeList[i] = transferSetting.transferMode;
            singleAddressList[i] = transferSetting.singleAddress;
        }
        return (
            transferModeList,
            singleAddressList
        );
    }

    function checkTokenTransferAvailability(uint256 tokenId_, address transferTo_) public view virtual returns (bool) {
        require(!paused(), "ERC721BeduDff: contract is paused");
        require(_exists(tokenId_), "ERC721BeduDff: query for nonexistent token");
        require(_globalTransferMode != GlobalTransferMode.AnyTransferForbidden, "ERC721BeduDff: any contracts transfers forbidden");
        if (_globalTransferMode == GlobalTransferMode.TransferAllowedPerTokenSettings) {
            TokenTransferSetting storage transferSetting = _tokenTransferSettings[tokenId_];
            require(transferSetting.transferMode == TokenTransferMode.AnyTransferAllowed
                || (transferSetting.transferMode == TokenTransferMode.TransferAllowedToSingleAddress && transferSetting.singleAddress == transferTo_), "ERC721BeduDff: token transfers forbidden");
        }
        return true;
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

    function updateDefaultURI(string memory defaultURI_) public virtual onlyOwner {
        require(bytes(defaultURI_).length != 0, "ERC721BeduDff: invalid default uri");
        _defaultURI = defaultURI_;
        emit DefaultURIUpdated(defaultURI_);
    }

    function setTokenURI(uint256 tokenId_, string memory tokenURI_) external virtual onlyOwner {
        require(tokenId_ != 0, "ERC721BeduDff: invalid token id");
        _tokenURIs[tokenId_] = tokenURI_;
        emit TokenURIUpdated(tokenId_, tokenURI_);
    }

    function updateRoyaltyParams(address account_, uint256 percent_) external virtual onlyOwner {
        require((account_ != address(0) && percent_ > 0 && percent_ <= _100_PERCENT) || (account_ == address(0) && percent_ == 0), "ERC721BeduDff: invalid percent");
        _royaltyAddress = account_;
        _royaltyPercent = percent_;
        emit RoyaltyParamsUpdated(account_, percent_);
    }

    function addToTrustedMinterList(address account_) external virtual onlyOwner {
        require(account_ != address(0), "ERC721BeduDff: invalid address");
        _trustedMinterList[account_] = true;
        emit AddToTrustedMinterList(account_);
    }

    function removeFromTrustedMinterList(address account_) external virtual onlyOwner {
        require(account_ != address(0), "ERC721BeduDff: invalid address");
        _trustedMinterList[account_] = false;
        emit RemoveFromTrustedMinterList(account_);
    }

    function addToTrustedAdminList(address account_) external virtual onlyOwner {
        require(account_ != address(0), "ERC721BeduDff: invalid address");
        _trustedAdminList[account_] = true;
        emit AddToTrustedAdminList(account_);
    }

    function removeFromTrustedAdminList(address account_) external virtual onlyOwner {
        require(account_ != address(0), "ERC721BeduDff: invalid address");
        _trustedAdminList[account_] = false;
        emit RemoveFromTrustedAdminList(account_);
    }

    function mintTokenBatch(address recipient_, uint256 tokenCount_) external virtual onlyTrustedMinter {
        require(recipient_ != address(0), "ERC721BeduDff: invalid address");
        require(tokenCount_ > 0 && tokenCount_ <= _MINT_LIMIT, "ERC721BeduDff: invalid token count");
        for (uint256 i = 0; i < tokenCount_; ++i) {
            _tokenIdTracker.increment();
            _mint(recipient_, _tokenIdTracker.current());
        }
    }

    function updateGlobalTransferMode(GlobalTransferMode transferMode_) external virtual onlyTrustedAdmin {
        _globalTransferMode = transferMode_;
        emit GlobalTransferModeUpdated(transferMode_);
    }

    function updateTokenTransferSettingsBatch(uint256[] memory tokenIds_, TokenTransferMode transferMode_, address singleAddress_) external virtual onlyTrustedAdmin {
        require(tokenIds_.length != 0, "ERC721BeduDff: invalid tokenIds length");
        require((transferMode_ != TokenTransferMode.TransferAllowedToSingleAddress && singleAddress_ == address(0))
            || (transferMode_ == TokenTransferMode.TransferAllowedToSingleAddress && singleAddress_ != address(0)), "ERC721BeduDff: invalid address");
        for (uint256 i = 0; i < tokenIds_.length; ++i) {
            TokenTransferSetting storage transferSetting = _tokenTransferSettings[tokenIds_[i]];
            transferSetting.transferMode = transferMode_;
            transferSetting.singleAddress = singleAddress_;
        }
        emit TokenTransferSettingUpdated(tokenIds_, transferMode_, singleAddress_);
    }

    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 tokenId_
    ) internal virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721PausableUpgradeable) {
        super._beforeTokenTransfer(from_, to_, tokenId_);
        if (from_ != address(0)) {
            checkTokenTransferAvailability(tokenId_, to_);
        }
    }
}