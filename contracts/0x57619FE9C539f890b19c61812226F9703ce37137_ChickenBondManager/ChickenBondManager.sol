/**
 *Submitted for verification at Etherscan.io on 2022-10-04
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BaseMath {
    uint constant public DECIMAL_PRECISION = 1e18;
}

// taken from: https://github.com/liquity/dev/blob/8371355b2f11bee9fa599f9223f4c2f6f429351f/packages/contracts/contracts/Dependencies/LiquityMath.sol
contract ChickenMath is BaseMath {

    /*
     * Multiply two decimal numbers and use normal rounding rules:
     * -round product up if 19'th mantissa digit >= 5
     * -round product down if 19'th mantissa digit < 5
     *
     * Used only inside the exponentiation, decPow().
     */
    function decMul(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x * y + DECIMAL_PRECISION / 2) / DECIMAL_PRECISION;
    }

    /*
     * decPow: Exponentiation function for 18-digit decimal base, and integer exponent n.
     *
     * Uses the efficient "exponentiation by squaring" algorithm. O(log(n)) complexity.
     *
     * Called by ChickenBondManager.calcRedemptionFeePercentage, that represents time in units of minutes:
     *
     * The exponent is capped to avoid reverting due to overflow. The cap 525600000 equals
     * "minutes in 1000 years": 60 * 24 * 365 * 1000
     *
     * If a period of > 1000 years is ever used as an exponent in either of the above functions, the result will be
     * negligibly different from just passing the cap, since:
     * the decayed base rate will be 0 for 1000 years or > 1000 years
     */
    function decPow(uint256 _base, uint256 _exponent) internal pure returns (uint) {

        if (_exponent > 525600000) {_exponent = 525600000;}  // cap to avoid overflow

        if (_exponent == 0) {return DECIMAL_PRECISION;}

        uint256 y = DECIMAL_PRECISION;
        uint256 x = _base;
        uint256 n = _exponent;

        // Exponentiation-by-squaring
        while (n > 1) {
            if (n % 2 != 0) {
                y = decMul(x, y);
            }
            x = decMul(x, x);
            n = n / 2;
        }

        return decMul(x, y);
    }
}

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

interface ILUSDToken is IERC20 { 
    
    // --- Events ---

    event TroveManagerAddressChanged(address _troveManagerAddress);
    event StabilityPoolAddressChanged(address _newStabilityPoolAddress);
    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event LUSDTokenBalanceUpdated(address _user, uint _amount);

    // --- Functions ---

    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;

    function sendToPool(address _sender,  address poolAddress, uint256 _amount) external;

    function returnFromPool(address poolAddress, address user, uint256 _amount ) external;

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface IBLUSDToken is IERC20 {
    function mint(address _to, uint256 _bLUSDAmount) external;

    function burn(address _from, uint256 _bLUSDAmount) external;
}

interface ICurvePool is IERC20 { 
    function add_liquidity(uint256[2] memory _amounts, uint256 _min_mint_amount) external returns (uint256 mint_amount);

    function remove_liquidity(uint256 burn_amount, uint256[2] memory _min_amounts) external;

    function remove_liquidity_one_coin(uint256 _burn_amount, int128 i, uint256 _min_received) external;

    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy, address _receiver) external returns (uint256);

    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy, address _receiver) external returns (uint256);

    function calc_withdraw_one_coin(uint256 _burn_amount, int128 i) external view returns (uint256);

    function calc_token_amount(uint256[2] memory _amounts, bool _is_deposit) external view returns (uint256);

    function balances(uint256 arg0) external view returns (uint256);

    function token() external view returns (address);

    function totalSupply() external view returns (uint256);

    function get_dy(int128 i,int128 j, uint256 dx) external view returns (uint256);

    function get_dy_underlying(int128 i,int128 j, uint256 dx) external view returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function fee() external view returns (uint256);

    function D() external returns (uint256);

    function future_A_gamma_time() external returns (uint256);
}

interface IYearnVault is IERC20 { 
    function deposit(uint256 _tokenAmount) external returns (uint256);

    function withdraw(uint256 _tokenAmount) external returns (uint256);

    function lastReport() external view returns (uint256);

    function totalDebt() external view returns (uint256);

    function calcTokenToYToken(uint256 _tokenAmount) external pure returns (uint256); 

    function token() external view returns (address);

    function availableDepositLimit() external view returns (uint256);

    function pricePerShare() external view returns (uint256);

    function name() external view returns (string memory);

    function setDepositLimit(uint256 limit) external;

    function withdrawalQueue(uint256) external returns (address);
}

interface IBAMM {
    function deposit(uint256 lusdAmount) external;

    function withdraw(uint256 lusdAmount, address to) external;

    function swap(uint lusdAmount, uint minEthReturn, address payable dest) external returns(uint);

    function getSwapEthAmount(uint lusdQty) external view returns(uint ethAmount, uint feeLusdAmount);

    function getLUSDValue() external view returns (uint256, uint256, uint256);

    function setChicken(address _chicken) external;
}

interface IChickenBondManager {
    // Valid values for `status` returned by `getBondData()`
    enum BondStatus {
        nonExistent,
        active,
        chickenedOut,
        chickenedIn
    }

    function lusdToken() external view returns (ILUSDToken);
    function bLUSDToken() external view returns (IBLUSDToken);
    function curvePool() external view returns (ICurvePool);
    function bammSPVault() external view returns (IBAMM);
    function yearnCurveVault() external view returns (IYearnVault);
    // constants
    function INDEX_OF_LUSD_TOKEN_IN_CURVE_POOL() external pure returns (int128);

    function createBond(uint256 _lusdAmount) external returns (uint256);
    function createBondWithPermit(
        address owner, 
        uint256 amount, 
        uint256 deadline, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) external  returns (uint256);
    function chickenOut(uint256 _bondID, uint256 _minLUSD) external;
    function chickenIn(uint256 _bondID) external;
    function redeem(uint256 _bLUSDToRedeem, uint256 _minLUSDFromBAMMSPVault) external returns (uint256, uint256);

    // getters
    function calcRedemptionFeePercentage(uint256 _fractionOfBLUSDToRedeem) external view returns (uint256);
    function getBondData(uint256 _bondID) external view returns (uint256 lusdAmount, uint64 claimedBLUSD, uint64 startTime, uint64 endTime, uint8 status);
    function getLUSDToAcquire(uint256 _bondID) external view returns (uint256);
    function calcAccruedBLUSD(uint256 _bondID) external view returns (uint256);
    function calcBondBLUSDCap(uint256 _bondID) external view returns (uint256);
    function getLUSDInBAMMSPVault() external view returns (uint256);
    function calcTotalYearnCurveVaultShareValue() external view returns (uint256);
    function calcTotalLUSDValue() external view returns (uint256);
    function getPendingLUSD() external view returns (uint256);
    function getAcquiredLUSDInSP() external view returns (uint256);
    function getAcquiredLUSDInCurve() external view returns (uint256);
    function getTotalAcquiredLUSD() external view returns (uint256);
    function getPermanentLUSD() external view returns (uint256);
    function getOwnedLUSDInSP() external view returns (uint256);
    function getOwnedLUSDInCurve() external view returns (uint256);
    function calcSystemBackingRatio() external view returns (uint256);
    function calcUpdatedAccrualParameter() external view returns (uint256);
    function getBAMMLUSDDebt() external view returns (uint256);
}

interface IBondNFT is IERC721Enumerable {
    struct BondExtraData {
        uint80 initialHalfDna;
        uint80 finalHalfDna;
        uint32 troveSize;         // Debt in LUSD
        uint32 lqtyAmount;        // Holding LQTY, staking or deposited into Pickle
        uint32 curveGaugeSlopes;  // For 3CRV and Frax pools combined
    }

    function mint(address _bonder, uint256 _permanentSeed) external returns (uint256, uint80);
    function setFinalExtraData(address _bonder, uint256 _tokenID, uint256 _permanentSeed) external returns (uint80);
    function chickenBondManager() external view returns (IChickenBondManager);
    function getBondAmount(uint256 _tokenID) external view returns (uint256 amount);
    function getBondStartTime(uint256 _tokenID) external view returns (uint256 startTime);
    function getBondEndTime(uint256 _tokenID) external view returns (uint256 endTime);
    function getBondInitialHalfDna(uint256 _tokenID) external view returns (uint80 initialHalfDna);
    function getBondInitialDna(uint256 _tokenID) external view returns (uint256 initialDna);
    function getBondFinalHalfDna(uint256 _tokenID) external view returns (uint80 finalHalfDna);
    function getBondFinalDna(uint256 _tokenID) external view returns (uint256 finalDna);
    function getBondStatus(uint256 _tokenID) external view returns (uint8 status);
    function getBondExtraData(uint256 _tokenID) external view returns (uint80 initialHalfDna, uint80 finalHalfDna, uint32 troveSize, uint32 lqtyAmount, uint32 curveGaugeSlopes);
}

