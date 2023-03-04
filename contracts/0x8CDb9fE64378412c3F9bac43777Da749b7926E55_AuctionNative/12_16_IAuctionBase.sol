// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

import "../../buyNow/base/IBuyNowBase.sol";
import "./ISignableStructsAuction.sol";

/**
 * @title Interface for a base Escrow Contract for Payments, that adds
 * an Auction mode to an inherited contract that implements the BuyNow mode.
 * @author Freeverse.io, www.freeverse.io
 * @dev The contract that implements this interface inherits the payment process 
 * required to conduct BuyNows, and extends it with Auctioning capabilities,
 * adding new entry points to start Auctions via bid methods, and reusing all the
 * State Machine, refund and withdraw methods of BuyNows after an auction finishes. 
 *
 * The contract that implements this interface can be inherited to conduct
 * auctions/buyNows in either native crypto or ERC20 tokens.

 * Buyers/bidders explicitly sign the agreement to let the specified Operator address
 * act as an Oracle, responsible for signing the success or failure of the asset transfer,
 * which is conducted outside this contract upon reception of funds in a Buynow, or
 * completion of an Auction.
 *
 * If no confirmation is received from the Operator during the PaymentWindow,
 * all funds received from the buyer/bidder are made available to him/her for refund.
 * Throughout the contract, this moment is labeled as 'expirationTime'.
 *
 * To start an auction, signatures of both the buyer and the Operator are required, and they
 * are checked in the contracts that inherit from this one. 
 *
 * The variable 'uint256 paymentId' is used to uniquely identify the started process, regardless
 * of whether it is a BuyNow or an Auction.
 *
 * The contract that implements this interface maintains the balances of all users,
 * which can be withdrawn via explicit calls to the various 'withdraw' methods.
 * If a buyer/bidder has a non-zero local balance at the moment of executing buyNow/bid,
 * the contract reuses it, and only requires the provision of the
 * remainder funds required (if any).
 *
 * Auctions start with an initial bid, and an initial 'endsAt' time,
 * and are characterized by: {minIncreasePercentage, timeToExtend, extendableUntil}.
 * - New bids need to provide and increase of at least minIncreasePercentage;
 * - 'Late bids', defined as those that arrive during the time window [endsAt - timeToExtend, endsAt],
 *   increment endsAt by an amount equal to timeToExtend, with max accumulated extension capped by extendableUntil.
 *
 * Each payment has the following State Machine:
 * - NOT_STARTED -> ASSET_TRANSFERRING, triggered by buyNow
 * - NOT_STARTED -> AUCTIONING, triggered by bid
 * - AUCTIONING -> AUCTIONING, triggered by successive bids
 * - AUCTIONING -> ASSET_TRANSFERRING, triggered when block.timestamp > endsAt;
 *   in this case, this transition is an implicit one, reflected by the change in the return
 *   state of the paymentState method.
 * - ASSET_TRANSFERRING -> PAID, triggered by relaying assetTransferSuccess signed by Operator
 * - ASSET_TRANSFERRING -> REFUNDED, triggered by relaying assetTransferFailed signed by Operator
 * - ASSET_TRANSFERRING -> REFUNDED, triggered by a refund request after expirationTime
 *
 * NOTE: To ensure that the every process proceeds as expected when the payment starts,
 * the following configuration data is stored uniquely for every payment when it is created,
 * remaining unmodified regardless of any possible changes to the contract's storage defaults:
 * - In BuyNow payments: {operator, feesCollector, expirationTime}
 * - In Auctions: {operator, feesCollector, expirationTime, minIncreasePercentage, timeToExtend, extendableUntil}
 *
 * NOTE: The contract allows a feature, 'Seller Registration', that can be used in the scenario that
 * applications want users to prove that they have enough crypto know-how (obtain native crypto,
 * pay for gas using a web3 wallet, etc.) to interact by themselves with this smart contract before selling,
 * so that they are less likely to require technical help in case they need to withdraw funds.
 * - If _isSellerRegistrationRequired = true, this feature is enabled, and payments can only be initiated
 *    if the payment seller has previously executed the registerAsSeller method.
 * - If _isSellerRegistrationRequired = false, this feature is disabled, and payments can be initiated
 *    regardless of any previous call to the registerAsSeller method.
 *
 * NOTE: Following previous audits suggestions, the EIP712 contract, which uses OpenZeppelin's implementation,
 * is not inherited; it is separately deployed, so that it can be upgraded should the standard evolve in the future.
 *
 */

