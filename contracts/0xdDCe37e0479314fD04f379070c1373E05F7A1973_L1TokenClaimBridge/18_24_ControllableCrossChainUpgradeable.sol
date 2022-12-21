// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./crosschain/CrosschainOrigin.sol";
import "./storage/ControllableCrossChainUpgradeableStorage.sol";

/**
 * Abstract contract to enable crosschain ownership, i.e., stores the data necessary
 * to implement onlyCrossChainOwner modifier.
 *
 * Also tracks the deployer, as a convenience to allow for set up by the deployer after
 * deployment and before transferring ownership to a crosschain owner
 */
abstract contract ControllableCrossChainUpgradeable {
    // MODIFIERS
    modifier onlyDeployer() {
        require(
            ControllableCrossChainUpgradeableStorage.get().deployer !=
                address(0) &&
                msg.sender ==
                ControllableCrossChainUpgradeableStorage.get().deployer,
            "Message sender is not the deployer"
        );
        _;
    }

    modifier onlyCrossChainOwner() {
        require(
            ControllableCrossChainUpgradeableStorage.get().crossChainOwner !=
                address(0) &&
                CrosschainOrigin.getCrosschainMessageSender() ==
                ControllableCrossChainUpgradeableStorage.get().crossChainOwner,
            "Crosschain message sender is not owner"
        );
        _;
    }

    // EXTERNAL + PUBLIC
    function transferOwnership(address newCrossChainOwner_)
        public
        onlyCrossChainOwner
    {
        require(
            newCrossChainOwner_ != address(0),
            "Ownable: new owner is the zero address"
        );
        _setCrossChainOwner(newCrossChainOwner_);
    }

    function setCrossChainOwnerAndRevokeDeployer(address crossChainOwner_)
        external
        onlyDeployer
    {
        require(
            crossChainOwner_ != address(0),
            "setCrossChainOwnerAndRevokeDeployer: new owner is the zero address"
        );

        _setCrossChainOwner(crossChainOwner_);
        _revokeDeployer();
    }

    function deployer() external view returns (address) {
        return ControllableCrossChainUpgradeableStorage.get().deployer;
    }

    function crossChainOwner() external view returns (address) {
        return ControllableCrossChainUpgradeableStorage.get().crossChainOwner;
    }

    // INTERNAL
    function _setCrossChainOwner(address crossChainOwner_) internal virtual {
        ControllableCrossChainUpgradeableStorage
            .get()
            .crossChainOwner = crossChainOwner_;
    }

    function _revokeDeployer() internal {
        ControllableCrossChainUpgradeableStorage.get().deployer = address(0);
    }

    function _setDeployer(address deployer_) internal {
        ControllableCrossChainUpgradeableStorage.get().deployer = deployer_;
    }
}