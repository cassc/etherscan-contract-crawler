// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "../../interfaces/IMetadataFreezable.sol";

abstract contract MetadataFreezableUpgradeable is Initializable, ERC165Upgradeable, IMetadataFreezable {
    bool private _allMetadataFrozen;
    mapping(uint256 => bool) private _metadataFrozen;

    event MetadataFrozen(uint256 indexed tokenId);
    event AllMetadataFrozen();

    modifier onlyNotFrozen(uint256 tokenId) {
        require(!_allMetadataFrozen && !_metadataFrozen[tokenId], "Metadata is frozen");
        _;
    }

    function __MetadataFreezable_init() internal onlyInitializing {
        __ERC165_init_unchained();
        __MetadataFreezable_init_unchained();
    }

    function __MetadataFreezable_init_unchained() internal onlyInitializing {}

    function hasFrozenMetadata(uint256 tokenId) external view returns (bool) {
        return _allMetadataFrozen || _metadataFrozen[tokenId];
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable) returns (bool) {
        return interfaceId == type(IMetadataFreezable).interfaceId || super.supportsInterface(interfaceId);
    }

    function _freezeAllMetadata() internal {
        _allMetadataFrozen = true;
        emit AllMetadataFrozen();
    }

    function _freezeMetadata(uint256 tokenId) internal {
        _metadataFrozen[tokenId] = true;
        emit MetadataFrozen(tokenId);
    }

    uint256[50] private __gap;
}