interface IAuctionBase is IBuyNowBase, ISignableStructsAuction {
    /**
     * @dev Event emitted on change of the default auction configuration settings.
     * @param minIncreasePercentage The minimum % amount that a new bid needs to increase
     *  above the previous highest bid, expressed as a percentage in Basis Points (BPS).
     *  e.g.: minIncreasePercentage = 500 requires new bids to be 5% larger.
     * @param timeToExtend If a bid arrives during the time window [endsAt - timeToExtend, endsAt],
     *  then endsAt is increased by timeToExtend.
     * @param extendableBy The maximum value that endsAt can be increased in an auction
     *  as a result of accumulated late-arriving bids.
     * @param prevMinIncreasePercentage The previous value of minIncreasePercentage
     * @param prevTimeToExtend The previous value of timeToExtend
     * @param prevExtendableBy The previous value of extendableBy
     */
    event DefaultAuctionConfig(
        uint256 minIncreasePercentage,
        uint256 timeToExtend,
        uint256 extendableBy,
        uint256 prevMinIncreasePercentage,
        uint256 prevTimeToExtend,
        uint256 prevExtendableBy
    );

    /**
     * @dev Event emitted on change of the auction configuration settings of a specific universe.
     *  Note that the previous values emitted correspond to the previous values of the struct
     *  storing the universe config params; not the params queried by the method universeAuctionConfig,
     *  which resorts to the default config if the specific universe config is not set. 
     *  This is to avoid events depending on internal logic, and just keeping track of stored state changes.  
     * @param universeId The id of the universe
     * @param minIncreasePercentage The minimum amount that a new bid needs to increase
     *  above the previous highest bid, expressed as a percentage in Basis Points (BPS).
     *  e.g.: minIncreasePercentage = 500 requires new bids to be 5% larger.
     * @param timeToExtend If a bid arrives during the time window [endsAt - timeToExtend, endsAt],
     *  then endsAt is increased by timeToExtend.
     * @param extendableBy The maximum value that endsAt can be increased in an auction
     *  as a result of accumulated late-arriving bids.
     * @param prevMinIncreasePercentage The previous value of minIncreasePercentage
     * @param prevTimeToExtend The previous value of timeToExtend
     * @param prevExtendableBy The previous value of extendableBy
    */
    event UniverseAuctionConfig(
        uint256 indexed universeId,
        uint256 minIncreasePercentage,
        uint256 timeToExtend,
        uint256 extendableBy,
        uint256 prevMinIncreasePercentage,
        uint256 prevTimeToExtend,
        uint256 prevExtendableBy
    );

    /**
     * @dev Event emitted on removal of a specific universe Auction Config,
     *  so that the default Auction Config is used from now on.
     * @param universeId The id of the universe
     */
    event RemovedUniverseAuctionConfig(uint256 indexed universeId);

    /**
     * @dev Event emitted when a Bid arrives and is correctly validated
     * @param paymentId The unique id identifying the payment
     * @param bidder The address of the bidder providing the funds
     * @param seller The address of the seller of the asset
     * @param bidAmount The funds provided with the bid
     * @param endsAt The time at which the auction ends if no late bids arrive
     */
    event Bid(
        bytes32 indexed paymentId,
        address indexed bidder,
        address indexed seller,
        uint256 bidAmount,
        uint256 endsAt
    );

