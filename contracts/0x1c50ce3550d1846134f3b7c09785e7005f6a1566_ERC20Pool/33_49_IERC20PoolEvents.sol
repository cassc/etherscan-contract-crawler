// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title ERC20 Pool Events
 */
interface IERC20PoolEvents {

    /**
     *  @notice Emitted when actor adds claimable collateral to a bucket.
     *  @param  actor     Recipient that added collateral.
     *  @param  index     Index at which collateral were added.
     *  @param  amount    Amount of collateral added to the pool (`WAD` precision).
     *  @param  lpAwarded Amount of `LP` awarded for the deposit (`WAD` precision).
     */
    event AddCollateral(
        address indexed actor,
        uint256 indexed index,
        uint256 amount,
        uint256 lpAwarded
    );

    /**
     *  @notice Emitted when borrower draws debt from the pool, or adds collateral to the pool.
     *  @param  borrower          The borrower to whom collateral was pledged, and/or debt was drawn for.
     *  @param  amountBorrowed    Amount of quote tokens borrowed from the pool (`WAD` precision).
     *  @param  collateralPledged Amount of collateral locked in the pool (`WAD` precision).
     *  @param  lup               `LUP` after borrow.
     */
    event DrawDebt(
        address indexed borrower,
        uint256 amountBorrowed,
        uint256 collateralPledged,
        uint256 lup
    );
}