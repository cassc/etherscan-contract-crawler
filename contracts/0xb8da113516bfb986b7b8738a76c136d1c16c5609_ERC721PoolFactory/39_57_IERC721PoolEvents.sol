// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title ERC721 Pool Events
 */
interface IERC721PoolEvents {

    /**
     *  @notice Emitted when actor adds claimable collateral to a bucket.
     *  @param  actor     Recipient that added collateral.
     *  @param  index     Index at which collateral were added.
     *  @param  tokenIds  Array of tokenIds to be added to the pool.
     *  @param  lpAwarded Amount of LP awarded for the deposit (`WAD` precision).
     */
    event AddCollateralNFT(
        address indexed actor,
        uint256 indexed index,
        uint256[] tokenIds,
        uint256   lpAwarded
    );

    /**
     *  @notice Emitted when actor adds claimable collateral to a bucket.
     *  @param  actor            Recipient that added collateral.
     *  @param  collateralMerged Amount of collateral merged (`WAD` precision).
     *  @param  toIndexLps       If non-zero, amount of LP in toIndex when collateral is merged into bucket (`WAD` precision). If 0, no collateral is merged.
     */
    event MergeOrRemoveCollateralNFT(
        address indexed actor,
        uint256 collateralMerged,
        uint256 toIndexLps
    );

    /**
     *  @notice Emitted when borrower draws debt from the pool or adds collateral to the pool.
     *  @param  borrower          `msg.sender`.
     *  @param  amountBorrowed    Amount of quote tokens borrowed from the pool (`WAD` precision).
     *  @param  tokenIdsPledged   Array of tokenIds to be added to the pool.
     *  @param  lup               LUP after borrow.
     */
    event DrawDebtNFT(
        address indexed borrower,
        uint256   amountBorrowed,
        uint256[] tokenIdsPledged,
        uint256   lup
    );
}