    /**
     * @notice Struct containing auction parameters that will be used by new incoming bids.
     * @param minIncreasePercentage The minimum amount that a new bid needs to increase
     *  above the previous highest bid, expressed as a percentage in Basis Points (BPS).
     *  e.g.: minIncreasePercentage = 500 requires new bids to be 5% larger.
     * @param timeToExtend If a bid arrives during the time window [endsAt - timeToExtend, endsAt],
     *  then endsAt is increased by timeToExtend.
     * @param extendableBy The maximum value that endsAt can be increased in an auction
     *  as a result of accumulated late-arriving bids.
     */
    struct AuctionConfig {
        uint256 minIncreasePercentage;
        uint256 timeToExtend;
        uint256 extendableBy;
    }

    /**
     * @notice Struct containing config parameters describing already existing Auctions
     * @dev When an auction is created, and an instance of this struct is stored,
     *  all fields of the struct remain non-modifiable except for 'endsAt'.
     * @param endsAt The time at which the auction ends if no late bids arrive
     * @param minIncreasePercentage The minimum amount that a new bid needs to increase
     *  above the previous highest bid, expressed as a percentage in Basis Points (BPS).
     *  e.g.: minIncreasePercentage = 500 requires new bids to be 5% larger.
     * @param timeToExtend If a bid arrives during the time window [endsAt - timeToExtend, endsAt],
     *  then endsAt is increased by timeToExtend.
     * @param extendableUntil The maximum value that endsAt can achieve in an auction
     *  as a result of accumulated late-arriving bids.
     */
    struct ExistingAuction {
        uint256 endsAt;
        uint256 minIncreasePercentage;
        uint256 timeToExtend;
        uint256 extendableUntil;
    }

    /**
     * @notice Sets the default auction configuration settings
     * @param minIncreasePercentage The minimum amount that a new bid needs to increase
     *  above the previous highest bid, expressed as a percentage in Basis Points (BPS).
     *  e.g.: minIncreasePercentage = 500 requires new bids to be 5% larger.
     * @param timeToExtend If a bid arrives during the time window [endsAt - timeToExtend, endsAt],
     *  then endsAt is increased by timeToExtend.
     * @param extendableBy The maximum value that endsAt can be increased in an auction
     *  as a result of accumulated late-arriving bids.
     */
    function setDefaultAuctionConfig(
        uint256 minIncreasePercentage,
        uint256 timeToExtend,
        uint256 extendableBy
    ) external;

    /**
     * @notice Sets the auction configuration settings specific to one universe
     * @param universeId The id of the universe
     * @param minIncreasePercentage The minimum amount that a new bid needs to increase
     *  above the previous highest bid, expressed as a percentage in Basis Points (BPS).
     *  e.g.: minIncreasePercentage = 500 requires new bids to be 5% larger.
     * @param timeToExtend the value such that, if a bid arrives during the
     *  time window [endsAt - timeToExtend, endsAt], then endsAt is increased by timeToExtend.
     * @param extendableBy The maximum value that endsAt can be increased in an auction
     *  as a result of accumulated late-arriving bids.
     */
    function setUniverseAuctionConfig(
        uint256 universeId,
        uint256 minIncreasePercentage,
        uint256 timeToExtend,
        uint256 extendableBy
    ) external;

    /**
     * @notice Removes the auction configuration settings specific to one universe,
     *  so that, from now on, this universe uses the default configuration.
     * @param universeId The id of the universe
     */
    function removeUniverseAuctionConfig(uint256 universeId) external;

    /**
     * @notice Splits the funds required to provide the bidAmount specified in a bid into two sources:
     *  - externalFunds: the funds required to be transferred from the external bidder balance
     *  - localFunds: the funds required from the bidder's already available balance in this contract.
     *  If new bidder coincides with previous max bidder, only the difference between
     *  the two bidAmounts is required.
     * @param bidInput The struct containing all required bid data
     * @return externalFunds The funds required to be transferred from the external bidder balance
     * @return localFunds The amount of local funds that will be used.
     * @return isSameBidder A bool which is true if the bidder coincides with the previous max bidder of the auction.
     */
    function splitAuctionFundingSources(BidInput memory bidInput)
        external
        view
        returns (
            uint256 externalFunds,
            uint256 localFunds,
            bool isSameBidder
        );

