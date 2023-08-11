// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

import {
    IERC721Token,
    IPoolErrors,
    IPoolLenderActions,
    IPoolKickerActions,
    IPoolTakerActions,
    IPoolSettlerActions
}                           from './interfaces/pool/IPool.sol';
import {
    DrawDebtResult,
    RepayDebtResult,
    SettleParams,
    SettleResult,
    TakeResult
}                           from './interfaces/pool/commons/IPoolInternals.sol';
import { PoolState }        from './interfaces/pool/commons/IPoolState.sol';

import {
    IERC721Pool,
    IERC721PoolBorrowerActions,
    IERC721PoolImmutables,
    IERC721PoolLenderActions
}                               from './interfaces/pool/erc721/IERC721Pool.sol';
import { IERC721Taker }         from './interfaces/pool/erc721/IERC721Taker.sol';
import { IERC721PoolState }     from './interfaces/pool/erc721/IERC721PoolState.sol';

import { FlashloanablePool } from './base/FlashloanablePool.sol';
import { _roundToScale }     from './libraries/helpers/PoolHelper.sol';

import {
    _revertIfAuctionClearable,
    _revertAfterExpiry
}                               from './libraries/helpers/RevertsHelper.sol';

import { Maths }    from './libraries/internal/Maths.sol';
import { Deposits } from './libraries/internal/Deposits.sol';
import { Loans }    from './libraries/internal/Loans.sol';

import { LenderActions }   from './libraries/external/LenderActions.sol';
import { BorrowerActions } from './libraries/external/BorrowerActions.sol';
import { SettlerActions }  from './libraries/external/SettlerActions.sol';
import { TakerActions }    from './libraries/external/TakerActions.sol';

/**
 *  @title  ERC721 Pool contract
 *  @notice Entrypoint of `ERC721` Pool actions for pool actors:
 *          - `Lenders`: add, remove and move quote tokens; transfer `LP`
 *          - `Borrowers`: draw and repay debt
 *          - `Traders`: add, remove and move quote tokens; add and remove collateral
 *          - `Kickers`: auction undercollateralized loans; settle auctions; claim bond rewards
 *          - `Bidders`: take auctioned collateral
 *          - `Reserve purchasers`: start auctions; take reserves
 *          - `Flash borrowers`: initiate flash loans on ERC20 quote tokens
 *  @dev    Contract is `FlashloanablePool` with flashloan logic.
 *  @dev    Contract is base `Pool` with logic to handle `ERC721` collateral.
 *  @dev    Calls logic from external `PoolCommons`, `LenderActions`, `BorrowerActions` and `Auction` actions libraries.
 */
