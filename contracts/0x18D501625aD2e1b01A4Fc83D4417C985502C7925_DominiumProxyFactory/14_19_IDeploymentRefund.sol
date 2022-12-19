//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Amit Molek
/// @dev Deployment refund actions
interface IDeploymentRefund {
    /// @dev Emitted on deployer withdraws deployment refund
    /// @param account the deployer that withdraw
    /// @param amount the refund amount
    event WithdrawnDeploymentRefund(address account, uint256 amount);

    /// @dev Emitted on deployment cost initialization
    /// @param gasUsed gas used in the group contract deployment
    /// @param gasPrice gas cost in the deployment
    /// @param deployer the account that deployed the group
    event InitializedDeploymentCost(
        uint256 gasUsed,
        uint256 gasPrice,
        address deployer
    );

    /// @dev Emitted on deployer joins the group
    /// @param ownershipUnits amount of ownership units acquired
    event DeployerJoined(uint256 ownershipUnits);

    /// @return The refund amount needed to be paid based on `units`.
    /// If the refund was fully funded, this will return 0
    /// If the refund amount is bigger than what is left to be refunded, this will return only
    /// what is left to be refunded. e.g. Need to refund 100 wei and 70 wei was already paid,
    /// if a new member joins and buys 40% ownership he will only need to pay 30 wei (100-70).
    function calculateDeploymentCostRefund(uint256 units)
        external
        view
        returns (uint256);

    /// @return The deployment cost needed to be refunded
    function deploymentCostToRefund() external view returns (uint256);

    /// @return The deployment cost already paid
    function deploymentCostPaid() external view returns (uint256);

    /// @return The refund amount that can be withdrawn by the deployer
    function refundable() external view returns (uint256);

    /// @notice Deployment cost refund withdraw (collected so far)
    /// @dev Refunds the deployer with the collected deployment cost
    /// Emits `WithdrawnDeploymentRefund` event
    function withdrawDeploymentRefund() external;

    /// @return The address of the contract/group deployer
    function deployer() external view returns (address);

    /// @dev Initializes the deployment cost.
    /// SHOULD be called together with the deployment of the contract, because this function uses
    /// `tx.gasprice`. So for the best accuracy initialize the contract and call this function in the same transaction.
    /// @param deploymentGasUsed Gas used to deploy the contract/group
    /// @param deployer_ The address who deployed the contract/group
    function initDeploymentCost(uint256 deploymentGasUsed, address deployer_)
        external;
}