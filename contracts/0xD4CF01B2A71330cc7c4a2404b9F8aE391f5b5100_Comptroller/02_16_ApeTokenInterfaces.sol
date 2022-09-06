pragma solidity ^0.5.16;

import "./ComptrollerInterface.sol";
import "./InterestRateModel.sol";
import "./ERC3156FlashBorrowerInterface.sol";

contract ApeTokenStorage {
    /**
     * @dev Guard variable for re-entrancy checks
     */
    bool internal _notEntered;

    enum Version {
        VANILLA,
        COLLATERALCAP,
        WRAPPEDNATIVE
    }

    /**
     * @notice ApeToken version
     */
    Version public version;

    /**
     * @notice EIP-20 token name for this token
     */
    string public name;

    /**
     * @notice EIP-20 token symbol for this token
     */
    string public symbol;

    /**
     * @notice EIP-20 token decimals for this token
     */
    uint8 public decimals;

    /**
     * @notice Maximum borrow rate that can ever be applied (.0005% / block)
     */

    uint256 internal constant borrowRateMaxMantissa = 0.0005e16;

    /**
     * @notice Maximum fraction of interest that can be set aside for reserves
     */
    uint256 internal constant reserveFactorMaxMantissa = 1e18;

    /**
     * @notice Administrator for this contract
     */
    address payable public admin;

    /**
     * @notice Pending administrator for this contract
     */
    address payable public pendingAdmin;

    /**
     * @notice Contract which oversees inter-apeToken operations
     */
    ComptrollerInterface public comptroller;

    /**
     * @notice Model which tells what the current interest rate should be
     */
    InterestRateModel public interestRateModel;

    /**
     * @notice Initial exchange rate used when minting the first ApeTokens (used when totalSupply = 0)
     */
    uint256 internal initialExchangeRateMantissa;

    /**
     * @notice Fraction of interest currently set aside for reserves
     */
    uint256 public reserveFactorMantissa;

    /**
     * @notice Block number that interest was last accrued at
     */
    uint256 public accrualBlockNumber;

    /**
     * @notice Accumulator of the total earned interest rate since the opening of the market
     */
    uint256 public borrowIndex;

    /**
     * @notice Total amount of outstanding borrows of the underlying in this market
     */
    uint256 public totalBorrows;

    /**
     * @notice Total amount of reserves of the underlying held in this market
     */
    uint256 public totalReserves;

    /**
     * @notice Total number of tokens in circulation
     */
    uint256 public totalSupply;

    /**
     * @notice Official record of token balances for each account
     */
    mapping(address => uint256) internal accountTokens;

    /**
     * @notice Container for borrow balance information
     * @member principal Total balance (with accrued interest), after applying the most recent balance-changing action
     * @member interestIndex Global borrowIndex as of the most recent balance-changing action
     */
    struct BorrowSnapshot {
        uint256 principal;
        uint256 interestIndex;
    }

    /**
     * @notice Mapping of account addresses to outstanding borrow balances
     */
    mapping(address => BorrowSnapshot) internal accountBorrows;

    /**
     * @notice The borrow fee of this market
     */
    uint256 public borrowFee;

    /**
     * @notice Helper contract address of this contract
     */
    address public helper;
}

contract ApeErc20Storage {
    /**
     * @notice Underlying asset for this ApeToken
     */
    address public underlying;

    /**
     * @notice Implementation address for this contract
     */
    address public implementation;
}

contract CSupplyCapStorage {
    /**
     * @notice Internal cash counter for this ApeToken. Should equal underlying.balanceOf(address(this)) for ApeErc20.
     */
    uint256 public internalCash;
}

contract CCollateralCapStorage {
    /**
     * @notice Total number of tokens used as collateral in circulation.
     */
    uint256 public totalCollateralTokens;

    /**
     * @notice Record of token balances which could be treated as collateral for each account.
     *         If collateral cap is not set, the value should be equal to accountTokens.
     */
    mapping(address => uint256) public accountCollateralTokens;

    /**
     * @notice Collateral cap for this ApeToken, zero for no cap.
     */
    uint256 public collateralCap;
}

/*** Interface ***/

