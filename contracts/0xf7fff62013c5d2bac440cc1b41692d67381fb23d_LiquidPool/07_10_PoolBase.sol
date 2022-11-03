// SPDX-License-Identifier: WISE

pragma solidity =0.8.17;

// Interfaces
import "./ILiquidRouter.sol";

interface IERC20 {

    /**
     * @dev ERC20 interface to get decimals of pool token for pool creation
    */
    function decimals()
        external
        returns (uint8);
}

interface IFactory {

    /**
     * @dev allows to get the address of the router during initialise call
    */
    function routerAddress()
        external
        view
        returns (address);
}

contract PoolBase {

    // Router Instance
    ILiquidRouter ROUTER;

    // Routes all calls
    address public ROUTER_ADDRESS;

    // ERC20 for loans
    address public poolToken;

    // Pool token decimals
    uint8 public poolTokenDecimals;

    // Address of fee destination
    address public feeDestinationAddress;

    // ChainLink feed address
    address public chainLinkETH;

    // ChainLink token feed address
    address public chainLinkFeedAddress;

    // Maximal factor every NFT can be collateralised in this pool
    uint256 public maxCollateralFactor;

    // Current usage of the pool. 1E18 <=> 100 %
    uint256 public utilisationRate;

    // Current actual number of token inside the contract
    uint256 public totalPool;

    // Current borrow rate of the pool;
    uint256 public borrowRate;

    // Current mean Markov value of the pool;
    uint256 public markovMean;

    // Bad debt amount in terms of poolToken correct decimals
    uint256 public badDebt;

    // This bool checks if the feeDestinationAddress should not be updatable anymore
    bool public permanentFeeDestination;

    // Tokens currently held by contract + all tokens out on loans
    uint256 public pseudoTotalTokensHeld;

    // Tokens currently being used in loans
    uint256 public totalTokensDue;

    // Shares representing tokens owed on a loan
    uint256 public totalBorrowShares;

    // Shares representing deposits that are not tokenised
    uint256 public totalInternalShares;

    // Borrow rates variables
    // ----------------------

    // Pool position of borrow rate functions (divergent at x = r) 1E18 <=> 1 and r > 1E18.
    uint256 public pole;

    // Value for single step
    uint256 public deltaPole;

    // Global minimum value for the pole
    uint256 public minPole;

    // Global maximum value for the pole
    uint256 public maxPole;

    // Individual multiplication factor scaling the y-axes (static after deployment of pool)
    uint256 public multiplicativeFactor;

    // Tracks the last interaction with the pool
    uint256 public timeStampLastInteraction;

    // Scaling algorithm variables
    // --------------------------

    // Tracks the pole which corresponds to maxPoolShares
    uint256 public bestPole;

    // Tracks the maximal value of shares the pool has ever reached
    uint256 public maxPoolShares;

    // Tracks the previous shares value during algorithm last round execution
    uint256 public previousValue;

    // Tracks time when scaling algorithm has been triggered last time
    uint256 public timeStampLastAlgorithm;

    // Switch for stepping directions
    bool public increasePole;

    // Global constants
    // ---------------

    uint8 constant DECIMALS_ETH = 18;
    uint256 constant THREE_HOURS = 3 hours;

    // (1% <=> 1E16)
    uint256 constant FIFTY_PERCENT = 50E16;

    uint256 constant PRECISION_FACTOR_E18 = 1E18;
    uint256 constant PRECISION_FACTOR_E36 = 1E18 * 1E18;
    uint256 constant ONE_YEAR_PRECISION_E18 = 52 weeks * 1E18;

    uint256 constant ONE_HUNDRED = 100;
    uint256 constant SECONDS_IN_DAY = 86400;
    address constant EMPTY_ADDRESS = address(0x0);

    // Earning fee
    uint256 public fee;

    // Value determing weight of new value in markov chain (1% <=> 1E16)
    uint256 constant MARKOV_FRACTION = 2E16;

    // Absolute max value for borrow rate (1% <=> 1E16)
    uint256 constant UPPER_BOUND_MAX_RATE = 150E16;

    // Lower max value for borrow rate (1% <=> 1E16)
    uint256 constant LOWER_BOUND_MAX_RATE = 30E16;

    // Timeframe for normalisation
    uint256 constant NORMALISATION_FACTOR = 8 weeks;

    // Threshold for reverting stepping direction
    uint256 constant THRESHOLD_SWITCH_DIRECTION = 90;

    // Threshold for resetting pole
    uint256 constant THRESHOLD_RESET_POLE = 75;

    // Expecting user to payback the loan in 35 days
    uint256 constant public TIME_BETWEEN_PAYMENTS = 35 days;

    // Auction reaches minimum after 42 hours
    uint256 constant public AUCTION_TIMEFRAME = 42 hours;

    // Relates minimum time of auction to lastPaidTime
    uint256 constant public MAX_AUCTION_TIMEFRAME = TIME_BETWEEN_PAYMENTS + AUCTION_TIMEFRAME;

    struct Loan {
        uint48 lastPaidTime;
        address tokenOwner;
        uint256 borrowShares;
        uint256 principalTokens;
    }

    // Storing known collections
    mapping(address => bool) public nftAddresses;

    // Keeping internal shares of each user
    mapping(address => uint256) public internalShares;

    // NFT address => tokenID => loan data
    mapping(address => mapping(uint256 => Loan)) public currentLoans;

    // Base functions

    /**
     * @dev Helper function to add specified value to pseudoTotalTokensHeld
     */
    function _increasePseudoTotalTokens(
        uint256 _amount
    )
        internal
    {
        pseudoTotalTokensHeld =
        pseudoTotalTokensHeld + _amount;
    }

    /**
     * @dev Helper function to subtract specified value from pseudoTotalTokensHeld
     */
    function _decreasePseudoTotalTokens(
        uint256 _amount
    )
        internal
    {
        pseudoTotalTokensHeld =
        pseudoTotalTokensHeld - _amount;
    }

    /**
     * @dev Helper function to add specified value to totalPool
     */
    function _increaseTotalPool(
        uint256 _amount
    )
        internal
    {
        totalPool =
        totalPool + _amount;
    }

    /**
     * @dev Helper function to subtract specified value from totalPool
     */
    function _decreaseTotalPool(
        uint256 _amount
    )
        internal
    {
        totalPool =
        totalPool - _amount;
    }

    /**
     * @dev Helper function to add specified value to totalInternalShares
     */
    function _increaseTotalInternalShares(
        uint256 _amount
    )
        internal
    {
        totalInternalShares =
        totalInternalShares + _amount;
    }

    /**
     * @dev Helper function to subtract specified value from totalInternalShares
     */
    function _decreaseTotalInternalShares(
        uint256 _amount
    )
        internal
    {
        totalInternalShares =
        totalInternalShares - _amount;
    }

    /**
     * @dev Helper function to add value to a specific users internal shares
     */
    function _increaseInternalShares(
        uint256 _amount,
        address _user
    )
        internal
    {
        internalShares[_user] =
        internalShares[_user] + _amount;
    }

    /**
     * @dev Helper function to subtract value a specific users internal shares
     */
    function _decreaseInternalShares(
        uint256 _amount,
        address _user
    )
        internal
    {
        internalShares[_user] =
        internalShares[_user] - _amount;
    }

    /**
     * @dev Helper function to add specified value to totalBorrowShares
     */
    function _increaseTotalBorrowShares(
        uint256 _amount
    )
        internal
    {
        totalBorrowShares =
        totalBorrowShares + _amount;
    }

    /**
     * @dev Helper function to subtract specified value from totalBorrowShares
     */
    function _decreaseTotalBorrowShares(
        uint256 _amount
    )
        internal
    {
        totalBorrowShares =
        totalBorrowShares - _amount;
    }

    /**
     * @dev Helper function to add specified value to totalTokensDue
     */
    function _increaseTotalTokensDue(
        uint256 _amount
    )
        internal
    {
        totalTokensDue =
        totalTokensDue + _amount;
    }

    /**
     * @dev Helper function to subtract specified value from totalTokensDue
     */
    function _decreaseTotalTokensDue(
        uint256 _amount
    )
        internal
    {
        totalTokensDue =
        totalTokensDue - _amount;
    }

    /**
     * @dev Helper function to increase bad debt
     */
    function _increaseBadDebt(
        uint256 _amount
    )
        internal
    {
        badDebt =
        badDebt + _amount;
    }

    /**
     * @dev Helper function to decrease bad debt
     */
    function _decreaseBadDebt(
        uint256 _amount
    )
        internal
    {
        badDebt =
        badDebt - _amount;
    }

    /**
     * @dev helping UI display principal Amount of loan
     */
    function getPrincipalAmount(
        address _nftAddress,
        uint256 _nftTokenId
    )
        public
        view
        returns (uint256)
    {
        return currentLoans[_nftAddress][_nftTokenId].principalTokens;
    }

    /**
    * @dev displays current borrowshares of a loan
    */
    function getCurrentBorrowShares(
        address _nftAddress,
        uint256 _nftTokenId
    )
        public
        view
        returns (uint256)
    {
        return currentLoans[_nftAddress][_nftTokenId].borrowShares;
    }

    /**
     * @dev function for helping router emit events with lessgas cost
     */
    function getLoanOwner(
        address _nftAddress,
        uint256 _nftTokenId
    )
        public
        view
        returns (address)
    {
        return currentLoans[_nftAddress][_nftTokenId].tokenOwner;
    }

    /**
     * @dev displays last payment time of a loan
     */
    function getLastPaidTime(
        address _nftAddress,
        uint256 _nftTokenId
    )
        public
        view
        returns (uint256)
    {
        return currentLoans[_nftAddress][_nftTokenId].lastPaidTime;
    }

    /**
     * @dev displays next payment time of a loan
     */
    function getNextPaymentDueTime(
        address _nftAddress,
        uint256 _nftTokenId
    )
        public
        view
        returns (uint256)
    {
        return getLastPaidTime(
            _nftAddress,
            _nftTokenId
        ) + TIME_BETWEEN_PAYMENTS;
    }

    /**
     * @dev function for deleting a loan inside the mapping
     */
    function _deleteLoanData(
        address _nftAddress,
        uint256 _nftTokenId
    )
        internal
    {
        delete currentLoans[_nftAddress][_nftTokenId];
    }
}
