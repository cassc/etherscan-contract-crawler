// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

interface IPoolDeployer {

    /**
     *  @dev   Emitted when a new pool is deployed.
     *  @param pool_              The address of the Pool deployed.
     *  @param poolManager_       The address of the PoolManager deployed.
     *  @param withdrawalManager_ The address of the WithdrawalManager deployed.
     *  @param loanManagers_      An array of the addresses of the LoanManagers deployed.
     */
    event PoolDeployed(address indexed pool_, address indexed poolManager_, address indexed withdrawalManager_, address[] loanManagers_);

    /**
     *  @dev   Deploys a pool along with its dependencies.
     *  @param poolManagerFactory_       The address of the PoolManager factory to use.
     *  @param withdrawalManagerFactory_ The address of the WithdrawalManager factory to use.
     *  @param loanManagerFactories_     An array of LoanManager factories to use.
     *  @param configParams_             Array of uint256 config parameters. Array used to avoid stack too deep issues.
     *                                    [0]: liquidityCap
     *                                    [1]: delegateManagementFeeRate
     *                                    [2]: coverAmountRequired
     *                                    [3]: cycleDuration
     *                                    [4]: windowDuration
     *                                    [5]: initialSupply
     *  @return poolManager_ The address of the PoolManager.
     */
    function deployPool(
        address           poolManagerFactory_,
        address           withdrawalManagerFactory_,
        address[]  memory loanManagerFactories_,
        address           asset_,
        string     memory name_,
        string     memory symbol_,
        uint256[6] memory configParams_
    )
        external
        returns (address poolManager_);

    /**
     *  @dev   Gets the addresses that would result from a deployment.
     *  @param poolDelegate_             The address of the PoolDelegate that will deploy the Pool.
     *  @param poolManagerFactory_       The address of the PoolManager factory to use.
     *  @param withdrawalManagerFactory_ The address of the WithdrawalManager factory to use.
     *  @param loanManagerFactories_     An array of LoanManager factories to use.
     *  @param configParams_             Array of uint256 config parameters. Array used to avoid stack too deep issues.
     *                                    [0]: liquidityCap
     *                                    [1]: delegateManagementFeeRate
     *                                    [2]: coverAmountRequired
     *                                    [3]: cycleDuration
     *                                    [4]: windowDuration
     *                                    [5]: initialSupply
     *  @return poolManager_       The address of the PoolManager contract that will be deployed.
     *  @return pool_              The address of the Pool contract that will be deployed.
     *  @return poolDelegateCover_ The address of the PoolDelegateCover contract that will be deployed.
     *  @return withdrawalManager_ The address of the WithdrawalManager contract that will be deployed.
     *  @return loanManagers_      The address of the LoanManager contracts that will be deployed.
     */
    function getDeploymentAddresses(
        address           poolDelegate_,
        address           poolManagerFactory_,
        address           withdrawalManagerFactory_,
        address[]  memory loanManagerFactories_,
        address           asset_,
        string     memory name_,
        string     memory symbol_,
        uint256[6] memory configParams_
    )
        external view
        returns (
            address          poolManager_,
            address          pool_,
            address          poolDelegateCover_,
            address          withdrawalManager_,
            address[] memory loanManagers_
        );

    function globals() external view returns (address globals_);

}