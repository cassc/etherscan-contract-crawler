// SPDX-License-Identifier: None
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./interfaces/IVaultBuilder.sol";
import "./interfaces/IMetaWealthModerator.sol";
import "./AssetVault.sol";

contract VaultBuilder is IVaultBuilder, Initializable, ContextUpgradeable {
    /// @notice MetaWealth moderator contract for currency and whitelist checks
    IMetaWealthModerator public metawealthMod;

    address beaconAddress;

    /// @notice Maintain a list of all the tokens fractionalized by the factory
    /// @dev Mapping is from collection address => NFT ID => Fractional Asset address
    mapping(address => mapping(uint256 => address)) public tokenFractions;

    modifier onlyAdmin() {
        require(
            metawealthMod.isAdmin(_msgSender()),
            "AccessControl: restricted to admin"
        );
        _;
    }
    modifier onlySuperAdmin() {
        require(
            metawealthMod.isSuperAdmin(_msgSender()),
            "AccessControl: restricted to super admin"
        );
        _;
    }

    /// @notice Initialize exchange contract with necessary factories
    /// @param metawealthMod_ is the moderator contract of MetaWealth platform
    function initialize(
        IMetaWealthModerator metawealthMod_
    ) public initializer {
        require(
            AddressUpgradeable.isContract(address(metawealthMod_)),
            "VaultBuilder: metawealthMod is not contract"
        );

        UpgradeableBeacon _beacon = new UpgradeableBeacon(
            address(new AssetVault())
        );
        _beacon.transferOwnership(address(this));
        beaconAddress = address(_beacon);
        metawealthMod = metawealthMod_;
    }

    function getBeacon() external view returns (address) {
        return beaconAddress;
    }

    function fractionalize(
        address collection,
        uint256 tokenId,
        address[] calldata payees,
        uint256[] calldata shares,
        string memory assetVaultName,
        string memory assetVaultSymbol,
        bytes32[] calldata _merkleProof
    ) public override returns (address newVault) {
        require(
            metawealthMod.checkWhitelist(_merkleProof, _msgSender()),
            "FractionalizedAsset: Access forbidden"
        );
        require(
            tokenFractions[collection][tokenId] == address(0),
            "Fractionalize: Already fractionalized"
        );
        require(
            IERC721Upgradeable(collection).ownerOf(tokenId) == _msgSender(),
            "Fractionalize: Not owner"
        );
        newVault = _createNewAssetVault(
            payees,
            shares,
            collection,
            tokenId,
            assetVaultName,
            assetVaultSymbol
        );

        tokenFractions[collection][tokenId] = newVault;

        /// @dev post-audit: Made the recipient AssetVault
        IERC721Upgradeable(collection).transferFrom(
            _msgSender(),
            newVault,
            tokenId
        );
        emit AssetFractionalized(collection, tokenId, newVault, payees, shares);
    }

    function onDefractionalize(
        address collection,
        uint256 tokenId,
        address shareholder
    ) external override returns (bool) {
        address vault = tokenFractions[collection][tokenId];
        require(_msgSender() == vault, "VaultBuilder: access denied");
        require(vault != address(0), "VaultBuilder: Already defractionalized");
        delete tokenFractions[collection][tokenId];

        emit AssetDefractionalized(
            collection,
            tokenId,
            _msgSender(),
            shareholder
        );
        return true;
    }

    function upgradeAssetVaults(
        address _newImplementation
    ) external onlySuperAdmin {
        UpgradeableBeacon(beaconAddress).upgradeTo(_newImplementation);
        emit AssetVaultUpdated(_newImplementation, _msgSender());
    }

    function _createNewAssetVault(
        address[] memory payees,
        uint256[] memory shares,
        address collection,
        uint256 tokenId,
        string memory _name,
        string memory _symbol
    ) private returns (address) {
        address proxy = address(
            new BeaconProxy(
                beaconAddress,
                abi.encodeWithSelector(
                    AssetVault(address(0)).initialize.selector,
                    payees,
                    shares,
                    metawealthMod,
                    address(this),
                    collection,
                    tokenId,
                    _name,
                    _symbol
                )
            )
        );

        return proxy;
    }

    uint256[47] private __gap;
}