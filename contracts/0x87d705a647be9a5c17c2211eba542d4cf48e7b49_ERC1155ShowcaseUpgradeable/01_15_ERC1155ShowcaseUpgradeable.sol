// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155PausableUpgradeable.sol";

contract ERC1155ShowcaseUpgradeable is Initializable, ContextUpgradeable, OwnableUpgradeable, ERC1155SupplyUpgradeable, ERC1155BurnableUpgradeable, ERC1155PausableUpgradeable {
    // Nft token name and symbol
    string private _name;
    string private _symbol;

    // ERC2981 interface id
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    // Mapping for nft token URIs
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
        __ERC1155Showcase_init(name_, symbol_, royaltyAddress_, royaltyPercent_);
    }

    function __ERC1155Showcase_init(
        string memory name_,
        string memory symbol_,
        address royaltyAddress_,
        uint256 royaltyPercent_
    ) internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ERC165_init_unchained();
        __Pausable_init_unchained();
        __ERC1155_init_unchained("");
        __ERC1155Supply_init_unchained();
        __ERC1155Burnable_init_unchained();
        __ERC1155Pausable_init_unchained();
        __ERC1155Showcase_init_unchained(name_, symbol_, royaltyAddress_, royaltyPercent_);
    }

    function __ERC1155Showcase_init_unchained(
        string memory name_,
        string memory symbol_,
        address royaltyAddress_,
        uint256 royaltyPercent_
    ) internal initializer {
        _name = name_;
        _symbol = symbol_;
        updateRoyaltyParams(royaltyAddress_, royaltyPercent_);
    }

    function name() external view virtual returns (string memory) {
        return _name;
    }

    function symbol() external view virtual returns (string memory) {
        return _symbol;
    }

    function getOwner() external view virtual returns (address) {
        return owner();
    }

    function uri(uint256 tokenId_) public view virtual override returns (string memory) {
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

    function supportsInterface(bytes4 interfaceId_) public view virtual override returns (bool) {
        return interfaceId_ == _INTERFACE_ID_ERC2981 || super.supportsInterface(interfaceId_);
    }

    function pause() external virtual onlyOwner {
        _pause();
    }

    function unpause() external virtual onlyOwner {
        _unpause();
    }

    function setTokenURI(uint256 tokenId_, string memory tokenURI_) external virtual onlyOwner {
        _tokenURIs[tokenId_] = tokenURI_;
        emit TokenURIUpdated(tokenId_, tokenURI_);
    }

    function updateRoyaltyParams(address royaltyAddress_, uint256 royaltyPercent_) public virtual onlyOwner {
        require(royaltyAddress_ != address(0), "ERC1155Showcase: invalid address");
        require(royaltyPercent_ <= _100_PERCENT, "ERC1155Showcase: invalid percent");
        _royaltyAddress = royaltyAddress_;
        _royaltyPercent = royaltyPercent_;
        emit RoyaltyParamsUpdated(royaltyAddress_, royaltyPercent_);
    }

    function mint(
        address to_,
        uint256 tokenId_,
        uint256 amount_,
        bytes memory data_
    ) external virtual onlyOwner {
        _mint(to_, tokenId_, amount_, data_);
    }

    function mintBatch(
        address to_,
        uint256[] memory tokenIds_,
        uint256[] memory amounts_,
        bytes memory data_
    ) external virtual onlyOwner {
        _mintBatch(to_, tokenIds_, amounts_, data_);
    }

    function _beforeTokenTransfer(
        address operator_,
        address from_,
        address to_,
        uint256[] memory tokenIds_,
        uint256[] memory amounts_,
        bytes memory data_
    ) internal virtual override(ERC1155Upgradeable, ERC1155SupplyUpgradeable, ERC1155PausableUpgradeable) {
        super._beforeTokenTransfer(operator_, from_, to_, tokenIds_, amounts_, data_);
    }
}