contract ApeTokenInterface is ApeTokenStorage {
    /**
     * @notice Indicator that this is a ApeToken contract (for inspection)
     */
    bool public constant isApeToken = true;

    /*** Market Events ***/

    /**
     * @notice Event emitted when interest is accrued
     */
    event AccrueInterest(uint256 cashPrior, uint256 interestAccumulated, uint256 borrowIndex, uint256 totalBorrows);

    /**
     * @notice Event emitted when tokens are minted
     */
    event Mint(address payer, address minter, uint256 mintAmount, uint256 mintTokens);

    /**
     * @notice Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint256 redeemAmount, uint256 redeemTokens);

    /**
     * @notice Event emitted when underlying is borrowed
     */
    event Borrow(address borrower, uint256 borrowAmount, uint256 accountBorrows, uint256 totalBorrows);

    /**
     * @notice Event emitted when a borrow is repaid
     */
    event RepayBorrow(
        address payer,
        address borrower,
        uint256 repayAmount,
        uint256 accountBorrows,
        uint256 totalBorrows
    );

    /**
     * @notice Event emitted when a borrow is liquidated
     */
    event LiquidateBorrow(
        address liquidator,
        address borrower,
        uint256 repayAmount,
        address apeTokenCollateral,
        uint256 seizeTokens
    );

    /*** Admin Events ***/

    /**
     * @notice Event emitted when pendingAdmin is changed
     */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
     * @notice Event emitted when pendingAdmin is accepted, which means admin is updated
     */
    event NewAdmin(address oldAdmin, address newAdmin);

    /**
     * @notice Event emitted when comptroller is changed
     */
    event NewComptroller(ComptrollerInterface oldComptroller, ComptrollerInterface newComptroller);

    /**
     * @notice Event emitted when interestRateModel is changed
     */
    event NewMarketInterestRateModel(InterestRateModel oldInterestRateModel, InterestRateModel newInterestRateModel);

    /**
     * @notice Event emitted when the reserve factor is changed
     */
    event NewReserveFactor(uint256 oldReserveFactorMantissa, uint256 newReserveFactorMantissa);

    /**
     * @notice Event emitted when the reserves are added
     */
    event ReservesAdded(address benefactor, uint256 addAmount, uint256 newTotalReserves);

    /**
     * @notice Event emitted when the reserves are reduced
     */
    event ReservesReduced(address admin, uint256 reduceAmount, uint256 newTotalReserves);

    /**
     * @notice Failure event
     */
    event Failure(uint256 error, uint256 info, uint256 detail);

    /**
     * @notice Bororw fee event
     */
    event BorrowFee(uint256 oldBorrowFee, uint256 newBorrowFee);

    /**
     * @notice Helper event
     */
    event HelperSet(address oldHelper, address newHelper);

    /*** User Interface ***/

    function balanceOf(address owner) external view returns (uint256);

    function balanceOfUnderlying(address owner) external returns (uint256);

    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function borrowRatePerBlock() external view returns (uint256);

    function supplyRatePerBlock() external view returns (uint256);

    function totalBorrowsCurrent() external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function borrowBalanceStored(address account) public view returns (uint256);

    function exchangeRateCurrent() public returns (uint256);

    function exchangeRateStored() public view returns (uint256);

    function getCash() external view returns (uint256);

    function accrueInterest() public returns (uint256);

    function seize(
        address liquidator,
        address borrower,
        uint256 seizeTokens,
        uint256 feeTokens
    ) external returns (uint256);

    /*** Admin Functions ***/

    function _setPendingAdmin(address payable newPendingAdmin) external returns (uint256);

    function _acceptAdmin() external returns (uint256);

    function _setComptroller(ComptrollerInterface newComptroller) public returns (uint256);

    function _setReserveFactor(uint256 newReserveFactorMantissa) external returns (uint256);

    function _reduceReserves(uint256 reduceAmount) external returns (uint256);

    function _setInterestRateModel(InterestRateModel newInterestRateModel) public returns (uint256);

    function _setBorrowFee(uint256 newBorrowFee) public;

    function _setHelper(address newHelper) public;

    function _setDelegate(
        address delegateContract,
        bytes32 id,
        address delegate
    ) external;
}