interface IYearnRegistry {
    function latestVault(address _tokenAddress) external returns (address);
}

interface ICurveLiquidityGaugeV5 is IERC20 {
    // Public state getters

    function reward_data(address _reward_token) external returns (
        address token,
        address distributor,
        uint256 period_finish,
        uint256 rate,
        uint256 last_update,
        uint256 integral
    );

    // User-facing functions

    function deposit(uint256 _value) external;
    function deposit(uint256 _value, address _addr) external;
    function deposit(uint256 _value, address _addr, bool _claim_rewards) external;

    function withdraw(uint256 _value) external;
    function withdraw(uint256 _value, bool _claim_rewards) external;

    function claim_rewards() external;
    function claim_rewards(address _addr) external;
    function claim_rewards(address _addr, address _receiver) external;

    function user_checkpoint(address addr) external returns (bool);
    function set_rewards_receiver(address _receiver) external;
    function kick(address addr) external;

    // Admin functions

    function deposit_reward_token(address _reward_token, uint256 _amount) external;
    function add_reward(address _reward_token, address _distributor) external;
    function set_reward_distributor(address _reward_token, address _distributor) external;
    function set_killed(bool _is_killed) external;

    // View methods

    function claimed_reward(address _addr, address _token) external view returns (uint256);
    function claimable_reward(address _user, address _reward_token) external view returns (uint256);
    function claimable_tokens(address addr) external view returns (uint256);

    function integrate_checkpoint() external view returns (uint256);
    function future_epoch_time() external view returns (uint256);
    function inflation_rate() external view returns (uint256);

    function version() external view returns (string memory);
}

// import "forge-std/console.sol";

