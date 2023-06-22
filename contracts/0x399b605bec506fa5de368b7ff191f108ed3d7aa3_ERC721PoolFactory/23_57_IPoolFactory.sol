// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 *  @title Pool Factory Interface.
 *  @dev   Used to deploy both funigible and non fungible pools.
 */
interface IPoolFactory {

    /**************/
    /*** Errors ***/
    /**************/
    /**
     *  @notice Can't deploy if quote and collateral are the same token.
     */
    error DeployQuoteCollateralSameToken();

    /**
     *  @notice Can't deploy with one of the args pointing to the `0x` address.
     */
    error DeployWithZeroAddress();

    /**
     *  @notice Can't deploy with token that has no decimals method or decimals greater than 18
     */
    error DecimalsNotCompliant();

    /**
     *  @notice Pool with this combination of quote and collateral already exists.
     *  @param  pool_ The address of deployed pool.
     */
    error PoolAlreadyExists(address pool_);

    /**
     *  @notice Pool starting interest rate is invalid.
     */
    error PoolInterestRateInvalid();

    /**************/
    /*** Events ***/
    /**************/

    /**
     *  @notice Emitted when a new pool is created.
     *  @param  pool_ The address of the new pool.
     */
    event PoolCreated(address pool_);
}