// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

interface IPoolManagerStorage {

    /**
     *  @dev    Returns whether or not a pool is active.
     *  @return active_ True if the pool is active.
     */
    function active() external view returns (bool active_);

    /**
     *  @dev    Gets the address of the funds asset.
     *  @return asset_ The address of the funds asset.
     */
    function asset() external view returns (address asset_);

    /**
     *  @dev    Returns whether or not a pool is configured.
     *  @return configured_ True if the pool is configured.
     */
    function configured() external view returns (bool configured_);

    /**
     *  @dev    Gets the delegate management fee rate.
     *  @return delegateManagementFeeRate_ The value for the delegate management fee rate.
     */
    function delegateManagementFeeRate() external view returns (uint256 delegateManagementFeeRate_);

    /**
     *  @dev    Returns whether or not the given address is a loan manager.
     *  @param  loan_          The address of the loan.
     *  @return isLoanManager_ True if the address is a loan manager.
     */
    function isLoanManager(address loan_) external view returns (bool isLoanManager_);

    /**
     *  @dev    Returns whether or not the given address is a valid lender.
     *  @param  lender_        The address of the lender.
     *  @return isValidLender_ True if the address is a valid lender.
     */
    function isValidLender(address lender_) external view returns (bool isValidLender_);

    /**
     *  @dev    Gets the liquidity cap for the pool.
     *  @return liquidityCap_ The liquidity cap for the pool.
     */
    function liquidityCap() external view returns (uint256 liquidityCap_);

    /**
     *  @dev    Gets the address of the loan manager in the list.
     *  @param  index_       The index to get the address of.
     *  @return loanManager_ The address in the list.
     */
    function loanManagerList(uint256 index_) external view returns (address loanManager_);

    /**
     *  @dev    Returns whether or not a pool is open to public deposits.
     *  @return openToPublic_ True if the pool is open to public deposits.
     */
    function openToPublic() external view returns (bool openToPublic_);

    /**
     *  @dev    Gets the address of the pending pool delegate.
     *  @return pendingPoolDelegate_ The address of the pending pool delegate.
     */
    function pendingPoolDelegate() external view returns (address pendingPoolDelegate_);

    /**
     *  @dev    Gets the address of the pool.
     *  @return pool_ The address of the pool.
     */
    function pool() external view returns (address pool_);

    /**
     *  @dev    Gets the address of the pool delegate.
     *  @return poolDelegate_ The address of the pool delegate.
     */
    function poolDelegate() external view returns (address poolDelegate_);

    /**
     *  @dev    Gets the address of the pool delegate cover.
     *  @return poolDelegateCover_ The address of the pool delegate cover.
     */
    function poolDelegateCover() external view returns (address poolDelegateCover_);

    /**
     *  @dev    Gets the address of the withdrawal manager.
     *  @return withdrawalManager_ The address of the withdrawal manager.
     */
    function withdrawalManager() external view returns (address withdrawalManager_);

}