contract ChickenBondManager is ChickenMath, IChickenBondManager {

    // ChickenBonds contracts and addresses
    IBondNFT immutable public bondNFT;

    IBLUSDToken immutable public bLUSDToken;
    ILUSDToken immutable public lusdToken;

    // External contracts and addresses
    ICurvePool immutable public curvePool; // LUSD meta-pool (i.e. coin 0 is LUSD, coin 1 is LP token from a base pool)
    ICurvePool immutable public curveBasePool; // base pool of curvePool
    IBAMM immutable public bammSPVault; // B.Protocol Stability Pool vault
    IYearnVault immutable public yearnCurveVault;
    IYearnRegistry immutable public yearnRegistry;
    ICurveLiquidityGaugeV5 immutable public curveLiquidityGauge;

    address immutable public yearnGovernanceAddress;

    uint256 immutable public CHICKEN_IN_AMM_FEE;

    uint256 private pendingLUSD;          // Total pending LUSD. It will always be in SP (B.Protocol)
    uint256 private permanentLUSD;        // Total permanent LUSD
    uint256 private bammLUSDDebt;         // Amount “owed” by B.Protocol to ChickenBonds, equals deposits - withdrawals + rewards
    uint256 public yTokensHeldByCBM;      // Computed balance of Y-tokens of LUSD-3CRV vault owned by this contract
                                          // (to prevent certain attacks where attacker increases the balance and thus the backing ratio)

    // --- Data structures ---

    struct ExternalAdresses {
        address bondNFTAddress;
        address lusdTokenAddress;
        address curvePoolAddress;
        address curveBasePoolAddress;
        address bammSPVaultAddress;
        address yearnCurveVaultAddress;
        address yearnRegistryAddress;
        address yearnGovernanceAddress;
        address bLUSDTokenAddress;
        address curveLiquidityGaugeAddress;
    }

    struct Params {
        uint256 targetAverageAgeSeconds;        // Average outstanding bond age above which the controller will adjust `accrualParameter` in order to speed up accrual
        uint256 initialAccrualParameter;        // Initial value for `accrualParameter`
        uint256 minimumAccrualParameter;        // Stop adjusting `accrualParameter` when this value is reached
        uint256 accrualAdjustmentRate;          // `accrualParameter` is multiplied `1 - accrualAdjustmentRate` every time there's an adjustment
        uint256 accrualAdjustmentPeriodSeconds; // The duration of an adjustment period in seconds
        uint256 chickenInAMMFee;                // Fraction of bonded amount that is sent to Curve Liquidity Gauge to incentivize LUSD-bLUSD liquidity
        uint256 curveDepositDydxThreshold;      // Threshold of SP => Curve shifting
        uint256 curveWithdrawalDxdyThreshold;   // Threshold of Curve => SP shifting
        uint256 bootstrapPeriodChickenIn;       // Min duration of first chicken-in
        uint256 bootstrapPeriodRedeem;          // Redemption lock period after first chicken in
        uint256 bootstrapPeriodShift;           // Period after launch during which shifter functions are disabled
        uint256 shifterDelay;                   // Duration of shifter countdown
        uint256 shifterWindow;                  // Interval in which shifting is possible after countdown finishes
        uint256 minBLUSDSupply;                 // Minimum amount of bLUSD supply that must remain after a redemption
        uint256 minBondAmount;                  // Minimum amount of LUSD that needs to be bonded
        uint256 nftRandomnessDivisor;           // Divisor for permanent LUSD amount in NFT pseudo-randomness computation (see comment below)
        uint256 redemptionFeeBeta;              // Parameter by which to divide the redeemed fraction, in order to calculate the new base rate from a redemption
        uint256 redemptionFeeMinuteDecayFactor; // Factor by which redemption fee decays (exponentially) every minute
    }

    struct BondData {
        uint256 lusdAmount;
        uint64 claimedBLUSD; // In BLUSD units without decimals
        uint64 startTime;
        uint64 endTime; // Timestamp of chicken in/out event
        BondStatus status;
    }

    uint256 public firstChickenInTime; // Timestamp of the first chicken in after bLUSD supply is zero
    uint256 public totalWeightedStartTimes; // Sum of `lusdAmount * startTime` for all outstanding bonds (used to tell weighted average bond age)
    uint256 public lastRedemptionTime; // The timestamp of the latest redemption
    uint256 public baseRedemptionRate; // The latest base redemption rate
    mapping (uint256 => BondData) private idToBondData;

    /* migration: flag which determines whether the system is in migration mode.

    When migration mode has been triggered:

    - No funds are held in the permanent bucket. Liquidity is either pending, or acquired
    - Bond creation and public shifter functions are disabled
    - Users with an existing bond may still chicken in or out
    - Chicken-ins will no longer send the LUSD surplus to the permanent bucket. Instead, they refund the surplus to the bonder
    - bLUSD holders may still redeem
    - Redemption fees are zero
    */
    bool public migration;

    uint256 public countChickenIn;
    uint256 public countChickenOut;

    // --- Constants ---

    uint256 constant MAX_UINT256 = type(uint256).max;
    int128 public constant INDEX_OF_LUSD_TOKEN_IN_CURVE_POOL = 0;
    int128 constant INDEX_OF_3CRV_TOKEN_IN_CURVE_POOL = 1;

    uint256 constant public SECONDS_IN_ONE_MINUTE = 60;

    uint256 public immutable BOOTSTRAP_PERIOD_CHICKEN_IN; // Min duration of first chicken-in
    uint256 public immutable BOOTSTRAP_PERIOD_REDEEM;     // Redemption lock period after first chicken in
    uint256 public immutable BOOTSTRAP_PERIOD_SHIFT;      // Period after launch during which shifter functions are disabled

    uint256 public immutable SHIFTER_DELAY;               // Duration of shifter countdown
    uint256 public immutable SHIFTER_WINDOW;              // Interval in which shifting is possible after countdown finishes

    uint256 public immutable MIN_BLUSD_SUPPLY;            // Minimum amount of bLUSD supply that must remain after a redemption
    uint256 public immutable MIN_BOND_AMOUNT;             // Minimum amount of LUSD that needs to be bonded
    // This is the minimum amount the permanent bucket needs to be increased by an attacker (through previous chicken in or redemption fee),
    // in order to manipulate the obtained NFT. If the attacker finds the desired outcome at attempt N,
    // the permanent increase should be N * NFT_RANDOMNESS_DIVISOR.
    // It also means that as long as Permanent doesn’t change in that order of magnitude, attacker can try to manipulate
    // only changing the event date.
    uint256 public immutable NFT_RANDOMNESS_DIVISOR;

    /*
     * BETA: 18 digit decimal. Parameter by which to divide the redeemed fraction, in order to calc the new base rate from a redemption.
     * Corresponds to (1 / ALPHA) in the Liquity white paper.
     */
    uint256 public immutable BETA;
    uint256 public immutable MINUTE_DECAY_FACTOR;

    uint256 constant CURVE_FEE_DENOMINATOR = 1e10;

    // Thresholds of SP <=> Curve shifting
    uint256 public immutable curveDepositLUSD3CRVExchangeRateThreshold;
    uint256 public immutable curveWithdrawal3CRVLUSDExchangeRateThreshold;

    // Timestamp at which the last shifter countdown started
    uint256 public lastShifterCountdownStartTime;

    // --- Accrual control variables ---

    // `block.timestamp` of the block in which this contract was deployed.
    uint256 public immutable deploymentTimestamp;

    // Average outstanding bond age above which the controller will adjust `accrualParameter` in order to speed up accrual.
    uint256 public immutable targetAverageAgeSeconds;

    // Stop adjusting `accrualParameter` when this value is reached.
    uint256 public immutable minimumAccrualParameter;

    // Number between 0 and 1. `accrualParameter` is multiplied by this every time there's an adjustment.
    uint256 public immutable accrualAdjustmentMultiplier;

    // The duration of an adjustment period in seconds. The controller performs at most one adjustment per every period.
    uint256 public immutable accrualAdjustmentPeriodSeconds;

    // The number of seconds it takes to accrue 50% of the cap, represented as an 18 digit fixed-point number.
    uint256 public accrualParameter;

    // Counts the number of adjustment periods since deployment.
    // Updated by operations that change the average outstanding bond age (createBond, chickenIn, chickenOut).
    // Used by `_calcUpdatedAccrualParameter` to tell whether it's time to perform adjustments, and if so, how many times
    // (in case the time elapsed since the last adjustment is more than one adjustment period).
    uint256 public accrualAdjustmentPeriodCount;

    // --- Events ---

    event BaseRedemptionRateUpdated(uint256 _baseRedemptionRate);
    event LastRedemptionTimeUpdated(uint256 _lastRedemptionFeeOpTime);
    event BondCreated(address indexed bonder, uint256 bondId, uint256 amount, uint80 bondInitialHalfDna);
    event BondClaimed(
        address indexed bonder,
        uint256 bondId,
        uint256 lusdAmount,
        uint256 bLusdAmount,
        uint256 lusdSurplus,
        uint256 chickenInFeeAmount,
        bool migration,
        uint80 bondFinalHalfDna
    );
    event BondCancelled(address indexed bonder, uint256 bondId, uint256 principalLusdAmount, uint256 minLusdAmount, uint256 withdrawnLusdAmount, uint80 bondFinalHalfDna);
    event BLUSDRedeemed(address indexed redeemer, uint256 bLusdAmount, uint256 minLusdAmount, uint256 lusdAmount, uint256 yTokens, uint256 redemptionFee);
    event MigrationTriggered(uint256 previousPermanentLUSD);
    event AccrualParameterUpdated(uint256 accrualParameter);

    // --- Constructor ---

    constructor
    (
        ExternalAdresses memory _externalContractAddresses, // to avoid stack too deep issues
        Params memory _params
    )
    {
        bondNFT = IBondNFT(_externalContractAddresses.bondNFTAddress);
        lusdToken = ILUSDToken(_externalContractAddresses.lusdTokenAddress);
        bLUSDToken = IBLUSDToken(_externalContractAddresses.bLUSDTokenAddress);
        curvePool = ICurvePool(_externalContractAddresses.curvePoolAddress);
        curveBasePool = ICurvePool(_externalContractAddresses.curveBasePoolAddress);
        bammSPVault = IBAMM(_externalContractAddresses.bammSPVaultAddress);
        yearnCurveVault = IYearnVault(_externalContractAddresses.yearnCurveVaultAddress);
        yearnRegistry = IYearnRegistry(_externalContractAddresses.yearnRegistryAddress);
        yearnGovernanceAddress = _externalContractAddresses.yearnGovernanceAddress;

        deploymentTimestamp = block.timestamp;
        targetAverageAgeSeconds = _params.targetAverageAgeSeconds;
        accrualParameter = _params.initialAccrualParameter;
        minimumAccrualParameter = _params.minimumAccrualParameter;
        require(minimumAccrualParameter > 0, "CBM: Min accrual parameter cannot be zero");
        accrualAdjustmentMultiplier = 1e18 - _params.accrualAdjustmentRate;
        accrualAdjustmentPeriodSeconds = _params.accrualAdjustmentPeriodSeconds;

        curveLiquidityGauge = ICurveLiquidityGaugeV5(_externalContractAddresses.curveLiquidityGaugeAddress);
        CHICKEN_IN_AMM_FEE = _params.chickenInAMMFee;

        uint256 fee = curvePool.fee(); // This is practically immutable (can only be set once, in `initialize()`)

        // By exchange rate, we mean the rate at which Curve exchanges LUSD <=> $ value of 3CRV (at the virtual price),
        // which is reduced by the fee.
        // For convenience, we want to parameterize our thresholds in terms of the spot prices -dy/dx & -dx/dy,
        // which are not exposed by Curve directly. Instead, we turn our thresholds into thresholds on the exchange rate
        // by taking into account the fee.
        curveDepositLUSD3CRVExchangeRateThreshold =
            _params.curveDepositDydxThreshold * (CURVE_FEE_DENOMINATOR - fee) / CURVE_FEE_DENOMINATOR;
        curveWithdrawal3CRVLUSDExchangeRateThreshold =
            _params.curveWithdrawalDxdyThreshold * (CURVE_FEE_DENOMINATOR - fee) / CURVE_FEE_DENOMINATOR;

        BOOTSTRAP_PERIOD_CHICKEN_IN = _params.bootstrapPeriodChickenIn;
        BOOTSTRAP_PERIOD_REDEEM = _params.bootstrapPeriodRedeem;
        BOOTSTRAP_PERIOD_SHIFT = _params.bootstrapPeriodShift;
        SHIFTER_DELAY = _params.shifterDelay;
        SHIFTER_WINDOW = _params.shifterWindow;
        MIN_BLUSD_SUPPLY = _params.minBLUSDSupply;
        require(_params.minBondAmount > 0, "CBM: MIN BOND AMOUNT parameter cannot be zero"); // We can still use 1e-18
        MIN_BOND_AMOUNT = _params.minBondAmount;
        NFT_RANDOMNESS_DIVISOR = _params.nftRandomnessDivisor;
        BETA = _params.redemptionFeeBeta;
        MINUTE_DECAY_FACTOR = _params.redemptionFeeMinuteDecayFactor;

        // TODO: Decide between one-time infinite LUSD approval to Yearn and Curve (lower gas cost per user tx, less secure
        // or limited approval at each bonder action (higher gas cost per user tx, more secure)
        lusdToken.approve(address(bammSPVault), MAX_UINT256);
        lusdToken.approve(address(curvePool), MAX_UINT256);
        curvePool.approve(address(yearnCurveVault), MAX_UINT256);
        lusdToken.approve(address(curveLiquidityGauge), MAX_UINT256);

        // Check that the system is hooked up to the correct latest Yearn vault
        assert(address(yearnCurveVault) == yearnRegistry.latestVault(address(curvePool)));
    }

    // --- User-facing functions ---

    function createBond(uint256 _lusdAmount) public returns (uint256) {
        _requireMinBond(_lusdAmount);
        _requireMigrationNotActive();

        _updateAccrualParameter();

        // Mint the bond NFT to the caller and get the bond ID
        (uint256 bondID, uint80 initialHalfDna) = bondNFT.mint(msg.sender, permanentLUSD / NFT_RANDOMNESS_DIVISOR);

        //Record the user’s bond data: bond_amount and start_time
        BondData memory bondData;
        bondData.lusdAmount = _lusdAmount;
        bondData.startTime = uint64(block.timestamp);
        bondData.status = BondStatus.active;
        idToBondData[bondID] = bondData;

        pendingLUSD += _lusdAmount;
        totalWeightedStartTimes += _lusdAmount * block.timestamp;

        lusdToken.transferFrom(msg.sender, address(this), _lusdAmount);

        // Deposit the LUSD to the B.Protocol LUSD vault
        _depositToBAMM(_lusdAmount);

        emit BondCreated(msg.sender, bondID, _lusdAmount, initialHalfDna);

        return bondID;
    }

    function createBondWithPermit(
        address owner, 
        uint256 amount, 
        uint256 deadline, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) external returns (uint256) {
        // LCB-10: don't call permit if the user already has the required amount permitted
        if (lusdToken.allowance(owner, address(this)) < amount) {
            lusdToken.permit(owner, address(this), amount, deadline, v, r, s);
        }
        return createBond(amount);
    }

    function chickenOut(uint256 _bondID, uint256 _minLUSD) external {
        BondData memory bond = idToBondData[_bondID];

        _requireCallerOwnsBond(_bondID);
        _requireActiveStatus(bond.status);

        _updateAccrualParameter();

        idToBondData[_bondID].status = BondStatus.chickenedOut;
        idToBondData[_bondID].endTime = uint64(block.timestamp);
        uint80 newDna = bondNFT.setFinalExtraData(msg.sender, _bondID, permanentLUSD / NFT_RANDOMNESS_DIVISOR);

        countChickenOut += 1;

        pendingLUSD -= bond.lusdAmount;
        totalWeightedStartTimes -= bond.lusdAmount * bond.startTime;

        /* In practice, there could be edge cases where the pendingLUSD is not fully backed:
        * - Heavy liquidations, and before yield has been converted
        * - Heavy loss-making liquidations, i.e. at <100% CR
        * - SP or B.Protocol vault hack that drains LUSD
        *
        * The user can decide how to handle chickenOuts if/when the recorded pendingLUSD is not fully backed by actual
        * LUSD in B.Protocol / the SP, by adjusting _minLUSD */
        uint256 lusdToWithdraw = _requireEnoughLUSDInBAMM(bond.lusdAmount, _minLUSD);

        // Withdraw from B.Protocol LUSD vault
        _withdrawFromBAMM(lusdToWithdraw, msg.sender);

        emit BondCancelled(msg.sender, _bondID, bond.lusdAmount, _minLUSD, lusdToWithdraw, newDna);
    }

    // transfer _lusdToTransfer to the LUSD/bLUSD AMM LP Rewards staking contract
    function _transferToRewardsStakingContract(uint256 _lusdToTransfer) internal {
        uint256 lusdBalanceBefore = lusdToken.balanceOf(address(this));
        curveLiquidityGauge.deposit_reward_token(address(lusdToken), _lusdToTransfer);

        assert(lusdBalanceBefore - lusdToken.balanceOf(address(this)) == _lusdToTransfer);
    }

    function _withdrawFromSPVaultAndTransferToRewardsStakingContract(uint256 _lusdAmount) internal {
        // Pull the LUSD amount from B.Protocol LUSD vault
        _withdrawFromBAMM(_lusdAmount, address(this));

        // Deposit in rewards contract
        _transferToRewardsStakingContract(_lusdAmount);
    }

    /* Divert acquired yield to LUSD/bLUSD AMM LP rewards staking contract
     * It happens on the very first chicken in event of the system, or any time that redemptions deplete bLUSD total supply to zero
     * Assumption: When there have been no chicken ins since the bLUSD supply was set to 0 (either due to system deployment, or full bLUSD redemption),
     * all acquired LUSD must necessarily be pure yield.
     */
    function _firstChickenIn(uint256 _bondStartTime, uint256 _bammLUSDValue, uint256 _lusdInBAMMSPVault) internal returns (uint256) {
        //assert(!migration); // we leave it as a comment so we can uncomment it for automated testing tools

        require(block.timestamp >= _bondStartTime + BOOTSTRAP_PERIOD_CHICKEN_IN, "CBM: First chicken in must wait until bootstrap period is over");
        firstChickenInTime = block.timestamp;

        (
            uint256 acquiredLUSDInSP,
            /* uint256 acquiredLUSDInCurve */,
            /* uint256 ownedLUSDInSP */,
            /* uint256 ownedLUSDInCurve */,
            /* uint256 permanentLUSDCached */
        ) = _getLUSDSplit(_bammLUSDValue);

        // Make sure that LUSD available in B.Protocol is at least as much as acquired
        // If first chicken in happens after an scenario of heavy liquidations and before ETH has been sold by B.Protocol
        // so that there’s not enough LUSD available in B.Protocol to transfer all the acquired bucket to the staking contract,
        // the system would start with a backing ratio greater than 1
        require(_lusdInBAMMSPVault >= acquiredLUSDInSP, "CBM: Not enough LUSD available in B.Protocol");

        // From SP Vault
        if (acquiredLUSDInSP > 0) {
            _withdrawFromSPVaultAndTransferToRewardsStakingContract(acquiredLUSDInSP);
        }

        return _lusdInBAMMSPVault - acquiredLUSDInSP;
    }

    function chickenIn(uint256 _bondID) external {
        BondData memory bond = idToBondData[_bondID];

        _requireCallerOwnsBond(_bondID);
        _requireActiveStatus(bond.status);

        uint256 updatedAccrualParameter = _updateAccrualParameter();
        (uint256 bammLUSDValue, uint256 lusdInBAMMSPVault) = _updateBAMMDebt();

        (uint256 chickenInFeeAmount, uint256 bondAmountMinusChickenInFee) = _getBondWithChickenInFeeApplied(bond.lusdAmount);

        /* Upon the first chicken-in after a) system deployment or b) redemption of the full bLUSD supply, divert
        * any earned yield to the bLUSD-LUSD AMM for fairness.
        *
        * This is not done in migration mode since there is no need to send rewards to the staking contract.
        */
        if (bLUSDToken.totalSupply() == 0 && !migration) {
            lusdInBAMMSPVault = _firstChickenIn(bond.startTime, bammLUSDValue, lusdInBAMMSPVault);
        }

        // Get the LUSD amount to acquire from the bond in proportion to the system's current backing ratio, in order to maintain said ratio.
        uint256 lusdToAcquire = _calcAccruedAmount(bond.startTime, bondAmountMinusChickenInFee, updatedAccrualParameter);
        // Get backing ratio and accrued bLUSD
        uint256 backingRatio = _calcSystemBackingRatioFromBAMMValue(bammLUSDValue);
        uint256 accruedBLUSD = lusdToAcquire * 1e18 / backingRatio;

        idToBondData[_bondID].claimedBLUSD = uint64(Math.min(accruedBLUSD / 1e18, type(uint64).max)); // to units and uint64
        idToBondData[_bondID].status = BondStatus.chickenedIn;
        idToBondData[_bondID].endTime = uint64(block.timestamp);
        uint80 newDna = bondNFT.setFinalExtraData(msg.sender, _bondID, permanentLUSD / NFT_RANDOMNESS_DIVISOR);

        countChickenIn += 1;

        // Subtract the bonded amount from the total pending LUSD (and implicitly increase the total acquired LUSD)
        pendingLUSD -= bond.lusdAmount;
        totalWeightedStartTimes -= bond.lusdAmount * bond.startTime;

        // Get the remaining surplus from the LUSD amount to acquire from the bond
        uint256 lusdSurplus = bondAmountMinusChickenInFee - lusdToAcquire;

        // Handle the surplus LUSD from the chicken-in:
        if (!migration) { // In normal mode, add the surplus to the permanent bucket by increasing the permament tracker. This implicitly decreases the acquired LUSD.
            permanentLUSD += lusdSurplus;
        } else { // In migration mode, withdraw surplus from B.Protocol and refund to bonder
            // TODO: should we allow to pass in a minimum value here too?
            (,lusdInBAMMSPVault,) = bammSPVault.getLUSDValue();
            uint256 lusdToRefund = Math.min(lusdSurplus, lusdInBAMMSPVault);
            if (lusdToRefund > 0) { _withdrawFromBAMM(lusdToRefund, msg.sender); }
        }

        bLUSDToken.mint(msg.sender, accruedBLUSD);

        // Transfer the chicken in fee to the LUSD/bLUSD AMM LP Rewards staking contract during normal mode.
        if (!migration && lusdInBAMMSPVault >= chickenInFeeAmount) {
            _withdrawFromSPVaultAndTransferToRewardsStakingContract(chickenInFeeAmount);
        }

        emit BondClaimed(msg.sender, _bondID, bond.lusdAmount, accruedBLUSD, lusdSurplus, chickenInFeeAmount, migration, newDna);
    }

    function redeem(uint256 _bLUSDToRedeem, uint256 _minLUSDFromBAMMSPVault) external returns (uint256, uint256) {
        _requireNonZeroAmount(_bLUSDToRedeem);
        _requireRedemptionNotDepletingbLUSD(_bLUSDToRedeem);

        require(block.timestamp >= firstChickenInTime + BOOTSTRAP_PERIOD_REDEEM, "CBM: Redemption after first chicken in must wait until bootstrap period is over");

        (
            uint256 acquiredLUSDInSP,
            uint256 acquiredLUSDInCurve,
            /* uint256 ownedLUSDInSP */,
            uint256 ownedLUSDInCurve,
            uint256 permanentLUSDCached
        ) = _getLUSDSplitAfterUpdatingBAMMDebt();

        uint256 fractionOfBLUSDToRedeem = _bLUSDToRedeem * 1e18 / bLUSDToken.totalSupply();
        // Calculate redemption fee. No fee in migration mode.
        uint256 redemptionFeePercentage = migration ? 0 : _updateRedemptionFeePercentage(fractionOfBLUSDToRedeem);
        // Will collect redemption fees from both buckets (in LUSD).
        uint256 redemptionFeeLUSD;

        // TODO: Both _requireEnoughLUSDInBAMM and _updateBAMMDebt call B.Protocol getLUSDValue, so it may be optmized
        // Calculate the LUSD to withdraw from LUSD vault, withdraw and send to redeemer. Move the fee to the permanent bucket.
        uint256 lusdToWithdrawFromSP;
        { // Block scoping to avoid stack too deep issues
            uint256 acquiredLUSDInSPToRedeem = acquiredLUSDInSP * fractionOfBLUSDToRedeem / 1e18;
            uint256 acquiredLUSDInSPToWithdraw = acquiredLUSDInSPToRedeem * (1e18 - redemptionFeePercentage) / 1e18;
            redemptionFeeLUSD += acquiredLUSDInSPToRedeem - acquiredLUSDInSPToWithdraw;
            lusdToWithdrawFromSP = _requireEnoughLUSDInBAMM(acquiredLUSDInSPToWithdraw, _minLUSDFromBAMMSPVault);
            if (lusdToWithdrawFromSP > 0) { _withdrawFromBAMM(lusdToWithdrawFromSP, msg.sender); }
        }

        // Send yTokens to the redeemer according to the proportion of owned LUSD in Curve that's being redeemed
        uint256 yTokensFromCurveVault;
        if (ownedLUSDInCurve > 0) {
            uint256 acquiredLUSDInCurveToRedeem = acquiredLUSDInCurve * fractionOfBLUSDToRedeem / 1e18;
            uint256 lusdToWithdrawFromCurve = acquiredLUSDInCurveToRedeem * (1e18 - redemptionFeePercentage) / 1e18;
            redemptionFeeLUSD += acquiredLUSDInCurveToRedeem - lusdToWithdrawFromCurve;
            yTokensFromCurveVault = yTokensHeldByCBM * lusdToWithdrawFromCurve / ownedLUSDInCurve;
            if (yTokensFromCurveVault > 0) { _transferFromCurve(msg.sender, yTokensFromCurveVault); }
        }

        // Move the fee to permanent. This implicitly removes it from the acquired bucket
        permanentLUSD = permanentLUSDCached + redemptionFeeLUSD;

        _requireNonZeroAmount(lusdToWithdrawFromSP + yTokensFromCurveVault);

        // Burn the redeemed bLUSD
        bLUSDToken.burn(msg.sender, _bLUSDToRedeem);

        emit BLUSDRedeemed(msg.sender, _bLUSDToRedeem, _minLUSDFromBAMMSPVault, lusdToWithdrawFromSP, yTokensFromCurveVault, redemptionFeeLUSD);

        return (lusdToWithdrawFromSP, yTokensFromCurveVault);
    }

    function shiftLUSDFromSPToCurve(uint256 _maxLUSDToShift) external {
        _requireShiftBootstrapPeriodEnded();
        _requireMigrationNotActive();
        _requireNonZeroBLUSDSupply();
        _requireShiftWindowIsOpen();

        (uint256 bammLUSDValue, uint256 lusdInBAMMSPVault) = _updateBAMMDebt();
        uint256 lusdOwnedInBAMMSPVault = bammLUSDValue - pendingLUSD;

        uint256 totalLUSDInCurve = getTotalLUSDInCurve();
        // it can happen due to profits from shifts or rounding errors:
        _requirePermanentGreaterThanCurve(totalLUSDInCurve);

        // Make sure pending bucket is not moved to Curve, so it can be withdrawn on chicken out
        uint256 clampedLUSDToShift = Math.min(_maxLUSDToShift, lusdOwnedInBAMMSPVault);

        // Make sure there’s enough LUSD available in B.Protocol
        clampedLUSDToShift = Math.min(clampedLUSDToShift, lusdInBAMMSPVault);

        // Make sure we don’t make Curve bucket greater than Permanent one with the shift
        // subtraction is safe per _requirePermanentGreaterThanCurve above
        clampedLUSDToShift = Math.min(clampedLUSDToShift, permanentLUSD - totalLUSDInCurve);

        _requireNonZeroAmount(clampedLUSDToShift);

        // Get the 3CRV virtual price only once, and use it for both initial and final check.
        // Adding LUSD liquidity to the meta-pool does not change 3CRV virtual price.
        uint256 _3crvVirtualPrice = curveBasePool.get_virtual_price();
        uint256 initialExchangeRate = _getLUSD3CRVExchangeRate(_3crvVirtualPrice);

        require(
            initialExchangeRate > curveDepositLUSD3CRVExchangeRateThreshold,
            "CBM: LUSD:3CRV exchange rate must be over the deposit threshold before SP->Curve shift"
        );

        // Withdram LUSD from B.Protocol
        _withdrawFromBAMM(clampedLUSDToShift, address(this));

        // Deposit the received LUSD to Curve in return for LUSD3CRV-f tokens
        uint256 lusd3CRVBalanceBefore = curvePool.balanceOf(address(this));
        /* TODO: Determine if we should pass a minimum amount of LP tokens to receive here. Seems infeasible to determinine the mininum on-chain from
        * Curve spot price / quantities, which are manipulable. */
        curvePool.add_liquidity([clampedLUSDToShift, 0], 0);
        uint256 lusd3CRVBalanceDelta = curvePool.balanceOf(address(this)) - lusd3CRVBalanceBefore;

        // Deposit the received LUSD3CRV-f to Yearn Curve vault
        _depositToCurve(lusd3CRVBalanceDelta);

        // Do price check: ensure the SP->Curve shift has decreased the LUSD:3CRV exchange rate, but not into unprofitable territory
        uint256 finalExchangeRate = _getLUSD3CRVExchangeRate(_3crvVirtualPrice);

        require(
            finalExchangeRate < initialExchangeRate &&
            finalExchangeRate >= curveDepositLUSD3CRVExchangeRateThreshold,
            "CBM: SP->Curve shift must decrease LUSD:3CRV exchange rate to a value above the deposit threshold"
        );
    }

    function shiftLUSDFromCurveToSP(uint256 _maxLUSDToShift) external {
        _requireShiftBootstrapPeriodEnded();
        _requireMigrationNotActive();
        _requireNonZeroBLUSDSupply();
        _requireShiftWindowIsOpen();

        // We can’t shift more than what’s in Curve
        uint256 ownedLUSDInCurve = getTotalLUSDInCurve();
        uint256 clampedLUSDToShift = Math.min(_maxLUSDToShift, ownedLUSDInCurve);
        _requireNonZeroAmount(clampedLUSDToShift);

        // Get the 3CRV virtual price only once, and use it for both initial and final check.
        // Removing LUSD liquidity from the meta-pool does not change 3CRV virtual price.
        uint256 _3crvVirtualPrice = curveBasePool.get_virtual_price();
        uint256 initialExchangeRate = _get3CRVLUSDExchangeRate(_3crvVirtualPrice);

        // Here we're using the 3CRV:LUSD exchange rate (with 3CRV being valued at its virtual price),
        // which increases as LUSD price decreases, hence the direction of the inequality.
        require(
            initialExchangeRate > curveWithdrawal3CRVLUSDExchangeRateThreshold,
            "CBM: 3CRV:LUSD exchange rate must be above the withdrawal threshold before Curve->SP shift"
        );

        // Convert yTokens to LUSD3CRV-f
        uint256 lusd3CRVBalanceBefore = curvePool.balanceOf(address(this));

        // ownedLUSDInCurve > 0 implied by _requireNonZeroAmount(clampedLUSDToShift)
        uint256 yTokensToBurnFromCurveVault = yTokensHeldByCBM * clampedLUSDToShift / ownedLUSDInCurve;
        _withdrawFromCurve(yTokensToBurnFromCurveVault);
        uint256 lusd3CRVBalanceDelta = curvePool.balanceOf(address(this)) - lusd3CRVBalanceBefore;

        // Withdraw LUSD from Curve
        uint256 lusdBalanceBefore = lusdToken.balanceOf(address(this));
        /* TODO: Determine if we should pass a minimum amount of LUSD to receive here. Seems infeasible to determinine the mininum on-chain from
        * Curve spot price / quantities, which are manipulable. */
        curvePool.remove_liquidity_one_coin(lusd3CRVBalanceDelta, INDEX_OF_LUSD_TOKEN_IN_CURVE_POOL, 0);
        uint256 lusdBalanceDelta = lusdToken.balanceOf(address(this)) - lusdBalanceBefore;

        // Assertion should hold in principle. In practice, there is usually minor rounding error
        // assert(lusdBalanceDelta == _lusdToShift);

        // Deposit the received LUSD to B.Protocol LUSD vault
        _depositToBAMM(lusdBalanceDelta);

        // Ensure the Curve->SP shift has decreased the 3CRV:LUSD exchange rate, but not into unprofitable territory
        uint256 finalExchangeRate = _get3CRVLUSDExchangeRate(_3crvVirtualPrice);

        require(
            finalExchangeRate < initialExchangeRate &&
            finalExchangeRate >= curveWithdrawal3CRVLUSDExchangeRateThreshold,
            "CBM: Curve->SP shift must increase 3CRV:LUSD exchange rate to a value above the withdrawal threshold"
        );
    }

    // --- B.Protocol debt functions ---

    // If the actual balance of B.Protocol is higher than our internal accounting,
    // it means that B.Protocol has had gains (through sell of ETH or LQTY).
    // We account for those gains
    // If the balance was lower (which would mean losses), we expect them to be eventually recovered
    function _getInternalBAMMLUSDValue() internal view returns (uint256) {
        (, uint256 lusdInBAMMSPVault,) = bammSPVault.getLUSDValue();

        return Math.max(bammLUSDDebt, lusdInBAMMSPVault);
    }

    // TODO: Should we make this one publicly callable, so that external getters can be up to date (by previously calling this)?
    // Returns the value updated
    function _updateBAMMDebt() internal returns (uint256, uint256) {
        (, uint256 lusdInBAMMSPVault,) = bammSPVault.getLUSDValue();
        uint256 bammLUSDDebtCached = bammLUSDDebt;

        // If the actual balance of B.Protocol is higher than our internal accounting,
        // it means that B.Protocol has had gains (through sell of ETH or LQTY).
        // We account for those gains
        // If the balance was lower (which would mean losses), we expect them to be eventually recovered
        if (lusdInBAMMSPVault > bammLUSDDebtCached) {
            bammLUSDDebt = lusdInBAMMSPVault;
            return (lusdInBAMMSPVault, lusdInBAMMSPVault);
        }

        return (bammLUSDDebtCached, lusdInBAMMSPVault);
    }

    function _depositToBAMM(uint256 _lusdAmount) internal {
        bammSPVault.deposit(_lusdAmount);
        bammLUSDDebt += _lusdAmount;
    }

    function _withdrawFromBAMM(uint256 _lusdAmount, address _to) internal {
        bammSPVault.withdraw(_lusdAmount, _to);
        bammLUSDDebt -= _lusdAmount;
    }

    // @dev make sure this wrappers are always used instead of calling yearnCurveVault functions directyl,
    // otherwise the internal accounting would fail
    function _depositToCurve(uint256 _lusd3CRV) internal {
        uint256 yTokensBalanceBefore = yearnCurveVault.balanceOf(address(this));
        yearnCurveVault.deposit(_lusd3CRV);
        uint256 yTokensBalanceDelta = yearnCurveVault.balanceOf(address(this)) - yTokensBalanceBefore;
        yTokensHeldByCBM += yTokensBalanceDelta;
    }

    function _withdrawFromCurve(uint256 _yTokensToSwap) internal {
        yearnCurveVault.withdraw(_yTokensToSwap);
        yTokensHeldByCBM -= _yTokensToSwap;
    }

    function _transferFromCurve(address _to, uint256 _yTokensToTransfer) internal {
        yearnCurveVault.transfer(_to, _yTokensToTransfer);
        yTokensHeldByCBM -= _yTokensToTransfer;
    }

    // --- Migration functionality ---

    /* Migration function callable one-time and only by Yearn governance.
    * Moves all permanent LUSD in Curve to the Curve acquired bucket.
    */
    function activateMigration() external {
        _requireCallerIsYearnGovernance();
        _requireMigrationNotActive();

        migration = true;

        emit MigrationTriggered(permanentLUSD);

        // Zero the permament LUSD tracker. This implicitly makes all permament liquidity acquired (and redeemable)
        permanentLUSD = 0;
    }

    // --- Shifter countdown starter ---

    function startShifterCountdown() public {
        // First check that the previous delay and shifting window have passed
        require(block.timestamp >= lastShifterCountdownStartTime + SHIFTER_DELAY + SHIFTER_WINDOW, "CBM: Previous shift delay and window must have passed");

        // Begin the new countdown from now
        lastShifterCountdownStartTime = block.timestamp;
    }

    // --- Fee share ---

    function sendFeeShare(uint256 _lusdAmount) external {
        _requireCallerIsYearnGovernance();
        require(!migration, "CBM: Receive fee share only in normal mode");

        // Move LUSD from caller to CBM and deposit to B.Protocol LUSD Vault
        lusdToken.transferFrom(yearnGovernanceAddress, address(this), _lusdAmount);
        _depositToBAMM(_lusdAmount);
    }

    // --- Helper functions ---

    function _getLUSD3CRVExchangeRate(uint256 _3crvVirtualPrice) internal view returns (uint256) {
        // Get the amount of 3CRV that would be received by swapping 1 LUSD (after deduction of fees)
        // If p_{LUSD:3CRV} is the price of LUSD quoted in 3CRV, then this returns p_{LUSD:3CRV} * (1 - fee)
        // as long as the pool is large enough so that 1 LUSD doesn't introduce significant slippage.
        uint256 dy = curvePool.get_dy(INDEX_OF_LUSD_TOKEN_IN_CURVE_POOL, INDEX_OF_3CRV_TOKEN_IN_CURVE_POOL, 1e18);

        return dy * _3crvVirtualPrice / 1e18;
    }

    function _get3CRVLUSDExchangeRate(uint256 _3crvVirtualPrice) internal view returns (uint256) {
        // Get the amount of LUSD that would be received by swapping 1 3CRV (after deduction of fees)
        // If p_{3CRV:LUSD} is the price of 3CRV quoted in LUSD, then this returns p_{3CRV:LUSD} * (1 - fee)
        // as long as the pool is large enough so that 1 3CRV doesn't introduce significant slippage.
        uint256 dy = curvePool.get_dy(INDEX_OF_3CRV_TOKEN_IN_CURVE_POOL, INDEX_OF_LUSD_TOKEN_IN_CURVE_POOL, 1e18);

        return dy * 1e18 / _3crvVirtualPrice;
    }

    // Calc decayed redemption rate
    function calcRedemptionFeePercentage(uint256 _fractionOfBLUSDToRedeem) public view returns (uint256) {
        uint256 minutesPassed = _minutesPassedSinceLastRedemption();
        uint256 decayFactor = decPow(MINUTE_DECAY_FACTOR, minutesPassed);

        uint256 decayedBaseRedemptionRate = baseRedemptionRate * decayFactor / DECIMAL_PRECISION;

        // Increase redemption base rate with the new redeemed amount
        uint256 newBaseRedemptionRate = decayedBaseRedemptionRate + _fractionOfBLUSDToRedeem / BETA;
        newBaseRedemptionRate = Math.min(newBaseRedemptionRate, DECIMAL_PRECISION); // cap baseRate at a maximum of 100%
        //assert(newBaseRedemptionRate <= DECIMAL_PRECISION); // This is already enforced in the line above

        return newBaseRedemptionRate;
    }

    // Update the base redemption rate and the last redemption time (only if time passed >= decay interval. This prevents base rate griefing)
    function _updateRedemptionFeePercentage(uint256 _fractionOfBLUSDToRedeem) internal returns (uint256) {
        uint256 newBaseRedemptionRate = calcRedemptionFeePercentage(_fractionOfBLUSDToRedeem);
        baseRedemptionRate = newBaseRedemptionRate;
        emit BaseRedemptionRateUpdated(newBaseRedemptionRate);

        uint256 timePassed = block.timestamp - lastRedemptionTime;

        if (timePassed >= SECONDS_IN_ONE_MINUTE) {
            lastRedemptionTime = block.timestamp;
            emit LastRedemptionTimeUpdated(block.timestamp);
        }

        return newBaseRedemptionRate;
    }

    function _minutesPassedSinceLastRedemption() internal view returns (uint256) {
        return (block.timestamp - lastRedemptionTime) / SECONDS_IN_ONE_MINUTE;
    }

    function _getBondWithChickenInFeeApplied(uint256 _bondLUSDAmount) internal view returns (uint256, uint256) {
        // Apply zero fee in migration mode
        if (migration) {return (0, _bondLUSDAmount);}

        // Otherwise, apply the constant fee rate
        uint256 chickenInFeeAmount = _bondLUSDAmount * CHICKEN_IN_AMM_FEE / 1e18;
        uint256 bondAmountMinusChickenInFee = _bondLUSDAmount - chickenInFeeAmount;

        return (chickenInFeeAmount, bondAmountMinusChickenInFee);
    }

    function _getBondAmountMinusChickenInFee(uint256 _bondLUSDAmount) internal view returns (uint256) {
        (, uint256 bondAmountMinusChickenInFee) = _getBondWithChickenInFeeApplied(_bondLUSDAmount);
        return bondAmountMinusChickenInFee;
    }

    /* _calcAccruedAmount: internal getter for calculating accrued token amount for a given bond.
    *
    * This function is unit-agnostic. It can be used to calculate a bonder's accrrued bLUSD, or the LUSD that that the
    * CB system would acquire (i.e. receive to the acquired bucket) if the bond were Chickened In now.
    *
    * For the bonder, _capAmount is their bLUSD cap.
    * For the CB system, _capAmount is the LUSD bond amount (less the Chicken In fee).
    */
    function _calcAccruedAmount(uint256 _startTime, uint256 _capAmount, uint256 _accrualParameter) internal view returns (uint256) {
        // All bonds have a non-zero creation timestamp, so return accrued sLQTY 0 if the startTime is 0
        if (_startTime == 0) {return 0;}

        // Scale `bondDuration` up to an 18 digit fixed-point number.
        // This lets us add it to `accrualParameter`, which is also an 18-digit FP.
        uint256 bondDuration = 1e18 * (block.timestamp - _startTime);

        uint256 accruedAmount = _capAmount * bondDuration / (bondDuration + _accrualParameter);
        //assert(accruedAmount < _capAmount); // we leave it as a comment so we can uncomment it for automated testing tools

        return accruedAmount;
    }

    // Gauge the average (size-weighted) outstanding bond age and adjust accrual parameter if it's higher than our target.
    // If there's been more than one adjustment period since the last adjustment, perform multiple adjustments retroactively.
    function _calcUpdatedAccrualParameter(
        uint256 _storedAccrualParameter,
        uint256 _storedAccrualAdjustmentCount
    )
        internal
        view
        returns (
            uint256 updatedAccrualParameter,
            uint256 updatedAccrualAdjustmentPeriodCount
        )
    {
        updatedAccrualAdjustmentPeriodCount = (block.timestamp - deploymentTimestamp) / accrualAdjustmentPeriodSeconds;

        if (
            // There hasn't been enough time since the last update to warrant another update
            updatedAccrualAdjustmentPeriodCount == _storedAccrualAdjustmentCount ||
            // or `accrualParameter` is already bottomed-out
            _storedAccrualParameter == minimumAccrualParameter ||
            // or there are no outstanding bonds (avoid division by zero)
            pendingLUSD == 0
        ) {
            return (_storedAccrualParameter, updatedAccrualAdjustmentPeriodCount);
        }

        uint256 averageStartTime = totalWeightedStartTimes / pendingLUSD;

        // We want to calculate the period when the average age will have reached or exceeded the
        // target average age, to be used later in a check against the actual current period.
        //
        // At any given timestamp `t`, the average age can be calculated as:
        //   averageAge(t) = t - averageStartTime
        //
        // For any period `n`, the average age is evaluated at the following timestamp:
        //   tSample(n) = deploymentTimestamp + n * accrualAdjustmentPeriodSeconds
        //
        // Hence we're looking for the smallest integer `n` such that:
        //   averageAge(tSample(n)) >= targetAverageAgeSeconds
        //
        // If `n` is the smallest integer for which the above inequality stands, then:
        //   averageAge(tSample(n - 1)) < targetAverageAgeSeconds
        //
        // Combining the two inequalities:
        //   averageAge(tSample(n - 1)) < targetAverageAgeSeconds <= averageAge(tSample(n))
        //
        // Substituting and rearranging:
        //   1.    deploymentTimestamp + (n - 1) * accrualAdjustmentPeriodSeconds - averageStartTime
        //       < targetAverageAgeSeconds
        //      <= deploymentTimestamp + n * accrualAdjustmentPeriodSeconds - averageStartTime
        //
        //   2.    (n - 1) * accrualAdjustmentPeriodSeconds
        //       < averageStartTime + targetAverageAgeSeconds - deploymentTimestamp
        //      <= n * accrualAdjustmentPeriodSeconds
        //
        //   3. n - 1 < (averageStartTime + targetAverageAgeSeconds - deploymentTimestamp) / accrualAdjustmentPeriodSeconds <= n
        //
        // Using equivalence `n = ceil(x) <=> n - 1 < x <= n` we arrive at:
        //   n = ceil((averageStartTime + targetAverageAgeSeconds - deploymentTimestamp) / accrualAdjustmentPeriodSeconds)
        //
        // We can calculate `ceil(a / b)` using `Math.ceilDiv(a, b)`.
        uint256 adjustmentPeriodCountWhenTargetIsExceeded = Math.ceilDiv(
            averageStartTime + targetAverageAgeSeconds - deploymentTimestamp,
            accrualAdjustmentPeriodSeconds
        );

        if (updatedAccrualAdjustmentPeriodCount < adjustmentPeriodCountWhenTargetIsExceeded) {
            // No adjustment needed; target average age hasn't been exceeded yet
            return (_storedAccrualParameter, updatedAccrualAdjustmentPeriodCount);
        }

        uint256 numberOfAdjustments = updatedAccrualAdjustmentPeriodCount - Math.max(
            _storedAccrualAdjustmentCount,
            adjustmentPeriodCountWhenTargetIsExceeded - 1
        );

        updatedAccrualParameter = Math.max(
            _storedAccrualParameter * decPow(accrualAdjustmentMultiplier, numberOfAdjustments) / 1e18,
            minimumAccrualParameter
        );
    }

    function _updateAccrualParameter() internal returns (uint256) {
        uint256 storedAccrualParameter = accrualParameter;
        uint256 storedAccrualAdjustmentPeriodCount = accrualAdjustmentPeriodCount;

        (uint256 updatedAccrualParameter, uint256 updatedAccrualAdjustmentPeriodCount) =
            _calcUpdatedAccrualParameter(storedAccrualParameter, storedAccrualAdjustmentPeriodCount);

        if (updatedAccrualAdjustmentPeriodCount != storedAccrualAdjustmentPeriodCount) {
            accrualAdjustmentPeriodCount = updatedAccrualAdjustmentPeriodCount;

            if (updatedAccrualParameter != storedAccrualParameter) {
                accrualParameter = updatedAccrualParameter;
                emit AccrualParameterUpdated(updatedAccrualParameter);
            }
        }

        return updatedAccrualParameter;
    }

    // Internal getter for calculating the bond bLUSD cap based on bonded amount and backing ratio
    function _calcBondBLUSDCap(uint256 _bondedAmount, uint256 _backingRatio) internal pure returns (uint256) {
        // TODO: potentially refactor this -  i.e. have a (1 / backingRatio) function for more precision
        return _bondedAmount * 1e18 / _backingRatio;
    }

    // --- 'require' functions

    function _requireCallerOwnsBond(uint256 _bondID) internal view {
        require(msg.sender == bondNFT.ownerOf(_bondID), "CBM: Caller must own the bond");
    }

    function _requireActiveStatus(BondStatus status) internal pure {
        require(status == BondStatus.active, "CBM: Bond must be active");
    }

    function _requireNonZeroAmount(uint256 _amount) internal pure {
        require(_amount > 0, "CBM: Amount must be > 0");
    }

    function _requireNonZeroBLUSDSupply() internal view {
        require(bLUSDToken.totalSupply() > 0, "CBM: bLUSD Supply must be > 0 upon shifting");
    }

    function _requireMinBond(uint256 _lusdAmount) internal view {
        require(_lusdAmount >= MIN_BOND_AMOUNT, "CBM: Bond minimum amount not reached");
    }

    function _requireRedemptionNotDepletingbLUSD(uint256 _bLUSDToRedeem) internal view {
        if (!migration) {
            //require(_bLUSDToRedeem < bLUSDTotalSupply, "CBM: Cannot redeem total supply");
            require(_bLUSDToRedeem + MIN_BLUSD_SUPPLY <= bLUSDToken.totalSupply(), "CBM: Cannot redeem below min supply");
        }
    }

    function _requireMigrationNotActive() internal view {
        require(!migration, "CBM: Migration must be not be active");
    }

    function _requireCallerIsYearnGovernance() internal view {
        require(msg.sender == yearnGovernanceAddress, "CBM: Only Yearn Governance can call");
    }

    function _requireEnoughLUSDInBAMM(uint256 _requestedLUSD, uint256 _minLUSD) internal view returns (uint256) {
        require(_requestedLUSD >= _minLUSD, "CBM: Min value cannot be greater than nominal amount");

        (, uint256 lusdInBAMMSPVault,) = bammSPVault.getLUSDValue();
        require(lusdInBAMMSPVault >= _minLUSD, "CBM: Not enough LUSD available in B.Protocol");

        uint256 lusdToWithdraw = Math.min(_requestedLUSD, lusdInBAMMSPVault);

        return lusdToWithdraw;
    }

    function _requireShiftBootstrapPeriodEnded() internal view {
        require(block.timestamp - deploymentTimestamp >= BOOTSTRAP_PERIOD_SHIFT, "CBM: Shifter only callable after shift bootstrap period ends");
    }

    function _requireShiftWindowIsOpen() internal view {
        uint256 shiftWindowStartTime = lastShifterCountdownStartTime + SHIFTER_DELAY;
        uint256 shiftWindowFinishTime = shiftWindowStartTime + SHIFTER_WINDOW;

        require(block.timestamp >= shiftWindowStartTime && block.timestamp < shiftWindowFinishTime, "CBM: Shift only possible inside shifting window");
    }

    function _requirePermanentGreaterThanCurve(uint256 _totalLUSDInCurve) internal view {
        require(permanentLUSD >= _totalLUSDInCurve, "CBM: The amount in Curve cannot be greater than the Permanent bucket");
    }

    // --- Getter convenience functions ---

    // Bond getters

    function getBondData(uint256 _bondID)
        external
        view
        returns (
            uint256 lusdAmount,
            uint64 claimedBLUSD,
            uint64 startTime,
            uint64 endTime,
            uint8 status
        )
    {
        BondData memory bond = idToBondData[_bondID];
        return (bond.lusdAmount, bond.claimedBLUSD, bond.startTime, bond.endTime, uint8(bond.status));
    }

    function getLUSDToAcquire(uint256 _bondID) external view returns (uint256) {
        BondData memory bond = idToBondData[_bondID];

        (uint256 updatedAccrualParameter, ) = _calcUpdatedAccrualParameter(accrualParameter, accrualAdjustmentPeriodCount);

        return _calcAccruedAmount(bond.startTime, _getBondAmountMinusChickenInFee(bond.lusdAmount), updatedAccrualParameter);
    }

    function calcAccruedBLUSD(uint256 _bondID) external view returns (uint256) {
        BondData memory bond = idToBondData[_bondID];

        if (bond.status != BondStatus.active) {
            return 0;
        }

        uint256 bondBLUSDCap = _calcBondBLUSDCap(_getBondAmountMinusChickenInFee(bond.lusdAmount), calcSystemBackingRatio());

        (uint256 updatedAccrualParameter, ) = _calcUpdatedAccrualParameter(accrualParameter, accrualAdjustmentPeriodCount);

        return _calcAccruedAmount(bond.startTime, bondBLUSDCap, updatedAccrualParameter);
    }

    function calcBondBLUSDCap(uint256 _bondID) external view returns (uint256) {
        uint256 backingRatio = calcSystemBackingRatio();

        BondData memory bond = idToBondData[_bondID];

        return _calcBondBLUSDCap(_getBondAmountMinusChickenInFee(bond.lusdAmount), backingRatio);
    }

    function getLUSDInBAMMSPVault() external view returns (uint256) {
        (, uint256 lusdInBAMMSPVault,) = bammSPVault.getLUSDValue();

        return lusdInBAMMSPVault;
    }

    // Native vault token value getters

    // Calculates the LUSD3CRV value of LUSD Curve Vault yTokens held by the ChickenBondManager
    function calcTotalYearnCurveVaultShareValue() public view returns (uint256) {
        return yTokensHeldByCBM * yearnCurveVault.pricePerShare() / 1e18;
    }

    // Calculates the LUSD value of this contract, including B.Protocol LUSD Vault and Curve Vault
    function calcTotalLUSDValue() external view returns (uint256) {
        uint256 totalLUSDInCurve = getTotalLUSDInCurve();
        uint256 bammLUSDValue = _getInternalBAMMLUSDValue();

        return bammLUSDValue + totalLUSDInCurve;
    }

    function getTotalLUSDInCurve() public view returns (uint256) {
        uint256 LUSD3CRVInCurve = calcTotalYearnCurveVaultShareValue();
        uint256 totalLUSDInCurve;
        if (LUSD3CRVInCurve > 0) {
            uint256 LUSD3CRVVirtualPrice = curvePool.get_virtual_price();
            totalLUSDInCurve = LUSD3CRVInCurve * LUSD3CRVVirtualPrice / 1e18;
        }

        return totalLUSDInCurve;
    }

    // Pending getter

    function getPendingLUSD() external view returns (uint256) {
        return pendingLUSD;
    }

    // Acquired getters

    function _getLUSDSplit(uint256 _bammLUSDValue)
        internal
        view
        returns (
            uint256 acquiredLUSDInSP,
            uint256 acquiredLUSDInCurve,
            uint256 ownedLUSDInSP,
            uint256 ownedLUSDInCurve,
            uint256 permanentLUSDCached
        )
    {
        // _bammLUSDValue is guaranteed to be at least pendingLUSD due to the way we track BAMM debt
        ownedLUSDInSP = _bammLUSDValue - pendingLUSD;
        ownedLUSDInCurve = getTotalLUSDInCurve(); // All LUSD in Curve is owned
        permanentLUSDCached = permanentLUSD;

        uint256 ownedLUSD = ownedLUSDInSP + ownedLUSDInCurve;

        if (ownedLUSD > permanentLUSDCached) {
            // ownedLUSD > 0 implied
            uint256 acquiredLUSD = ownedLUSD - permanentLUSDCached;
            acquiredLUSDInSP = acquiredLUSD * ownedLUSDInSP / ownedLUSD;
            acquiredLUSDInCurve = acquiredLUSD - acquiredLUSDInSP;
        }
    }

    // Helper to avoid stack too deep in redeem() (we save one local variable)
    function _getLUSDSplitAfterUpdatingBAMMDebt()
        internal
        returns (
            uint256 acquiredLUSDInSP,
            uint256 acquiredLUSDInCurve,
            uint256 ownedLUSDInSP,
            uint256 ownedLUSDInCurve,
            uint256 permanentLUSDCached
        )
    {
        (uint256 bammLUSDValue,) = _updateBAMMDebt();
        return _getLUSDSplit(bammLUSDValue);
    }

    function getTotalAcquiredLUSD() public view returns (uint256) {
        uint256 bammLUSDValue = _getInternalBAMMLUSDValue();
        (uint256 acquiredLUSDInSP, uint256 acquiredLUSDInCurve,,,) = _getLUSDSplit(bammLUSDValue);
        return acquiredLUSDInSP + acquiredLUSDInCurve;
    }

    function getAcquiredLUSDInSP() external view returns (uint256) {
        uint256 bammLUSDValue = _getInternalBAMMLUSDValue();
        (uint256 acquiredLUSDInSP,,,,) = _getLUSDSplit(bammLUSDValue);
        return acquiredLUSDInSP;
    }

    function getAcquiredLUSDInCurve() external view returns (uint256) {
        uint256 bammLUSDValue = _getInternalBAMMLUSDValue();
        (, uint256 acquiredLUSDInCurve,,,) = _getLUSDSplit(bammLUSDValue);
        return acquiredLUSDInCurve;
    }

    // Permanent getter

    function getPermanentLUSD() external view returns (uint256) {
        return permanentLUSD;
    }

    // Owned getters

    function getOwnedLUSDInSP() external view returns (uint256) {
        uint256 bammLUSDValue = _getInternalBAMMLUSDValue();
        (,, uint256 ownedLUSDInSP,,) = _getLUSDSplit(bammLUSDValue);
        return ownedLUSDInSP;
    }

    function getOwnedLUSDInCurve() external view returns (uint256) {
        uint256 bammLUSDValue = _getInternalBAMMLUSDValue();
        (,,, uint256 ownedLUSDInCurve,) = _getLUSDSplit(bammLUSDValue);
        return ownedLUSDInCurve;
    }

    // Other getters

    function calcSystemBackingRatio() public view returns (uint256) {
        uint256 bammLUSDValue = _getInternalBAMMLUSDValue();
        return _calcSystemBackingRatioFromBAMMValue(bammLUSDValue);
    }

    function _calcSystemBackingRatioFromBAMMValue(uint256 _bammLUSDValue) public view returns (uint256) {
        uint256 totalBLUSDSupply = bLUSDToken.totalSupply();
        (uint256 acquiredLUSDInSP, uint256 acquiredLUSDInCurve,,,) = _getLUSDSplit(_bammLUSDValue);

        /* TODO: Determine how to define the backing ratio when there is 0 bLUSD and 0 totalAcquiredLUSD,
         * i.e. before the first chickenIn. For now, return a backing ratio of 1. Note: Both quantities would be 0
         * also when the bLUSD supply is fully redeemed.
         */
        //if (totalBLUSDSupply == 0  && totalAcquiredLUSD == 0) {return 1e18;}
        //if (totalBLUSDSupply == 0) {return MAX_UINT256;}
        if (totalBLUSDSupply == 0) {return 1e18;}

        return  (acquiredLUSDInSP + acquiredLUSDInCurve) * 1e18 / totalBLUSDSupply;
    }

    function calcUpdatedAccrualParameter() external view returns (uint256) {
        (uint256 updatedAccrualParameter, ) = _calcUpdatedAccrualParameter(accrualParameter, accrualAdjustmentPeriodCount);
        return updatedAccrualParameter;
    }

    function getBAMMLUSDDebt() external view returns (uint256) {
        return bammLUSDDebt;
    }

    function getTreasury()
        external
        view
        returns (
            // We don't normally use leading underscores for return values,
            // but we do so here in order to avoid shadowing state variables
            uint256 _pendingLUSD,
            uint256 _totalAcquiredLUSD,
            uint256 _permanentLUSD
        )
    {
        _pendingLUSD = pendingLUSD;
        _totalAcquiredLUSD = getTotalAcquiredLUSD();
        _permanentLUSD = permanentLUSD;
    }

    function getOpenBondCount() external view returns (uint256 openBondCount) {
        return bondNFT.totalSupply() - countChickenIn - countChickenOut;
    }
}