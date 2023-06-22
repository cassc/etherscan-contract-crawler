// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "./MatrixpricerInterface.sol";
import "./InterestRateModel.sol";
import "./LevTokenInterfaces.sol";
import "./EIP20NonStandardInterface.sol";
import "./ErrorReporter.sol";
// import "./DepositWithdraw.sol";

contract DepTokenStorage {
    //uint internal constant MAXGAS = 0;
    /**
     * @dev protection against contract calling itself (re-entrancy check)
     */
    bool internal _notEntered;

    /**
     * @notice EIP-20 token name for this token
     */
    string public name;

    /**
     * @notice EIP-20 token symbol for this token
     */
    string public symbol;

    /**
     * @notice EIP-20 token decimals for this token, we use 6 to stay consistent with usdt
     */
    uint8 public decimals;

    // Maximum fraction of interest that can be set aside for reserves
    uint internal constant reserveFactorMaxMantissa = 1e18;

    /**
     * @notice Administrator for this contract
     */
    address payable public admin;

    /**
     * @notice Pending administrator for this contract
     */
    address payable public pendingAdmin;

    /**
     * @notice the brain of this contract
     */
    MatrixpricerInterface public matrixpricer;

    /**
     * @notice Model that computes deposit and lending rate
     */
    InterestRateModel public interestRateModel;

    /**
     * @notice associated levErc20
     */
    LevErc20Interface public levErc20;

    // when totalSupply = 0, need to initialise an exchangeRate
    uint internal initialExchangeRateMantissa;  // 1e18

    /**
     * @notice Fraction of interest currently set aside for reserves
     */
    uint public reserveFactorMantissa;  //1e18

    /**
     * @notice Block number that interest was last accrued at
     */
    uint public accrualBlockNumber;

    /**
     * @notice Accumulator of the total earned interest rate since the opening of the market
     */
    uint public borrowIndex;

    /**
     * @notice Total amount of outstanding borrows of the underlying in this market
     */
    uint public totalBorrows;   // decimals = 6, same as underlying(=usdt)

    /**
     * @notice Total amount of reserves of the underlying held in this market
     */
    uint public totalReserves;   // decimals = 6, same as underlying(=usdt)

    /**
     * @notice Total number of tokens in circulation
     */
    uint public totalSupply;    // decimals = 6

    // Official record of token balances for each account
    mapping (address => uint) internal accountTokens;

    // Approved token transfer amounts on behalf of others
    mapping (address => mapping (address => uint)) internal transferAllowances;

    // usdt decimals is 6
    uint internal constant minTransferAmtUSDT = 50000e6;
    uint internal constant thresholdUSDT = 300000e6;
    uint internal constant extraUSDT = 100000e6;

    /**
     * @notice Container for borrow balance information
     * @member principal Total balance (with accrued interest), after applying the most recent balance-changing action
     * @member interestIndex Global borrowIndex as of the most recent balance-changing action
     */
    struct BorrowSnapshot {
        uint principal;
        uint interestIndex;
    }

    // Mapping of account addresses to outstanding borrow balances
    mapping(address => BorrowSnapshot) internal accountBorrows;

    /**
     * @notice Share of seized collateral that is added to reserves
     */
    uint public constant protocolSeizeShareMantissa = 2.8e16; //2.8%
}