    /**
     * @notice Reverts unless the requirements for a BidInput are fulfilled.
     * @param bidInput The struct containing all required bid data
     * @return state The current state of the auction
     */
    function assertBidInputsOK(BidInput calldata bidInput)
        external
        view
        returns (State state);

    /**
     * @notice Returns the minimum bidAmount required for a new arriving bid,
     *  having minIncreasePercentage into account.
     * @param paymentId The unique ID that identifies the payment.
     * @return the minimum bidAmount of a new arriving bid
     */
    function minNewBidAmount(bytes32 paymentId) external view returns (uint256);

    /**
     * @notice Returns the state of a payment.
     * @dev Overrides the method in the BuyNow contract to account for
     *  possibly on-going Auctions.
     *  It returns the explicit state stored unless:
     *  - it is in AUCTIONING state &&
     *  - the current time is beyond the auction ending time,
     *  in wich case the auction is finished, and it returns ASSET_TRANSFERING.
     *  If payment is in ASSET_TRANSFERRING, it may be worth
     *  checking acceptsRefunds to check to it has gone beyond expirationTime.
     * @param paymentId The unique ID that identifies the payment.
     * @return the state of the payment.
     */
    function paymentState(bytes32 paymentId)
        external
        view
        override
        returns (State);

    /**
     * @notice The minimum percentage that a new bid needs to increase
     *  above the previous highest bid, for the specified universe
     * @dev It returns the default value unless the universe has a specific auction config
     * @param universeId The id of the universe
     * @return minIncreasePercentage The minimum percentage that a new bid needs to increase
     *  above the previous highest bid, expressed as a percentage in Basis Points (BPS).
     *  e.g.: minIncreasePercentage = 500 requires new bids to be 5% larger.
     */
    function universeMinIncreasePercentage(uint256 universeId)
        external
        view
        returns (uint256);

    /**
     * @notice Returns the value such that, if a bid arrives during the
     *  time window [endsAt - timeToExtend, endsAt], then endsAt is increased by timeToExtend,
     *  for the specified universe.
     * @dev It returns the default value unless the universe has a specific auction config
     * @param universeId The id of the universe
     * @return the value such that, if a bid arrives during the
     *  time window [endsAt - timeToExtend, endsAt], then endsAt is increased by timeToExtend.
     */
    function universeTimeToExtend(uint256 universeId) external view returns (uint256);

    /**
     * @notice Returns the maximum value that endsAt can be increased in an auction
     *  as a result of accumulated late-arriving bids, for the specified universe.
     * @dev It returns the default value unless the universe has a specific auction config
     * @param universeId The id of the universe
     * @return The maximum value that endsAt can be increased in an auction
     *  as a result of accumulated late-arriving bids for the specified universe
     */
    function universeExtendableBy(uint256 universeId) external view returns (uint256);

    /**
     * @notice Returns the default auction configuration settings struct
     * @return the default auction configuration settings struct.
     */
    function defaultAuctionConfig()
        external
        view
        returns (AuctionConfig memory);

    /**
     * @notice Returns the auction configuration settings of a specific universe.
     * @param universeId The id of the universe
     * @return the struct containing the auction configuration settings of the specified universe.
     */
    function universeAuctionConfig(uint256 universeId)
        external
        view
        returns (AuctionConfig memory);

    /**
     * @notice Returns the stored auction data of an existing auction
     * @param paymentId The unique id identifying the payment
     * @return the struct containing the auction configuration settings of the specified paymentId.
     */
    function existingAuction(bytes32 paymentId)
        external
        view
        returns (ExistingAuction memory);
}