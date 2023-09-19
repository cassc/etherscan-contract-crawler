// SPDX-License-Identifier: -- WISE --

pragma solidity =0.8.21;

import "./InterfaceHub/IWETH.sol";
import "./InterfaceHub/IPositionNFTs.sol";
import "./InterfaceHub/IWiseSecurity.sol";
import "./InterfaceHub/IWiseOracleHub.sol";
import "./InterfaceHub/IFeeManagerLight.sol";

import "./OwnableMaster.sol";

error InvalidCaller();
error AlreadyCreated();
error PositionLocked();
error ForbiddenValue();
error ParametersLocked();
error DepositCapReached();
error CollateralTooSmall();

contract WiseLendingDeclaration is OwnableMaster {

    event FundsDeposited(
        address indexed sender,
        uint256 indexed nftId,
        address indexed token,
        uint256 amount,
        uint256 shares,
        uint256 timestamp
    );

    event FundsSolelyDeposited(
        address indexed sender,
        uint256 indexed nftId,
        address indexed token,
        uint256 amount,
        uint256 timestamp
    );

    event FundsWithdrawn(
        address indexed sender,
        uint256 indexed nftId,
        address indexed token,
        uint256 amount,
        uint256 shares,
        uint256 timestamp
    );

    event FundsWithdrawnOnBehalf(
        address indexed sender,
        uint256 indexed nftId,
        address indexed token,
        uint256 amount,
        uint256 shares,
        uint256 timestamp
    );

    event FundsSolelyWithdrawn(
        address indexed sender,
        uint256 indexed nftId,
        address indexed token,
        uint256 amount,
        uint256 timestamp
    );

    event FundsSolelyWithdrawnOnBehalf(
        address indexed sender,
        uint256 indexed nftId,
        address indexed token,
        uint256 amount,
        uint256 timestamp
    );

    event FundsBorrowed(
        address indexed borrower,
        uint256 indexed nftId,
        address indexed token,
        uint256 amount,
        uint256 shares,
        uint256 timestamp
    );

    event FundsBorrowedOnBehalf(
        address indexed sender,
        uint256 indexed nftId,
        address indexed token,
        uint256 amount,
        uint256 shares,
        uint256 timestamp
    );

    event FundsReturned(
        address indexed sender,
        address indexed token,
        uint256 indexed nftId,
        uint256 totalPayment,
        uint256 totalPaymentShares,
        uint256 timestamp
    );

    event FundsReturnedWithLendingShares(
        address indexed sender,
        address indexed token,
        uint256 indexed nftId,
        uint256 totalPayment,
        uint256 totalPaymentShares,
        uint256 timestamp
    );

    event Approve(
        address indexed sender,
        address indexed token,
        address indexed user,
        uint256 amount,
        uint256 timestamp
    );

    event PoolSynced(
        address pool,
        uint256 timestamp
    );

    event RegisteredForIsolationPool(
        address user,
        uint256 timestamp,
        bool registration
    );

    constructor(
        address _master,
        address _wiseOracleHub,
        address _nftContract,
        address _wethContract
    )
        OwnableMaster(
            _master
        )
    {
        WETH_ADDRESS = _wethContract;

        WETH = IWETH(
            _wethContract
        );

        WISE_ORACLE = IWiseOracleHub(
            _wiseOracleHub
        );

        POSITION_NFT = IPositionNFTs(
            _nftContract
        );
    }

    function setSecurity(
        address _wiseSecurity
    )
        external
        onlyMaster
    {
        WISE_SECURITY = IWiseSecurity(
            _wiseSecurity
        );

        FEE_MANAGER = IFeeManagerLight(
            WISE_SECURITY.FEE_MANAGER()
        );

        AAVE_HUB = WISE_SECURITY.AAVE_HUB();
    }

    /**
     * @dev Wrapper for wrapping
     * ETH call.
     */
    function _wrapETH(
        uint256 _value
    )
        internal
    {
        WETH.deposit{
            value: _value
        }();
    }

    /**
     * @dev Wrapper for unwrapping
     * ETH call.
     */
    function _unwrapETH(
        uint256 _value
    )
        internal
    {
        WETH.withdraw(
            _value
        );
    }

    // Variables -----------------------------------------

    // Aave address
    address public AAVE_HUB;

    // Wrapped ETH address
    address public immutable WETH_ADDRESS;

    // Nft id for feeManager
    uint256 constant FEE_MANAGER_NFT = 0;


    // Interfaces -----------------------------------------

    // Wrapped ETH interface
    IWETH immutable WETH;

    // WiseSecurity interface
    IWiseSecurity public WISE_SECURITY;

    // FeeManager interface
    IFeeManagerLight public FEE_MANAGER;

    // NFT contract interface for positions
    IPositionNFTs public immutable POSITION_NFT;

    // OraceHub interface
    IWiseOracleHub public immutable WISE_ORACLE;

    // Structs ------------------------------------------

    struct LendingEntry {
        uint256 shares;
        bool deCollteralized;
    }

    struct BorrowRatesEntry {
        uint256 pole;
        uint256 deltaPole;
        uint256 minPole;
        uint256 maxPole;
        uint256 multiplicativeFactor;
    }

    struct AlgorithmEntry {
        uint256 bestPole;
        uint256 maxValue;
        uint256 previousValue;
        bool increasePole;
    }

    struct GlobalPoolEntry {
        uint256 totalPool;
        uint256 utilization;
        uint256 totalBareToken;
        uint256 poolFee;
    }

    struct LendingPoolEntry {
        uint256 pseudoTotalPool;
        uint256 totalDepositShares;
        uint256 collateralFactor;
    }

    struct BorrowPoolEntry {
        bool allowBorrow;
        uint256 pseudoTotalBorrowAmount;
        uint256 totalBorrowShares;
        uint256 borrowRate;
    }

    struct TimestampsPoolEntry {
        uint256 timeStamp;
        uint256 timeStampScaling;
    }

    // Position mappings ------------------------------------------
    mapping(address => uint256) bufferIncrease;
    mapping(address => uint256) public maxDepositValueToken;

    mapping(uint256 => address[]) public positionBorrowTokenData;
    mapping(uint256 => address[]) public positionLendingTokenData;

    mapping(uint256 => mapping(address => uint256)) public userBorrowShares;
    mapping(uint256 => mapping(address => LendingEntry)) public userLendingData;
    mapping(uint256 => mapping(address => uint256)) public positionPureCollateralAmount;

    // Owner -> PoolToken -> Spender -> Allowance Value
    mapping(address => mapping(address => mapping(address => uint256))) public allowance;

    // Struct mappings -------------------------------------
    mapping(address => BorrowRatesEntry) public borrowRatesData;
    mapping(address => AlgorithmEntry) public algorithmData;
    mapping(address => GlobalPoolEntry) public globalPoolData;
    mapping(address => LendingPoolEntry) public lendingPoolData;
    mapping(address => BorrowPoolEntry) public borrowPoolData;
    mapping(address => TimestampsPoolEntry) public timestampsPoolData;

    // Bool mappings -------------------------------------
    mapping(uint256 => bool) public positionLocked;
    mapping(address => bool) public parametersLocked;
    mapping(address => bool) public veryfiedIsolationPool;

    // Hash mappings -------------------------------------
    mapping(bytes32 => bool) hashMapPositionBorrow;
    mapping(bytes32 => bool) hashMapPositionLending;

    // PRECISION FACTORS ------------------------------------
    uint256 constant PRECISION_FACTOR_E16 = 1E16;
    uint256 constant PRECISION_FACTOR_E18 = 1E18;
    uint256 constant PRECISION_FACTOR_E36 = PRECISION_FACTOR_E18 * PRECISION_FACTOR_E18;

    // TIME CONSTANTS --------------------------------------
    uint256 constant ONE_YEAR = 52 weeks;
    uint256 constant THREE_HOURS = 3 hours;
    uint256 constant PRECISION_FACTOR_E18_YEAR = PRECISION_FACTOR_E18 * ONE_YEAR;

    // Two months in seconds:
    // Norming change in pole value that it steps from min to max value
    // within two month (if nothing changes)
    uint256 constant NORMALISATION_FACTOR = 4838400;

    // LASA CONSTANTS -------------------------
    uint256 constant THRESHOLD_SWITCH_DIRECTION = 90 * PRECISION_FACTOR_E16;
    uint256 constant THRESHOLD_RESET_RESONANCE_FACTOR = 75 * PRECISION_FACTOR_E16;
}