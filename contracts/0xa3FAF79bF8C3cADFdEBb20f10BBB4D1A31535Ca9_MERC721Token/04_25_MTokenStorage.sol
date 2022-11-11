pragma solidity ^0.5.16;

import "./MtrollerInterface.sol";
import "./TokenAuction.sol";
import "./compound/InterestRateModel.sol";

contract MDelegateeStorage {
    /**
    * @notice List of all public function selectors implemented by "admin type" contract
    * @dev Needs to be initialized in the constructor(s)
    */
    bytes4[] public implementedSelectors;

    function implementedSelectorsLength() public view returns (uint) {
        return implementedSelectors.length;
    }
}

contract MTokenV1Storage is MDelegateeStorage {

    /**
     * @dev Guard variable for re-entrancy checks
     */
    bool internal _notEntered;
    bool internal _notEntered2;


    /*** Global variables: addresses of other contracts to call. 
     *   These are set at contract initialization and can only be modified by a (timelock) admin
    ***/

    /**
     * @notice Address of the underlying asset contract (this never changes again after initialization)
     */
    address public underlyingContract;

    /**
     * @notice Contract address of model which tells what the current interest rate(s) should be
     */
    InterestRateModel public interestRateModel;

    /**
     * @notice Contract used for (non-fungible) mToken auction (used only if applicable)
     */ 
    TokenAuction public tokenAuction;

    /**
     * @notice Contract which oversees inter-mToken operations
     */
    MtrollerInterface public mtroller;


    /*** Global variables: token identification constants. 
     *   These variables are set at contract initialization and never modified again
    ***/

    /**
     * @notice EIP-20 token name for this token
     */
    string public mName;

    /**
     * @notice EIP-20 token symbol for this token
     */
    string public mSymbol;

    /**
     * @notice EIP-20 token decimals for this token
     */
    uint8 public mDecimals;


    /*** Global variables: protocol control parameters. 
     *   These variables are set at contract initialization and can only be modified by a (timelock) admin
    ***/

    /**
     * @notice Initial exchange rate used when minting the first mTokens (used when totalSupply = 0)
     */
    uint internal initialExchangeRateMantissa;

    /**
     * @notice Fraction of interest currently set aside for reserves
     */
    uint internal constant reserveFactorMaxMantissa = 50e16; // upper protocol limit (50%)
    uint public reserveFactorMantissa;

    /**
     * @notice Fraction of seized (fungible) collateral that is added to reserves
     */
    uint internal constant protocolSeizeShareMaxMantissa = 5e16; // upper protocol limit (5%)
    uint public protocolSeizeShareMantissa;

    /**
     * @notice Fraction of new borrow amount set aside for reserves (one-time fee)
     */
    uint internal constant borrowFeeMaxMantissa = 50e16; // upper protocol limit (50%)
    uint public borrowFeeMantissa;

    /**
     * @notice Mapping of addresses that are whitelisted as receiver for flash loans
     */
    mapping (address => bool) public flashReceiverIsWhitelisted;


    /*** Global variables: auction liquidation control parameters. 
     *   The variables are set at contract initialization and can only be changed by a (timelock) admin
    ***/

    /**
     * @notice Minimum and maximum values that can ever be used for the grace period, which is
     * the minimum time liquidators have to wait before they can seize a non-fungible mToken collateral
     */ 
    uint256 public constant auctionMinGracePeriod = 2000; // lower limit (2000 blocks, i.e. about 8 hours)
    uint256 public constant auctionMaxGracePeriod = 50000; // upper limit (50000 blocks, i.e. about 8.5 days)
    uint256 public auctionGracePeriod;

    /**
     * @notice "Headstart" time in blocks the preferredLiquidator has available to liquidate a mToken
     * exclusively before everybody else is also allowed to do it.
     */
    uint256 public constant preferredLiquidatorMaxHeadstart = 2000; // upper limit (2000 blocks, i.e. about 8 hours)
    uint256 public preferredLiquidatorHeadstart;

    /**
     * @notice Minimum offer required to win liquidation auction, relative to the NFTs regular price.
     */
    uint public constant minimumOfferMaxMantissa = 80e16; // upper limit (80% of market price)
    uint public minimumOfferMantissa;

    /**
     * @notice Fee for the liquidator executing liquidateToPaymentToken().
     */
    uint public constant liquidatorAuctionFeeMaxMantissa = 10e16; // upper limit (10%)
    uint public liquidatorAuctionFeeMantissa;

    /**
     * @notice Fee for the protocol when executing liquidateToPaymentToken() or acceptHighestOffer().
     * The funds are directly added to mEther reserves.
     */
    uint public constant protocolAuctionFeeMaxMantissa = 20e16; // upper limit (50%)
    uint public protocolAuctionFeeMantissa;


    /*** Token variables: basic token identification. 
     *   These variables are only initialized the first time the given token is minted
    ***/

    /**
     * @notice Mapping of mToken to underlying tokenID
     */
    mapping (uint240 => uint256) public underlyingIDs;

    /**
     * @notice Mapping of underlying tokenID to mToken
     */
    mapping (uint256 => uint240) public mTokenFromUnderlying;

    /**
     * @notice Total number of (ever) minted mTokens. Note: Burning a mToken (when redeeming the 
     * underlying asset) DOES NOT reduce this count. The maximum possible amount of tokens that 
     * can ever be minted by this contract is limited to 2^88-1, which is finite but high enough 
     * to never be reached in realistic time spans.
     */
    uint256 public totalCreatedMarkets;

    /**
     * @notice Maps mToken to block number that interest was last accrued at
     */
    mapping (uint240 => uint) public accrualBlockNumber;

    /**
     * @notice Maps mToken to accumulator of the total earned interest rate since the opening of that market
     */
    mapping (uint240 => uint) public borrowIndex;


    /*** Token variables: general token accounting. 
     *   These variables are initialized the first time the given token is minted and then adapted when needed
    ***/

    /**
     * @notice Official record of token balances for each mToken, for each account
     */
    mapping (uint240 => mapping (address => uint)) internal accountTokens;

    /**
     * @notice Container for borrow balance information
     * @member principal Total balance (with accrued interest), after applying the most recent balance-changing action
     * @member interestIndex Global borrowIndex as of the most recent balance-changing action
     */
    struct BorrowSnapshot {
        uint principal;
        uint interestIndex;
    }

    /**
     * @notice Mapping of account addresses to outstanding borrow balances, for any given mToken
     */
    mapping(uint240 => mapping(address => BorrowSnapshot)) internal accountBorrows;

    /**
     * @notice Maximum borrow rate that can ever be applied (.0005% / block)
     */
    uint internal constant borrowRateMaxMantissa = 0.0005e16;

    /**
     * @notice Maps mToken to total amount of cash of the underlying in that market
     */
    mapping (uint240 => uint) public totalCashUnderlying;

    /**
     * @notice Maps mToken to total amount of outstanding borrows of the underlying in that market
     */
    mapping (uint240 => uint) public totalBorrows;

    /**
     * @notice Maps mToken to total amount of reserves of the underlying held in that market
     */
    mapping (uint240 => uint) public totalReserves;

    /**
     * @notice Maps mToken to total number of tokens in circulation in that market
     */
    mapping (uint240 => uint) public totalSupply;


    /*** Token variables: Special variables used for fungible tokens (e.g. ERC-20). 
     *   These variables are initialized the first time the given token is minted and then adapted when needed
    ***/

    /**
     * @notice Dummy ID for "underlying asset" in case of a (single) fungible token
     */
    uint256 internal constant dummyTokenID = 1;

    /**
     * @notice The mToken for a (single) fungible token
     */
    uint240 public thisFungibleMToken;

    /**
     * @notice Approved token transfer amounts on behalf of others (for fungible tokens)
     */
    mapping (address => mapping (address => uint)) internal transferAllowances;


    /*** Token variables: Special variables used for non-fungible tokens (e.g. ERC-721). 
     *   These variables are initialized the first time the given token is minted and then adapted when needed
    ***/

    /**
     * @notice Virtual amount of "cash" that corresponds to one underlying NFT. This is used as 
     * calculatory units internally for mTokens with strictly non-fungible underlying (such as ERC-721) 
     * to avoid loss of mathematical precision for calculations such as borrowing amounts. However, both 
     * underlying NFT and associated mToken are still non-fungible (ERC-721 compliant) tokens and can 
     * only be transferred as one item.
     */
    uint internal constant oneUnit = 1e18;

    /**
     * @notice Mapping of mToken to the block number of the last block in their grace period (zero
     * if mToken is not in a grace period)
     */
    mapping (uint240 => uint256) public lastBlockGracePeriod;

    /**
     * @notice Mapping of mToken to the address that has "fist mover" rights to do the liquidation
     * for the mToken (because that address first called startGracePeriod())
     */
    mapping (uint240 => address) public preferredLiquidator;

    /**
     * @notice Asking price that can be set by a mToken's current owner. At or above this price the mToken
     * will be instantly sold. Set to zero to disable.
     */
    mapping (uint240 => uint256) public askingPrice;
}