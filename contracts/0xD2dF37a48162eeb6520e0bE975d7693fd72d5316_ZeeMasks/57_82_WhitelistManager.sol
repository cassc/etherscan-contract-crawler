// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "../../../acl/access-controlled/AccessControlledUpgradeable.sol";
import "../configuration/ConfigurationControlled.sol";
import "../../../common/BlockAware.sol";
import "../configuration/Features.sol";
import "./IWhitelistManager.sol";

contract WhitelistManager is
    IWhitelistManager,
    UUPSUpgradeable,
    ConfigurationControlled,
    AccessControlledUpgradeable,
    BlockAware
{
    bytes32 private constant _WHITELIST_MERKLE_ROOT_SLOT =
        bytes32(uint256(keccak256("zee-game.whitelist.merkle-root")) - 1);
    mapping(address => WhitelistOverride) private _whitelistOverrides;

    /// @dev Constructor that gets called for the implementation contract.
    constructor() initializer {
        // solhint-disable-previous-line no-empty-blocks
    }

    // solhint-disable-next-line comprehensive-interface
    function initialize(address configuration, address acl) external initializer {
        __BlockAware_init();
        __UUPSUpgradeable_init();
        __ConfigurationControlled_init(configuration);
        __AccessControlled_init(acl);
    }

    /// @inheritdoc IWhitelistManager
    function addUserToWhitelist(address account) external override whenEnabled(Features._WHITELIST) onlyMaintainer {
        _whitelistOverrides[account] = WhitelistOverride({blocked: false, whitelisted: true});

        emit AddedToWhitelist(account);
    }

    /// @inheritdoc IWhitelistManager
    function removeUserFromWhitelist(address account) external override onlyMaintainer {
        _whitelistOverrides[account] = WhitelistOverride({blocked: true, whitelisted: false});

        emit RemovedFromWhitelist(account);
    }

    /// @inheritdoc IWhitelistManager
    function setWhitelistMerkleRoot(bytes32 merkleRoot)
        external
        override
        onlyMaintainer
        whenEnabled(Features._CONFIGURING)
    {
        StorageSlot.getBytes32Slot(_WHITELIST_MERKLE_ROOT_SLOT).value = merkleRoot;

        emit MerkleRootSet(merkleRoot);
    }

    /// @inheritdoc IWhitelistManager
    function enableWhitelist() external override onlyMaintainer whenDisabled(Features._WHITELIST) {
        if (_getWhitelistMerkleRoot() == bytes32(0)) revert MerkleRootNotSet();
        _enableFeature(Features._WHITELIST);
    }

    /// @inheritdoc IWhitelistManager
    function disableWhitelist() external override onlyMaintainer whenEnabled(Features._WHITELIST) {
        _disableFeature(Features._WHITELIST);
    }

    /// @inheritdoc IWhitelistManager
    function isUserWhitelisted(address account, bytes32[] memory whitelistProof) external view override returns (bool) {
        return _isUserWhitelisted(account, whitelistProof);
    }

    /// @inheritdoc IWhitelistManager
    function getWhitelistMerkleRoot() external view override returns (bytes32) {
        return _getWhitelistMerkleRoot();
    }

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address) internal override onlyAdmin {
        // solhint-disable-previous-line no-empty-blocks
    }

    /// @dev Verify if the merkle proof is valid.
    function _isValidMerkleProof(address account, bytes32[] memory proof) internal view returns (bool) {
        return MerkleProof.verify(proof, _getWhitelistMerkleRoot(), _constructHash(account));
    }

    /// @dev Construct the hash used for merkle root validation.
    function _constructHash(address account) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(address(this), account, block.chainid));
    }

    /// @dev Return the merkle root.
    function _getWhitelistMerkleRoot() internal view virtual returns (bytes32) {
        return StorageSlot.getBytes32Slot(_WHITELIST_MERKLE_ROOT_SLOT).value;
    }

    /// @dev Make sure that the user has been whitelisted.
    /// @dev if the user has been manually whitelisted, the `whitelistProof` can be an empty array.
    function _isUserWhitelisted(address account, bytes32[] memory whitelistProof) internal view returns (bool) {
        // Everyone is whitelisted while the whitelist is disabled.
        if (_getFeature(Features._WHITELIST)) {
            return
                !_whitelistOverrides[account].blocked &&
                (_whitelistOverrides[account].whitelisted || _isValidMerkleProof(account, whitelistProof));
        }
        return true;
    }
}