abstract contract DepTokenInterface is DepTokenStorage {
    /**
     * @notice Indicator that this is a DepToken contract (for inspection)
     */
    bool public constant isDepToken = true;


    /*** Market Events ***/

    /**
     * @notice Event emitted when interest is accrued
     */
    event AccrueInterest(uint cashPrior, uint interestAccumulated, uint borrowIndex, uint totalBorrows);

    /**
     * @notice Event emitted when tokens are minted
     */
    event Mint(address minter, uint mintAmount, uint mintTokens, uint apy);

    /**
     * @notice Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint redeemAmount, uint redeemTokens, uint apy);

    /**
     * @notice Event emitted when underlying is borrowed
     */
    event Borrow(address borrower, uint borrowAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when a borrow is repaid
     */
    event RepayBorrow(address borrower, uint repayAmount, uint accountBorrows, uint totalBorrows, bool liquidate);

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
     * @notice Event emitted when matrixpricer is changed
     */
    event NewMatrixpricer(MatrixpricerInterface oldMatrixpricer, MatrixpricerInterface newMatrixpricer);

    /**
     * @notice Event emitted when interestRateModel is changed
     */
    //event NewMarketInterestRateModel(InterestRateModel oldInterestRateModel, InterestRateModel newInterestRateModel);

    /**
     * @notice Event emitted when the reserve factor is changed
     */
    event NewReserveFactor(uint oldReserveFactorMantissa, uint newReserveFactorMantissa);

    /**
     * @notice Event emitted when the reserves are added
     */
    event ReservesAdded(address benefactor, uint addAmount, uint newTotalReserves);

    /**
     * @notice Event emitted when the reserves are reduced
     */
    event ReservesReduced(address admin, uint reduceAmount, uint newTotalReserves);

    /**
     * @notice EIP20 Transfer event
     */
    event Transfer(address indexed from, address indexed to, uint amount);

    /**
     * @notice EIP20 Approval event
     */
    event Approval(address indexed owner, address indexed spender, uint amount);


    /*** User Interface ***/

    function transfer(address dst, uint amount) virtual external returns (bool);
    function transferFrom(address src, address dst, uint amount) virtual external returns (bool);
    function approve(address spender, uint amount) virtual external returns (bool);
    function allowance(address owner, address spender) virtual external view returns (uint);
    function balanceOf(address owner) virtual external view returns (uint);
    function balanceOfUnderlying(address owner) virtual external returns (uint);
    function balanceOfUnderlyingView(address owner) virtual external view returns (uint);
    function getAccountSnapshot(address account) virtual external view returns (uint, uint, uint, uint);
    function borrowRatePerBlock() virtual external view returns (uint);
    function supplyRatePerBlock() virtual public view returns (uint);
    function totalBorrowsCurrent() virtual external returns (uint);
    //function borrowBalanceCurrent(address account) virtual external returns (uint);
    //function borrowBalanceStored(address account) virtual internal view returns (uint);
    function exchangeRateCurrent() virtual external returns (uint);
    function exchangeRateStored() virtual external view returns (uint);
    function getCash() virtual external view returns (uint);
    function getCompoundBalance() virtual external view returns (uint);
    function accrueInterest() virtual external returns (uint);

    /*** Admin Functions ***/

    function _setPendingAdmin(address payable newPendingAdmin) virtual external returns (uint);
    function _acceptAdmin() virtual external returns (uint);
    function _setMatrixpricer(MatrixpricerInterface newMatrixpricer) virtual external returns (uint);
    function _setReserveFactor(uint newReserveFactorMantissa) virtual external returns (uint);
    function _reduceReserves(uint reduceAmount) virtual external returns (uint);
    function _setInterestRateModel(InterestRateModel newInterestRateModel) virtual external returns (uint);
}

contract DepErc20Storage {
    /**
     * @notice Underlying asset for this DepToken
     */
    address public underlying;
}

abstract contract DepErc20Interface is DepErc20Storage {

    /*** User Interface ***/

    function mint(uint mintAmount) virtual external returns (uint);
    function redeem(uint redeemTokens, uint redeemAmount) virtual external returns (uint);
    function borrow(uint borrowAmount) virtual external returns (uint);
    function repayBorrow(uint repayAmount, bool liquidate) virtual external returns (uint);
    function getUnborrowedUSDTBalance() virtual external view returns (uint);
    function getTotalBorrows() virtual external view returns (uint);    // only 1 borrower
    function getTotalBorrowsAfterAccrueInterest() virtual external returns (uint);    // only 1 borrower

    /*** Admin Functions ***/

    function _addReserves(uint addAmount) virtual external returns (uint);
}