contract ApeErc20Interface is ApeErc20Storage {
    /*** User Interface ***/

    function mint(address minter, uint256 mintAmount) external returns (uint256);

    function redeem(
        address payable redeemer,
        uint256 redeemTokens,
        uint256 redeemAmount
    ) external returns (uint256);

    function borrow(address payable borrower, uint256 borrowAmount) external returns (uint256);

    function repayBorrow(address borrower, uint256 repayAmount) external returns (uint256);

    function liquidateBorrow(
        address borrower,
        uint256 repayAmount,
        ApeTokenInterface apeTokenCollateral
    ) external returns (uint256);

    function _addReserves(uint256 addAmount) external returns (uint256);
}

contract ApeWrappedNativeInterface is ApeErc20Interface {
    /**
     * @notice Flash loan fee ratio
     */
    uint256 public constant flashFeeBips = 3;

    /*** Market Events ***/

    /**
     * @notice Event emitted when a flashloan occured
     */
    event Flashloan(address indexed receiver, uint256 amount, uint256 totalFee, uint256 reservesFee);

    /*** User Interface ***/

    function mintNative(address minter) external payable returns (uint256);

    function redeemNative(
        address payable redeemer,
        uint256 redeemTokens,
        uint256 redeemAmount
    ) external returns (uint256);

    function borrowNative(address payable borrower, uint256 borrowAmount) external returns (uint256);

    function repayBorrowNative(address borrower) external payable returns (uint256);

    function liquidateBorrowNative(address borrower, ApeTokenInterface apeTokenCollateral)
        external
        payable
        returns (uint256);

    function flashLoan(
        ERC3156FlashBorrowerInterface receiver,
        address initiator,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);

    function _addReservesNative() external payable returns (uint256);

    function collateralCap() external view returns (uint256);

    function totalCollateralTokens() external view returns (uint256);
}

contract CCapableErc20Interface is ApeErc20Interface, CSupplyCapStorage {
    /**
     * @notice Flash loan fee ratio
     */
    uint256 public constant flashFeeBips = 3;

    /*** Market Events ***/

    /**
     * @notice Event emitted when a flashloan occured
     */
    event Flashloan(address indexed receiver, uint256 amount, uint256 totalFee, uint256 reservesFee);

    /*** User Interface ***/

    function gulp() external;
}

contract ApeCollateralCapErc20Interface is CCapableErc20Interface, CCollateralCapStorage {
    /*** Admin Events ***/

    /**
     * @notice Event emitted when collateral cap is set
     */
    event NewCollateralCap(address token, uint256 newCap);

    /**
     * @notice Event emitted when user collateral is changed
     */
    event UserCollateralChanged(address account, uint256 newCollateralTokens);

    /*** User Interface ***/

    function registerCollateral() external returns (uint256);

    function flashLoan(
        ERC3156FlashBorrowerInterface receiver,
        address initiator,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);

    /*** Admin Functions ***/

    function _setCollateralCap(uint256 newCollateralCap) external;
}

contract CDelegatorInterface {
    /**
     * @notice Emitted when implementation is changed
     */
    event NewImplementation(address oldImplementation, address newImplementation);

    /**
     * @notice Called by the admin to update the implementation of the delegator
     * @param implementation_ The address of the new implementation for delegation
     * @param allowResign Flag to indicate whether to call _resignImplementation on the old implementation
     * @param becomeImplementationData The encoded bytes data to be passed to _becomeImplementation
     */
    function _setImplementation(
        address implementation_,
        bool allowResign,
        bytes memory becomeImplementationData
    ) public;
}

contract CDelegateInterface {
    /**
     * @notice Called by the delegator on a delegate to initialize it for duty
     * @dev Should revert if any issues arise which make it unfit for delegation
     * @param data The encoded bytes data for any initialization
     */
    function _becomeImplementation(bytes memory data) public;

    /**
     * @notice Called by the delegator on a delegate to forfeit its responsibility
     */
    function _resignImplementation() public;
}

/*** External interface ***/

/**
 * @title Flash loan receiver interface
 */
interface IFlashloanReceiver {
    function executeOperation(
        address sender,
        address underlying,
        uint256 amount,
        uint256 fee,
        bytes calldata params
    ) external;
}