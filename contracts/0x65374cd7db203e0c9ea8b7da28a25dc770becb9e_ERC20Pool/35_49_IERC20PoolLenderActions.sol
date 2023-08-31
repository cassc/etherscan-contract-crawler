// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title ERC20 Pool Lender Actions
 */
interface IERC20PoolLenderActions {

    /**
     *  @notice Deposit claimable collateral into a specified bucket.
     *  @param  amountToAdd_ Amount of collateral to deposit (`WAD` precision).
     *  @param  index_       The bucket index to which collateral will be deposited.
     *  @param  expiry_      Timestamp after which this transaction will revert, preventing inclusion in a block with unfavorable price.
     *  @return bucketLP_    The amount of `LP` awarded for the added collateral (`WAD` precision).
     */
    function addCollateral(
        uint256 amountToAdd_,
        uint256 index_,
        uint256 expiry_
    ) external returns (uint256 bucketLP_);
}