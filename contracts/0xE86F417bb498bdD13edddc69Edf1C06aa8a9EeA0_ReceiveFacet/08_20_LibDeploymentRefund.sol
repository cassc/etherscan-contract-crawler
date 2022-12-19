//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {StorageDeploymentCost} from "../storage/StorageDeploymentCost.sol";
import {LibOwnership} from "./LibOwnership.sol";
import {LibTransfer} from "./LibTransfer.sol";

/// @author Amit Molek
/// @dev Please see `IDeploymentRefund` for docs
library LibDeploymentRefund {
    event WithdrawnDeploymentRefund(address account, uint256 amount);
    event InitializedDeploymentCost(
        uint256 gasUsed,
        uint256 gasPrice,
        address deployer
    );
    event DeployerJoined(uint256 ownershipUnits);

    /// @dev The total refund amount can't exceed the deployment cost, so
    /// if the deployment cost refund based on `ownershipUnits` exceeds the
    /// deployment cost, the refund will be equal to only the delta left (deploymentCost - paidSoFar)
    /// @return The deployment cost refund amount that needs to be paid,
    /// if the member acquires `ownershipUnits` ownership units
    function _calculateDeploymentCostRefund(uint256 ownershipUnits)
        internal
        view
        returns (uint256)
    {
        uint256 totalOwnershipUnits = LibOwnership._totalOwnershipUnits();

        require(
            ownershipUnits <= totalOwnershipUnits,
            "DeploymentRefund: Invalid units"
        );

        uint256 deploymentCost = _deploymentCostToRefund();
        uint256 refundPayment = (deploymentCost * ownershipUnits) /
            totalOwnershipUnits;
        uint256 paidSoFar = _deploymentCostPaid();

        // Can't refund more than the deployment cost
        return
            refundPayment + paidSoFar > deploymentCost
                ? deploymentCost - paidSoFar
                : refundPayment;
    }

    function _payDeploymentCost(uint256 refundAmount) internal {
        StorageDeploymentCost.DiamondStorage storage ds = StorageDeploymentCost
            .diamondStorage();

        ds.paid += refundAmount;
    }

    function _initDeploymentCost(uint256 deploymentGasUsed, address deployer)
        internal
    {
        require(
            deploymentGasUsed > 0,
            "DeploymentRefund: Deployment gas can't be 0"
        );
        require(
            deployer != address(0),
            "DeploymentRefund: Invalid deployer address"
        );

        StorageDeploymentCost.DiamondStorage storage ds = StorageDeploymentCost
            .diamondStorage();

        require(
            ds.deploymentCostToRefund == 0,
            "DeploymentRefund: Deployment cost already initialized"
        );

        uint256 gasPrice = tx.gasprice;
        ds.deploymentCostToRefund = deploymentGasUsed * gasPrice;
        ds.deployer = deployer;

        emit InitializedDeploymentCost(deploymentGasUsed, gasPrice, deployer);
    }

    function _deployerJoin(address member, uint256 deployerOwnershipUnits)
        internal
    {
        require(
            !_isDeployerJoined(),
            "DeploymentRefund: Deployer already joined"
        );

        require(
            _isDeploymentCostSet(),
            "DeploymentRefund: Must initialized deployment cost first"
        );

        require(member == _deployer(), "DeploymentRefund: Not the deployer");

        require(
            deployerOwnershipUnits > 0,
            "DeploymentRefund: Invalid ownership units"
        );

        StorageDeploymentCost.DiamondStorage storage ds = StorageDeploymentCost
            .diamondStorage();

        uint256 deployerDeploymentCost = _calculateDeploymentCostRefund(
            deployerOwnershipUnits
        );

        // The deployer already paid
        ds.paid += deployerDeploymentCost;
        // The deployer can't withdraw his payment
        ds.withdrawn += deployerDeploymentCost;
        ds.isDeployerJoined = true;

        emit DeployerJoined(deployerOwnershipUnits);
    }

    function _isDeploymentCostSet() internal view returns (bool) {
        StorageDeploymentCost.DiamondStorage storage ds = StorageDeploymentCost
            .diamondStorage();

        return ds.deploymentCostToRefund > 0;
    }

    function _deploymentCostToRefund() internal view returns (uint256) {
        StorageDeploymentCost.DiamondStorage storage ds = StorageDeploymentCost
            .diamondStorage();

        return ds.deploymentCostToRefund;
    }

    function _deploymentCostPaid() internal view returns (uint256) {
        StorageDeploymentCost.DiamondStorage storage ds = StorageDeploymentCost
            .diamondStorage();

        return ds.paid;
    }

    function _withdrawn() internal view returns (uint256) {
        StorageDeploymentCost.DiamondStorage storage ds = StorageDeploymentCost
            .diamondStorage();

        return ds.withdrawn;
    }

    function _deployer() internal view returns (address) {
        StorageDeploymentCost.DiamondStorage storage ds = StorageDeploymentCost
            .diamondStorage();

        return ds.deployer;
    }

    function _refundable() internal view returns (uint256) {
        return _deploymentCostPaid() - _withdrawn();
    }

    function _isDeployerJoined() internal view returns (bool) {
        StorageDeploymentCost.DiamondStorage storage ds = StorageDeploymentCost
            .diamondStorage();

        return ds.isDeployerJoined;
    }

    function _withdrawDeploymentRefund() internal {
        address deployer = _deployer();

        // Only the deployer can withdraw the deployment cost refund
        require(
            msg.sender == deployer,
            "DeploymentRefund: caller not the deployer"
        );

        uint256 refundAmount = _refundable();
        require(refundAmount > 0, "DeploymentRefund: nothing to withdraw");

        StorageDeploymentCost.DiamondStorage storage ds = StorageDeploymentCost
            .diamondStorage();
        ds.withdrawn += refundAmount;

        emit WithdrawnDeploymentRefund(deployer, refundAmount);

        LibTransfer._untrustedSendValue(payable(deployer), refundAmount);
    }
}