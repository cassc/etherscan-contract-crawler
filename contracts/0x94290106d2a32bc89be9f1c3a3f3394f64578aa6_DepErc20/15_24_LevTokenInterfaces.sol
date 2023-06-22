// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "./TensorpricerInterface.sol";
import "./InterestRateModel.sol";
import "./DepTokenInterfaces.sol";
import "./EIP20NonStandardInterface.sol";
import "./ErrorReporter.sol";
import "./DepositWithdraw.sol";
import "./CurveSwap.sol";

contract LevTokenStorage {
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
     * @notice EIP-20 token decimals for this token, we use 6 to stay consistent with usdc
     */
    uint8 public decimals;

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
    TensorpricerInterface public tensorpricer;

    /**
     * @notice associated depErc20
     */
    DepErc20Interface public depErc20;

    // when totalSupply = 0, need to initialise a NAV
    uint internal constant initialNetAssetValueMantissa = 1e18;  // treat like fx rate, 1e18

    // when totalSupply = 0, need to initialise a targetLevRatio
    uint internal constant initialTargetLevRatio = 5e18;

    /**
     * @notice Total number of tokens in circulation
     */
    uint public totalSupply;    // 1e6

    /**
     * @notice Total amount of outstanding borrow in USDT in this market
     */
    uint public borrowBalanceUSDT;  // in usdt, decimals=6

    /**
     * @notice Total amount of outstanding borrow valued in USDC in this market
     */
    uint public borrowBalanceUSDC;  // in usdc, decimals=6

    /**
     * @notice Total asset value in USDC
     */
    uint public totalAssetValue;  // in usdc, decimals=6

    /**
     * @notice net asset value in USDC
     */
    uint public netAssetValue;  // in usdc, BUT decimals=18, asset per levToken

    /**
     * @notice leverage ratio
     */
    uint public levRatio;   // 1e18

    /**
     * @notice
     */
    uint public extraBorrowDemand;  // in usdt, decimals=6

    /**
     * @notice
     */
    uint public extraBorrowSupply;  // in usdt, decimals=6

    uint public targetLevRatio; // 1e18

    // Official record of token balances for each account
    mapping (address => uint) internal accountTokens;

    // Approved token transfer amounts on behalf of others
    mapping (address => mapping (address => uint)) internal transferAllowances;

    // usdc decimals is 6
    uint internal constant minTransferAmtUSDC = 50000e6;
    uint internal constant thresholdUSDC = 300000e6;
    uint internal constant extraUSDC = 100000e6;

    struct checkRebalanceRes {
        uint res;
        uint targetLevRatio;
        uint tmpBorrowBalanceUSDC;
        uint tmpTotalAssetValue;
        uint tmpLevRatio;
    }

    uint internal hisHighNav;
    uint internal levReserve;   // 1e6
    uint internal constant redeemFeePC = 1e15;
    uint internal constant perfPC = 1e17;

    uint internal redeemAmountInUSDC;
}

abstract contract LevTokenInterface is LevTokenStorage {
    /**
     * @notice Indicator that this is a LevToken contract (for inspection)
     */
    bool public constant isLevToken = true;


    /*** Market Events ***/

    /**
     * @notice Event emitted when tokens are minted
     */
    event Mint(address minter, uint mintAmount, uint mintTokens, uint nav);

    /**
     * @notice Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint redeemAmount, uint redeemTokens, uint nav);

    /**
     * @notice Event emitted when forceRepay is triggered
     */
    event ForceRepay(address forcer, uint repayAmount);


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
     * @notice Event emitted when tensorpricer is changed
     */
    event NewTensorpricer(TensorpricerInterface oldTensorpricer, TensorpricerInterface newTensorpricer);

    /**
     * @notice EIP20 Transfer event
     */
    event Transfer(address indexed from, address indexed to, uint amount);

    /**
     * @notice EIP20 Approval event
     */
    event Approval(address indexed owner, address indexed spender, uint amount);

    /**
     * @notice Event emitted when the reserves are reduced
     */
    event ReservesReduced(address admin, uint reduceAmount, uint newLevReserve);

    /*** User Interface ***/

    function transfer(address dst, uint amount) virtual external returns (bool);
    function transferFrom(address src, address dst, uint amount) virtual external returns (bool);
    function approve(address spender, uint amount) virtual external returns (bool);
    function allowance(address owner, address spender) virtual external view returns (uint);
    function balanceOf(address owner) virtual external view returns (uint);
    function getNAV(address owner) virtual external view returns (uint);
    function getAccountSnapshot(address account) virtual external view returns (uint, uint);
    function getCash() virtual external view returns (uint);
    function getCompoundBalance() virtual external view returns (uint);
    function getLevReserve() virtual external view returns (uint);
    function getHisHighNav() virtual external view returns (uint);
    
    /*** Admin Functions ***/

    function _setPendingAdmin(address payable newPendingAdmin) virtual external returns (uint);
    function _acceptAdmin() virtual external returns (uint);
    function _setTensorpricer(TensorpricerInterface newTensorpricer) virtual external returns (uint);
    function _reduceReserves(uint reduceAmount) virtual external returns (uint);
}

contract LevErc20Storage {
    /**
     * @notice Underlying asset for this LevToken
     */
    address public underlying;  // USDC
    address public borrowUnderlying;    // USDT
}

abstract contract LevErc20Interface is LevErc20Storage {

    /*** User Interface ***/

    function getAdmin() virtual external returns (address payable);
    function mint(uint mintAmount) virtual external returns (uint);
    function redeem(uint redeemTokens) virtual external returns (uint);
    function sweepToken(EIP20NonStandardInterface token) virtual external;
    function getExtraBorrowDemand() virtual external view returns (uint256);
    function getExtraBorrowSupply() virtual external view returns (uint256);
    function forceRepay(uint256 repayAmount) virtual external returns (uint);
    function updateLedger() virtual external;
}