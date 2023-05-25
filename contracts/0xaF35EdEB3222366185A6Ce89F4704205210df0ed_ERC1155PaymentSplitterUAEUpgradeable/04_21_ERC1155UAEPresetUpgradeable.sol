// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155PausableUpgradeable.sol";

contract ERC1155UAEPresetUpgradeable is Initializable, ContextUpgradeable, OwnableUpgradeable, ERC1155SupplyUpgradeable, ERC1155BurnableUpgradeable, ERC1155PausableUpgradeable {
    // Nft token collection name
    string private _name;
    // Nft token collection symbol
    string private _symbol;
    // Nft token collection release token id
    uint256 private _releaseTokenId;
    // Nft token collection release token URI
    string private _releaseTokenUri;
    // Nft token collection release token supply
    uint256 private constant _RELEASE_TOKEN_SUPPLY = 1971;

    // Nft token collection royalty params
    address private _royaltyAddress;
    uint256 private _royaltyPercent;
    uint256 private constant _MAX_PERCENT = 2000; // 2000 equal 20%
    uint256 private constant _100_PERCENT = 10000; // 10000 equal 100%

    // Emitted when royalty params updated.
    event RoyaltyParamsUpdated(address account, uint256 percent);

    // Emitted when release token URI updated.
    event ReleaseTokenUriUpdated(string tokenURI);

    function __ERC1155UAEPreset_init(
        string memory name_,
        string memory symbol_,
        address releaseMintTo_,
        uint256 releaseTokenId_,
        string memory releaseTokenUri_,
        string memory defaultUri_
    ) internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ERC165_init_unchained();
        __ERC1155_init_unchained(defaultUri_);
        __ERC1155Supply_init_unchained();
        __ERC1155Burnable_init_unchained();
        __Pausable_init_unchained();
        __ERC1155Pausable_init_unchained();
        __ERC1155UAEPreset_init_unchained(name_, symbol_, releaseMintTo_, releaseTokenId_, releaseTokenUri_);
    }

    function __ERC1155UAEPreset_init_unchained(
        string memory name_,
        string memory symbol_,
        address releaseMintTo_,
        uint256 releaseTokenId_,
        string memory releaseTokenUri_
    ) internal initializer {
        require(releaseMintTo_ != address(0), "ERC1155UAE: invalid mint address");
        require(releaseTokenId_ != 0, "ERC1155UAE: invalid token id");

        _name = name_;
        _symbol = symbol_;
        _releaseTokenId = releaseTokenId_;
        _releaseTokenUri = releaseTokenUri_;

        _mint(releaseMintTo_, releaseTokenId_, _RELEASE_TOKEN_SUPPLY, "");
    }

    function name() external view virtual returns (string memory) {
        return _name;
    }

    function symbol() external view virtual returns (string memory) {
        return _symbol;
    }

    function getOwner() external view returns (address) {
        return owner();
    }

    function releaseTokenId() external view virtual returns (uint256) {
        return _releaseTokenId;
    }

    function releaseTokenSupply() external pure virtual returns (uint256) {
        return _RELEASE_TOKEN_SUPPLY;
    }

    function uri(uint256 tokenId_) public view virtual override returns (string memory) {
        if (tokenId_ == _releaseTokenId) {
            return _releaseTokenUri;
        }
        return super.uri(tokenId_);
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

    function tokenInfo(uint256 tokenId_) external view virtual returns (uint256 tokenSupply, string memory tokenUri) {
        return (
            totalSupply(tokenId_),
            uri(tokenId_)
        );
    }

    function supportsInterface(bytes4 interfaceId_)
        public
        view
        virtual
        override
        returns (bool)
    {
        return super.supportsInterface(interfaceId_);
    }

    function pause() external virtual onlyOwner {
        _pause();
    }

    function unpause() external virtual onlyOwner {
        _unpause();
    }

    function updateReleaseTokenURI(string memory releaseTokenUri_) external virtual onlyOwner {
        _releaseTokenUri = releaseTokenUri_;
        emit ReleaseTokenUriUpdated(releaseTokenUri_);
    }

    function updateRoyaltyParams(address royaltyAddress_, uint256 royaltyPercent_) external virtual onlyOwner {
        require(royaltyPercent_ <= _MAX_PERCENT, "ERC1155UAE: invalid percent");
        _royaltyAddress = royaltyAddress_;
        _royaltyPercent = royaltyPercent_;
        emit RoyaltyParamsUpdated(royaltyAddress_, royaltyPercent_);
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

    uint256[50] private __gap;
}