contract ERC721Pool is FlashloanablePool, IERC721Pool {

    /*****************/
    /*** Constants ***/
    /*****************/

    /// @dev Immutable NFT subset pool arg offset.
    uint256 internal constant SUBSET = 93;

    /***********************/
    /*** State Variables ***/
    /***********************/

    /// @dev Borrower `address => array` of tokenIds pledged by borrower mapping.
    mapping(address => uint256[]) public borrowerTokenIds;
    /// @dev Array of `tokenIds` in pool buckets (claimable from pool).
    uint256[]                     public bucketTokenIds;

    /// @dev Mapping of `tokenIds` allowed in `NFT` Subset type pool.
    mapping(uint256 => bool)      internal tokenIdsAllowed_;

    /****************************/
    /*** Initialize Functions ***/
    /****************************/

    /// @inheritdoc IERC721Pool
    function initialize(
        uint256[] memory tokenIds_,
        uint256 rate_
    ) external override {
        if (isPoolInitialized) revert AlreadyInitialized();

        inflatorState.inflator       = uint208(1e18);
        inflatorState.inflatorUpdate = uint48(block.timestamp);

        interestState.interestRate       = uint208(rate_);
        interestState.interestRateUpdate = uint48(block.timestamp);

        uint256 noOfTokens = tokenIds_.length;

        if (noOfTokens != 0) {
            // add subset of tokenIds allowed in the pool
            for (uint256 id = 0; id < noOfTokens;) {
                tokenIdsAllowed_[tokenIds_[id]] = true;

                unchecked { ++id; }
            }
        }

        Loans.init(loans);

        // increment initializations count to ensure these values can't be updated
        isPoolInitialized = true;
    }

    /******************/
    /*** Immutables ***/
    /******************/

    /// @inheritdoc IERC721PoolImmutables
    function isSubset() external pure override returns (bool) {
        return _getArgUint256(SUBSET) != 0;
    }

    /***********************************/
    /*** Borrower External Functions ***/
    /***********************************/

    function tokenIdsAllowed(uint256 tokenId_) public view returns (bool) {
        return (_getArgUint256(SUBSET) == 0 || tokenIdsAllowed_[tokenId_]);
    }

    /**
     *  @inheritdoc IERC721PoolBorrowerActions
     *  @dev    === Write state ===
     *  @dev    - decrement `poolBalances.t0DebtInAuction` accumulator
     *  @dev    - increment `poolBalances.pledgedCollateral` accumulator
     *  @dev    - increment `poolBalances.t0Debt` accumulator
     *  @dev    - update `t0Debt2ToCollateral` ratio only if loan not in auction, debt and collateral pre action are considered 0 if auction settled
     *  @dev    - update `borrowerTokenIds` and `bucketTokenIds` arrays
     *  @dev    === Emit events ===
     *  @dev    - `DrawDebtNFT`
     */
    function drawDebt(
        address borrowerAddress_,
        uint256 amountToBorrow_,
        uint256 limitIndex_,
        uint256[] calldata tokenIdsToPledge_
    ) external nonReentrant {
        PoolState memory poolState = _accruePoolInterest();

        // ensure the borrower is not charged for additional debt that they did not receive
        amountToBorrow_ = _roundToScale(amountToBorrow_, poolState.quoteTokenScale);

        DrawDebtResult memory result = BorrowerActions.drawDebt(
            auctions,
            buckets,
            deposits,
            loans,
            poolState,
            _availableQuoteToken(),
            borrowerAddress_,
            amountToBorrow_,
            limitIndex_,
            Maths.wad(tokenIdsToPledge_.length)
        );

        emit DrawDebtNFT(borrowerAddress_, amountToBorrow_, tokenIdsToPledge_, result.newLup);

        // update in memory pool state struct
        poolState.debt       = result.poolDebt;
        poolState.t0Debt     = result.t0PoolDebt;
        poolState.collateral = result.poolCollateral;

        // update t0 debt in auction in memory pool state struct and pool balances state
        if (result.t0DebtInAuctionChange != 0) {
            poolState.t0DebtInAuction    -= result.t0DebtInAuctionChange;
            poolBalances.t0DebtInAuction = poolState.t0DebtInAuction;
        }

        // adjust t0Debt2ToCollateral ratio if loan not in auction
        if (!result.inAuction) {
            _updateT0Debt2ToCollateral(
                result.settledAuction ? 0 : result.debtPreAction,       // debt pre settle (for loan in auction) not taken into account
                result.debtPostAction,
                result.settledAuction ? 0 : result.collateralPreAction, // collateral pre settle (for loan in auction) not taken into account
                result.collateralPostAction
            );
        }

        // update pool interest rate state
        _updateInterestState(poolState, result.newLup);

        if (tokenIdsToPledge_.length != 0) {
            // update pool balances pledged collateral state
            poolBalances.pledgedCollateral = poolState.collateral;

            // move collateral from sender to pool
            _transferFromSenderToPool(borrowerTokenIds[borrowerAddress_], tokenIdsToPledge_);
        }

        if (result.settledAuction) _rebalanceTokens(borrowerAddress_, result.remainingCollateral);

        // move borrowed amount from pool to sender
        if (amountToBorrow_ != 0) {
            // update pool balances t0 debt state
            poolBalances.t0Debt = poolState.t0Debt;

            // move borrowed amount from pool to sender
            _transferQuoteToken(msg.sender, amountToBorrow_);
        }
    }

    /**
     *  @inheritdoc IERC721PoolBorrowerActions
     *  @dev    === Write state ===
     *  @dev    - decrement `poolBalances.t0Debt accumulator`
     *  @dev    - decrement `poolBalances.t0DebtInAuction accumulator`
     *  @dev    - decrement `poolBalances.pledgedCollateral accumulator`
     *  @dev    - update `t0Debt2ToCollateral` ratio only if loan not in auction, debt and collateral pre action are considered 0 if auction settled
     *  @dev    - update `borrowerTokenIds` and `bucketTokenIds` arrays
     *  @dev    === Emit events ===
     *  @dev    - `RepayDebt`
     */
    function repayDebt(
        address borrowerAddress_,
        uint256 maxQuoteTokenAmountToRepay_,
        uint256 noOfNFTsToPull_,
        address collateralReceiver_,
        uint256 limitIndex_
    ) external nonReentrant {
        PoolState memory poolState = _accruePoolInterest();

        // ensure accounting is performed using the appropriate token scale
        if (maxQuoteTokenAmountToRepay_ != type(uint256).max)
            maxQuoteTokenAmountToRepay_ = _roundToScale(maxQuoteTokenAmountToRepay_, poolState.quoteTokenScale);

        RepayDebtResult memory result = BorrowerActions.repayDebt(
            auctions,
            buckets,
            deposits,
            loans,
            poolState,
            borrowerAddress_,
            maxQuoteTokenAmountToRepay_,
            Maths.wad(noOfNFTsToPull_),
            limitIndex_
        );

        emit RepayDebt(borrowerAddress_, result.quoteTokenToRepay, noOfNFTsToPull_, result.newLup);

        // update in memory pool state struct
        poolState.debt       = result.poolDebt;
        poolState.t0Debt     = result.t0PoolDebt;
        poolState.collateral = result.poolCollateral;

        // update t0 debt in auction in memory pool state struct and pool balances state
        if (result.t0DebtInAuctionChange != 0) {
            poolState.t0DebtInAuction -= result.t0DebtInAuctionChange;
            poolBalances.t0DebtInAuction = poolState.t0DebtInAuction;
        }

        if (result.settledAuction) _rebalanceTokens(borrowerAddress_, result.remainingCollateral);

        // adjust t0Debt2ToCollateral ratio if loan not in auction
        if (!result.inAuction) {
            _updateT0Debt2ToCollateral(
                result.settledAuction ? 0 : result.debtPreAction,       // debt pre settle (for loan in auction) not taken into account
                result.debtPostAction,
                result.settledAuction ? 0 : result.collateralPreAction, // collateral pre settle (for loan in auction) not taken into account
                result.collateralPostAction
            );
        }

        // update pool interest rate state
        _updateInterestState(poolState, result.newLup);

        // update pool balances pledged collateral state
        poolBalances.pledgedCollateral = poolState.collateral;

        if (result.quoteTokenToRepay != 0) {
            // update pool balances t0 debt state
            poolBalances.t0Debt = poolState.t0Debt;

            // move amount to repay from sender to pool
            _transferQuoteTokenFrom(msg.sender, result.quoteTokenToRepay);
        }
        if (noOfNFTsToPull_ != 0) {
            // move collateral from pool to address specified as collateral receiver
            _transferFromPoolToAddress(collateralReceiver_, borrowerTokenIds[msg.sender], noOfNFTsToPull_);
        }
    }

    /*********************************/
    /*** Lender External Functions ***/
    /*********************************/

    /**
     *  @inheritdoc IERC721PoolLenderActions
     *  @dev    === Write state ===
     *  @dev    - update `bucketTokenIds` arrays
     *  @dev    === Emit events ===
     *  @dev    - `AddCollateralNFT`
     */
    function addCollateral(
        uint256[] calldata tokenIds_,
        uint256 index_,
        uint256 expiry_
    ) external override nonReentrant returns (uint256 bucketLP_) {
        _revertAfterExpiry(expiry_);
        PoolState memory poolState = _accruePoolInterest();

        bucketLP_ = LenderActions.addCollateral(
            buckets,
            deposits,
            Maths.wad(tokenIds_.length),
            index_
        );

        emit AddCollateralNFT(msg.sender, index_, tokenIds_, bucketLP_);

        // update pool interest rate state
        _updateInterestState(poolState, Deposits.getLup(deposits, poolState.debt));

        // move required collateral from sender to pool
        _transferFromSenderToPool(bucketTokenIds, tokenIds_);
    }

    /**
     *  @inheritdoc IERC721PoolLenderActions
     *  @dev    === Write state ===
     *  @dev    - update `bucketTokenIds` arrays
     *  @dev    === Emit events ===
     *  @dev    - `MergeOrRemoveCollateralNFT`
     */
    function mergeOrRemoveCollateral(
        uint256[] calldata removalIndexes_,
        uint256 noOfNFTsToRemove_,
        uint256 toIndex_
    ) external override nonReentrant returns (uint256 collateralMerged_, uint256 bucketLP_) {
        _revertIfAuctionClearable(auctions, loans);

        PoolState memory poolState = _accruePoolInterest();
        uint256 collateralAmount = Maths.wad(noOfNFTsToRemove_);

        (
            collateralMerged_,
            bucketLP_
        ) = LenderActions.mergeOrRemoveCollateral(
            buckets,
            deposits,
            removalIndexes_,
            collateralAmount,
            toIndex_
        );

        emit MergeOrRemoveCollateralNFT(msg.sender, collateralMerged_, bucketLP_);

        // update pool interest rate state
        _updateInterestState(poolState, Deposits.getLup(deposits, poolState.debt));

        if (collateralMerged_ == collateralAmount) {
            // Total collateral in buckets meets the requested removal amount, noOfNFTsToRemove_
            _transferFromPoolToAddress(msg.sender, bucketTokenIds, noOfNFTsToRemove_);
        }

    }

    /**
     *  @inheritdoc IPoolLenderActions
     *  @dev    === Write state ===
     *  @dev    - update `bucketTokenIds` arrays
     *  @dev    === Emit events ===
     *  @dev    - `RemoveCollateral`
     *  @param noOfNFTsToRemove_ Number of `NFT` tokens to remove.
     */
    function removeCollateral(
        uint256 noOfNFTsToRemove_,
        uint256 index_
    ) external override nonReentrant returns (uint256 removedAmount_, uint256 redeemedLP_) {
        _revertIfAuctionClearable(auctions, loans);

        PoolState memory poolState = _accruePoolInterest();

        removedAmount_ = Maths.wad(noOfNFTsToRemove_);
        redeemedLP_ = LenderActions.removeCollateral(
            buckets,
            deposits,
            removedAmount_,
            index_
        );

        emit RemoveCollateral(msg.sender, index_, noOfNFTsToRemove_, redeemedLP_);

        // update pool interest rate state
        _updateInterestState(poolState, Deposits.getLup(deposits, poolState.debt));

        _transferFromPoolToAddress(msg.sender, bucketTokenIds, noOfNFTsToRemove_);
    }

    /*******************************/
    /*** Pool Auctions Functions ***/
    /*******************************/

    /**
     *  @inheritdoc IPoolSettlerActions
     *  @dev    === Write state ===
     *  @dev    - decrement `poolBalances.t0Debt` accumulator
     *  @dev    - decrement `poolBalances.t0DebtInAuction` accumulator
     *  @dev    - decrement `poolBalances.pledgedCollateral` accumulator
     *  @dev    - no update of `t0Debt2ToCollateral` ratio as debt and collateral pre settle are not taken into account (pre debt and pre collateral = 0)
     */
    function settle(
        address borrowerAddress_,
        uint256 maxDepth_
    ) external nonReentrant override {
        PoolState memory poolState = _accruePoolInterest();

        SettleParams memory params = SettleParams({
            borrower:    borrowerAddress_,
            poolBalance: _getNormalizedPoolQuoteTokenBalance(),
            bucketDepth: maxDepth_
        });

        SettleResult memory result = SettlerActions.settlePoolDebt(
            auctions,
            buckets,
            deposits,
            loans,
            reserveAuction,
            poolState,
            params
        );

        _updatePostSettleState(result, poolState);

        // move token ids from borrower array to pool claimable array if any collateral used to settle bad debt
        _rebalanceTokens(params.borrower, result.collateralRemaining);
    }

    /**
     *  @inheritdoc IPoolTakerActions
     *  @dev    === Write state ===
     *  @dev    - decrement `poolBalances.t0Debt` accumulator
     *  @dev    - decrement `poolBalances.t0DebtInAuction` accumulator
     *  @dev    - decrement `poolBalances.pledgedCollateral` accumulator
     *  @dev    - update `t0Debt2ToCollateral` ratio only if auction settled, debt and collateral pre action are considered 0
     */
    function take(
        address        borrowerAddress_,
        uint256        collateral_,
        address        callee_,
        bytes calldata data_
    ) external override nonReentrant {
        PoolState memory poolState = _accruePoolInterest();

        TakeResult memory result = TakerActions.take(
            auctions,
            buckets,
            deposits,
            loans,
            poolState,
            borrowerAddress_,
            Maths.wad(collateral_),
            1
        );

        _updatePostTakeState(result, poolState);

        // transfer rounded collateral from pool to taker
        uint256[] memory tokensTaken = _transferFromPoolToAddress(
            callee_,
            borrowerTokenIds[borrowerAddress_],
            result.collateralAmount / 1e18
        );

        uint256 totalQuoteTokenAmount = result.quoteTokenAmount + result.excessQuoteToken;

        if (data_.length != 0) {
            IERC721Taker(callee_).atomicSwapCallback(
                tokensTaken,
                totalQuoteTokenAmount  / poolState.quoteTokenScale,
                data_
            );
        }

        // move borrower token ids to bucket claimable token ids after taking / reducing borrower collateral
        _rebalanceTokens(borrowerAddress_, result.remainingCollateral);

        // transfer from taker to pool the amount of quote tokens needed to cover collateral auctioned (including excess for rounded collateral)
        _transferQuoteTokenFrom(msg.sender, totalQuoteTokenAmount);

        // transfer from pool to borrower the excess of quote tokens after rounding collateral auctioned
        if (result.excessQuoteToken != 0) _transferQuoteToken(borrowerAddress_, result.excessQuoteToken);
    }

    /**
     *  @inheritdoc IPoolTakerActions
     *  @dev    === Write state ===
     *  @dev    - decrement `poolBalances.t0Debt` accumulator
     *  @dev    - decrement `poolBalances.t0DebtInAuction` accumulator
     *  @dev    - decrement `poolBalances.pledgedCollateral` accumulator
     *  @dev    - update `t0Debt2ToCollateral` ratio only if auction settled, debt and collateral pre action are considered 0
     */
    function bucketTake(
        address borrowerAddress_,
        bool    depositTake_,
        uint256 index_
    ) external override nonReentrant {

        PoolState memory poolState = _accruePoolInterest();

        TakeResult memory result = TakerActions.bucketTake(
            auctions,
            buckets,
            deposits,
            loans,
            poolState,
            borrowerAddress_,
            depositTake_,
            index_,
            1
        );

        _updatePostTakeState(result, poolState);

        // move borrower token ids to bucket claimable token ids after taking / reducing borrower collateral
        _rebalanceTokens(borrowerAddress_, result.remainingCollateral);
    }

    /**************************/
    /*** Internal Functions ***/
    /**************************/

    /**
     *  @notice Rebalance `NFT` token and transfer difference to floor collateral from borrower to pool claimable array.
     *  @dev    === Write state ===
     *  @dev    - update `borrowerTokens` and `bucketTokenIds` arrays
     *  @param  borrowerAddress_    Address of borrower.
     *  @param  borrowerCollateral_ Current borrower collateral to be rebalanced.
     */
    function _rebalanceTokens(
        address borrowerAddress_,
        uint256 borrowerCollateral_
    ) internal {
        // rebalance borrower's collateral, transfer difference to floor collateral from borrower to pool claimable array
        uint256[] storage borrowerTokens = borrowerTokenIds[borrowerAddress_];

        uint256 noOfTokensPledged    = borrowerTokens.length;
        /*
            eg1. borrowerCollateral_ = 4.1, noOfTokensPledged = 6; noOfTokensToTransfer = 1
            eg2. borrowerCollateral_ = 4, noOfTokensPledged = 6; noOfTokensToTransfer = 2
        */
        uint256 borrowerCollateralRoundedUp = (borrowerCollateral_ + 1e18 - 1) / 1e18;
        uint256 noOfTokensToTransfer = noOfTokensPledged - borrowerCollateralRoundedUp;

        for (uint256 i = 0; i < noOfTokensToTransfer;) {
            uint256 tokenId = borrowerTokens[--noOfTokensPledged]; // start with moving the last token pledged by borrower
            borrowerTokens.pop();                                  // remove token id from borrower
            bucketTokenIds.push(tokenId);                          // add token id to pool claimable tokens

            unchecked { ++i; }
        }
    }

    /**
     *  @notice Helper function for transferring multiple `NFT` tokens from msg.sender to pool.
     *  @dev    Reverts in case token id is not supported by subset pool.
     *  @param  poolTokens_ Array in pool that tracks `NFT` ids (could be tracking `NFT`s pledged by borrower or `NFT`s added by a lender in a specific bucket).
     *  @param  tokenIds_   Array of `NFT` token ids to transfer from `msg.sender` to pool.
     */
    function _transferFromSenderToPool(
        uint256[] storage poolTokens_,
        uint256[] calldata tokenIds_
    ) internal {
        for (uint256 i = 0; i < tokenIds_.length;) {
            uint256 tokenId = tokenIds_[i];
            if (!tokenIdsAllowed(tokenId)) revert OnlySubset();
            poolTokens_.push(tokenId);

            _transferNFT(msg.sender, address(this), tokenId);

            unchecked { ++i; }
        }
    }

    /**
     *  @notice Helper function for transferring multiple `NFT` tokens from pool to given address.
     *  @dev    It transfers `NFT`s from the most recent one added into the pool (pop from array tracking `NFT`s in pool).
     *  @param  toAddress_      Address where pool should transfer tokens to.
     *  @param  poolTokens_     Array in pool that tracks `NFT` ids (could be tracking `NFT`s pledged by borrower or `NFT`s added by a lender in a specific bucket).
     *  @param  amountToRemove_ Number of `NFT` tokens to transfer from pool to given address.
     *  @return Array containing token ids that were transferred from pool to address.
     */
    function _transferFromPoolToAddress(
        address toAddress_,
        uint256[] storage poolTokens_,
        uint256 amountToRemove_
    ) internal returns (uint256[] memory) {
        uint256[] memory tokensTransferred = new uint256[](amountToRemove_);

        uint256 noOfNFTsInPool = poolTokens_.length;

        for (uint256 i = 0; i < amountToRemove_;) {
            uint256 tokenId = poolTokens_[--noOfNFTsInPool]; // start with transferring the last token added in bucket
            poolTokens_.pop();

            _transferNFT(address(this), toAddress_, tokenId);

            tokensTransferred[i] = tokenId;

            unchecked { ++i; }
        }

        return tokensTransferred;
    }

    /**
     *  @notice Helper function to transfer an `NFT` from owner to target address (reused in code to reduce contract deployment bytecode size).
     *  @dev    Since `transferFrom` is used instead of `safeTransferFrom`, calling smart contracts must be careful to check that they support any received `NFT`s.
     *  @param  from_    `NFT` owner address.
     *  @param  to_      New `NFT` owner address.
     *  @param  tokenId_ `NFT` token id to be transferred.
     */
    function _transferNFT(address from_, address to_, uint256 tokenId_) internal {
        // slither-disable-next-line calls-loop
        IERC721Token(_getArgAddress(COLLATERAL_ADDRESS)).transferFrom(from_, to_, tokenId_);
    }

    /*******************************/
    /*** External View Functions ***/
    /*******************************/

    /// @inheritdoc IERC721PoolState
    function totalBorrowerTokens(address borrower_) external view override returns(uint256) {
        return borrowerTokenIds[borrower_].length;
    }

    /// @inheritdoc IERC721PoolState
    function totalBucketTokens() external view override returns(uint256) {
        return bucketTokenIds.length;
    }

}