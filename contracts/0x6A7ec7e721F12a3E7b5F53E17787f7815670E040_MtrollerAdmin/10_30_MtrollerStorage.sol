pragma solidity ^0.5.16;

import "./PriceOracle.sol";
import "./MTokenInterfaces.sol";
import "./MTokenStorage.sol";
import "./ErrorReporter.sol";
import "./compound/ExponentialNoError.sol";

contract MtrollerV1Storage is MDelegateeStorage, MtrollerErrorReporter, ExponentialNoError {

    /*** Global variables: addresses of other contracts to call. 
     *   These are set at contract initialization and can only be modified by a (timelock) admin
    ***/

    /**
     * @notice Address of the mmo token contract (this never changes again after initialization)
     */
    address mmoTokenAddress;

    /**
     * @notice Oracle which gives the price of any given asset
     */
    PriceOracle public oracle;


    /*** Global variables: protocol control parameters. 
     *   These variables are set at contract initialization and can only be modified by a (timelock) admin
    ***/

    /**
     * @notice Multiplier used to calculate the maximum repayAmount when liquidating a borrow
     */
    uint internal constant closeFactorMinMantissa = 0.05e18; // 0.05 (lower limit)
    uint internal constant closeFactorMaxMantissa = 1.0e18; // 1.0 (upper limit)
    uint public closeFactorMantissa;

    /**
     * @notice Multiplier representing the discount on collateral that a liquidator receives
     */
    uint internal constant liquidationIncentiveMinMantissa = 1.0e18; // 1.0 (lower limit = no incentive)
    uint internal constant liquidationIncentiveMaxMantissa = 2.0e18; // 2.0 (upper limit = 50% discount)
    uint public liquidationIncentiveMantissa;

    /**
     * @notice Max number of assets a single account can participate in (borrow or use as collateral).
     * This value is set at initialization and can only be modified by admin.
     */
    uint public maxAssets;

    /**
     * @notice The borrowCapGuardian can set borrowCaps to any number for any market. Lowering the borrow 
     * cap could disable borrowing on the given market.
     */
    address public borrowCapGuardian;

    /**
     * @notice The Pause Guardian can pause certain actions as a safety mechanism.
     *  Actions which allow users to remove their own assets cannot be paused.
     *  Liquidation / seizing / transfer can only be paused globally, not by market.
     */
    address public pauseGuardian;


    /*** mToken variables: general token-specific parameters and permissions. 
     *   These variables are initialized the first time the given mToken is minted and then adapted when needed
    ***/

    /**
     * @notice Per-account mapping of "mToken assets you are in", length of array capped by maxAssets
     */
    mapping(address => uint240[]) public accountAssets;

    /// Structure for per-token metadata. TODO: Move these to individual mappings (no struct anymore)
    struct Market {
        /// @notice Whether or not this mToken market is listed, i.e. allowed to interact with the mtroller
        bool _isListed;

        /**
         * @notice Multiplier representing the most one can borrow against their collateral in this mToken market.
         *  For instance, 0.9e18 to allow borrowing 90% of collateral value.
         *  Must be between 0 and 1e18 (stored as a mantissa, i.e., scaled by 1e18)
         */
        uint _collateralFactorMantissa;

        /// @notice Mapping of "accounts in this asset", per mToken market.
        mapping(address => bool) _accountMembership;
    }

    /// @notice No collateralFactorMantissa may exceed this value
    uint internal constant collateralFactorMaxMantissa = 0.9e18; // 0.9
    
    /**
     * @notice Official mapping of mTokens -> Market metadata
     * @dev Used e.g. to determine if a market is supported. Do not access variables directly but use getter 
     *  functions _isListed(), _collateralFactorMantissa(), etc
     */
    mapping(uint240 => Market) public markets;


    /*** mToken variables: per-token variables to control (emergency) pausing of certain functions. 
     *   These variables are inactive by default and only set by admin if needed
    ***/
    mapping(uint240 => bool) public auctionGuardianPaused;
    mapping(uint240 => bool) public mintGuardianPaused;
    mapping(uint240 => bool) public borrowGuardianPaused;
    mapping(uint240 => bool) public transferGuardianPaused;
    mapping(uint240 => bool) public seizeGuardianPaused;

    // @notice Borrow caps enforced by borrowAllowed for each mToken address. Defaults to zero which corresponds to unlimited borrowing.
    mapping(uint240 => uint) public borrowCaps;


    /*** mToken variables: list of all markets (for book-keeping by the mtroller). 
     * Only the anchor tokens are registered (when the admin calls _supportMarket() for that anchor token).
     * All other mTokens used (ever minted) can be retrieved from their contract using the respective anchor token.
    ***/
    /// @notice A list of all markets
    mapping (uint => uint240) public allMarkets;
    mapping (uint240 => uint) public allMarketsIndex;
    uint public allMarketsSize;


    /*** MMO platform token variables: not really used so far
    ***/

    /// @notice The rate at which the flywheel distributes MMO to mToken markets, per block. 
    /// Only admin can set that. TODO: better use only with anchor mToken!
    mapping(uint240 => uint) public mmoSpeeds;

    struct MmoMarketState {
        /// @notice The market's last updated mmoBorrowIndex or mmoSupplyIndex
        uint224 index;

        /// @notice The block number the index was last updated at
        uint32 block;
    }

    /// @notice The MMO market supply state for each market
    mapping(uint240 => MmoMarketState) public mmoSupplyState;

    /// @notice The MMO market borrow state for each market
    mapping(uint240 => MmoMarketState) public mmoBorrowState;

    /// @notice The MMO borrow index for each market for each supplier as of the last time they accrued MMO
    mapping(uint240 => mapping(address => uint)) public mmoSupplierIndex;

    /// @notice The MMO borrow index for each market for each borrower as of the last time they accrued MMO
    mapping(uint240 => mapping(address => uint)) public mmoBorrowerIndex;

    /// @notice The MMO accrued but not yet transferred to each user
    mapping(address => uint) public mmoAccrued;

    /// @notice The portion of MMO that each contributor receives per block
    mapping(address => uint) public mmoContributorSpeeds;

    /// @notice Last block at which a contributor's MMO rewards have been allocated
    mapping(address => uint) public lastContributorBlock;

    /// @notice The initial MMO index for a market
    uint224 public constant mmoInitialIndex = 1e36;
}