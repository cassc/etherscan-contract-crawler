// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title Pool Taker Actions
 */
interface IPoolTakerActions {

    /**
     *  @notice Called by actors to use quote token to arb higher-priced deposit off the book.
     *  @param  borrowerAddress_  Address of the borower take is being called upon.
     *  @param  depositTake_      If `true` then the take will happen at an auction price equal with bucket price. Auction price is used otherwise.
     *  @param  index_            Index of a bucket, likely the `HPB`, in which collateral will be deposited.
     */
    function bucketTake(
        address borrowerAddress_,
        bool    depositTake_,
        uint256 index_
    ) external;

    /**
     *  @notice Called by actors to purchase collateral from the auction in exchange for quote token.
     *  @param  borrowerAddress_  Address of the borower take is being called upon.
     *  @param  maxAmount_        Max amount of collateral that will be taken from the auction (`WAD` precision for `ERC20` pools, max number of `NFT`s for `ERC721` pools).
     *  @param  callee_           Identifies where collateral should be sent and where quote token should be obtained.
     *  @param  data_             If provided, take will assume the callee implements `IERC*Taker`.  Take will send collateral to 
     *                            callee before passing this data to `IERC*Taker.atomicSwapCallback`.  If not provided, 
     *                            the callback function will not be invoked.
     */
    function take(
        address        borrowerAddress_,
        uint256        maxAmount_,
        address        callee_,
        bytes calldata data_
    ) external;

    /***********************/
    /*** Reserve Auction ***/
    /***********************/

    /**
     *  @notice Purchases claimable reserves during a `CRA` using `Ajna` token.
     *  @param  maxAmount_ Maximum amount of quote token to purchase at the current auction price (`WAD` precision).
     *  @return amount_    Actual amount of reserves taken (`WAD` precision).
     */
    function takeReserves(
        uint256 maxAmount_
    ) external returns (uint256 amount_);

}