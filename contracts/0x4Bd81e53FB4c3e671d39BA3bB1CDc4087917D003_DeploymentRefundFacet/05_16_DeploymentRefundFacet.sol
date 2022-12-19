//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IDeploymentRefund} from "../../interfaces/IDeploymentRefund.sol";
import {LibDeploymentRefund} from "../../libraries/LibDeploymentRefund.sol";
import {DiamondReentrancyGuard} from "../../access/DiamondReentrancyGuard.sol";

/// @author Amit Molek
/// @dev Please see `IDeploymentRefund` for docs
contract DeploymentRefundFacet is IDeploymentRefund, DiamondReentrancyGuard {
    function calculateDeploymentCostRefund(uint256 ownershipUnits)
        external
        view
        override
        returns (uint256)
    {
        return
            LibDeploymentRefund._calculateDeploymentCostRefund(ownershipUnits);
    }

    function deploymentCostToRefund() external view override returns (uint256) {
        return LibDeploymentRefund._deploymentCostToRefund();
    }

    function deploymentCostPaid() external view override returns (uint256) {
        return LibDeploymentRefund._deploymentCostPaid();
    }

    function refundable() external view override returns (uint256) {
        return LibDeploymentRefund._refundable();
    }

    function withdrawDeploymentRefund() external override nonReentrant {
        LibDeploymentRefund._withdrawDeploymentRefund();
    }

    function initDeploymentCost(uint256 deploymentGasUsed, address deployer_)
        external
        override
    {
        LibDeploymentRefund._initDeploymentCost(deploymentGasUsed, deployer_);
    }

    function deployer() external view override returns (address) {
        return LibDeploymentRefund._deployer();
    }

    /// @return the refund amount withdrawn by the deployer
    function withdrawnByDeployer() external view returns (uint256) {
        return LibDeploymentRefund._withdrawn();
    }

    /// @return true, if the deployer joined the group
    function isDeployerJoined() external view returns (bool) {
        return LibDeploymentRefund._isDeployerJoined();
    }
}