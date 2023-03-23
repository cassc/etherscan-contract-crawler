pragma solidity ^0.8.18;

// SPDX-License-Identifier: MIT

interface ISyndicateFactory {

    /// @notice Emitted when a new syndicate instance is deployed
    event SyndicateDeployed(address indexed implementation);

    /// @notice Deploy a new knot syndicate with an initial set of KNOTs registered with the syndicate
    /// @param _contractOwner Ethereum public key that will receive management rights of the contract
    /// @param _priorityStakingEndBlock Block number when priority sETH staking ends and anyone can stake
    /// @param _priorityStakers Optional list of addresses that will have priority for staking sETH against each knot registered
    /// @param _blsPubKeysForSyndicateKnots List of BLS public keys of Stakehouse protocol registered KNOTs participating in syndicate
    function deploySyndicate(
        address _contractOwner,
        uint256 _priorityStakingEndBlock,
        address[] calldata _priorityStakers,
        bytes[] calldata _blsPubKeysForSyndicateKnots
    ) external returns (address);

    /// @notice Helper function to calculate the address of a syndicate contract before it is deployed (CREATE2)
    /// @param _deployer Address of the account that will trigger the deployment of a syndicate contract
    /// @param _contractOwner Address of the account that will be the initial owner for parameter management and knot expansion
    /// @param _numberOfInitialKnots Number of initial knots that will be registered to the syndicate
    function calculateSyndicateDeploymentAddress(
        address _deployer,
        address _contractOwner,
        uint256 _numberOfInitialKnots
    ) external view returns (address);

    /// @notice Helper function to generate the CREATE2 salt required for deployment
    /// @param _deployer Address of the account that will trigger the deployment of a syndicate contract
    /// @param _contractOwner Address of the account that will be the initial owner for parameter management and knot expansion
    /// @param _numberOfInitialKnots Number of initial knots that will be registered to the syndicate
    function calculateDeploymentSalt(
        address _deployer,
        address _contractOwner,
        uint256 _numberOfInitialKnots
    ) external pure returns (bytes32);
}