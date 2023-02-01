pragma solidity =0.5.16;

import "./interfaces/IFactory.sol";
import "./interfaces/IBDeployer.sol";
import "./interfaces/IBorrowable.sol";
import "./interfaces/ICDeployer.sol";
import "./interfaces/ICollateral.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IBaseV1Pair.sol";
import "./interfaces/ITarotSolidlyPriceOracleV2.sol";

contract Factory is IFactory {
    address public admin;
    address public pendingAdmin;
    address public reservesAdmin;
    address public reservesPendingAdmin;
    address public reservesManager;

    struct LendingPool {
        bool initialized;
        uint24 lendingPoolId;
        address collateral;
        address borrowable0;
        address borrowable1;
    }
    mapping(address => LendingPool) public getLendingPool; // get by UniswapV2Pair
    address[] public allLendingPools; // address of the UniswapV2Pair

    function allLendingPoolsLength() external view returns (uint256) {
        return allLendingPools.length;
    }

    IBDeployer public bDeployer;
    ICDeployer public cDeployer;
    ITarotSolidlyPriceOracleV2 public tarotPriceOracle;

    event LendingPoolInitialized(
        address indexed uniswapV2Pair,
        address indexed token0,
        address indexed token1,
        address collateral,
        address borrowable0,
        address borrowable1,
        uint256 lendingPoolId
    );
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);
    event NewAdmin(address oldAdmin, address newAdmin);
    event NewReservesPendingAdmin(
        address oldReservesPendingAdmin,
        address newReservesPendingAdmin
    );
    event NewReservesAdmin(address oldReservesAdmin, address newReservesAdmin);
    event NewReservesManager(
        address oldReservesManager,
        address newReservesManager
    );

    constructor(
        address _admin,
        address _reservesAdmin,
        IBDeployer _bDeployer,
        ICDeployer _cDeployer,
        ITarotSolidlyPriceOracleV2 _tarotPriceOracle
    ) public {
        admin = _admin;
        reservesAdmin = _reservesAdmin;
        bDeployer = _bDeployer;
        cDeployer = _cDeployer;
        tarotPriceOracle = _tarotPriceOracle;
        emit NewAdmin(address(0), _admin);
        emit NewReservesAdmin(address(0), _reservesAdmin);
    }

    function _getTokens(address uniswapV2Pair)
        private
        view
        returns (address token0, address token1)
    {
        token0 = IBaseV1Pair(uniswapV2Pair).token0();
        token1 = IBaseV1Pair(uniswapV2Pair).token1();
    }

    function _createLendingPool(address uniswapV2Pair) private {
        if (getLendingPool[uniswapV2Pair].lendingPoolId != 0) return;
        allLendingPools.push(uniswapV2Pair);
        getLendingPool[uniswapV2Pair] = LendingPool(
            false,
            uint24(allLendingPools.length),
            address(0),
            address(0),
            address(0)
        );
    }

    function createCollateral(address uniswapV2Pair)
        external
        returns (address collateral)
    {
        _getTokens(uniswapV2Pair);
        require(
            getLendingPool[uniswapV2Pair].collateral == address(0),
            "Tarot: ALREADY_EXISTS"
        );
        collateral = cDeployer.deployCollateral(uniswapV2Pair);
        ICollateral(collateral)._setFactory();
        _createLendingPool(uniswapV2Pair);
        getLendingPool[uniswapV2Pair].collateral = collateral;
    }

    function createBorrowable0(address uniswapV2Pair)
        external
        returns (address borrowable0)
    {
        _getTokens(uniswapV2Pair);
        require(
            getLendingPool[uniswapV2Pair].borrowable0 == address(0),
            "Tarot: ALREADY_EXISTS"
        );
        borrowable0 = bDeployer.deployBorrowable(uniswapV2Pair, 0);
        IBorrowable(borrowable0)._setFactory();
        _createLendingPool(uniswapV2Pair);
        getLendingPool[uniswapV2Pair].borrowable0 = borrowable0;
    }

    function createBorrowable1(address uniswapV2Pair)
        external
        returns (address borrowable1)
    {
        _getTokens(uniswapV2Pair);
        require(
            getLendingPool[uniswapV2Pair].borrowable1 == address(0),
            "Tarot: ALREADY_EXISTS"
        );
        borrowable1 = bDeployer.deployBorrowable(uniswapV2Pair, 1);
        IBorrowable(borrowable1)._setFactory();
        _createLendingPool(uniswapV2Pair);
        getLendingPool[uniswapV2Pair].borrowable1 = borrowable1;
    }

    function initializeLendingPool(address uniswapV2Pair) external {
        require(!IBaseV1Pair(uniswapV2Pair).stable(), "Tarot: STABLE");
        (address token0, address token1) = _getTokens(uniswapV2Pair);
        LendingPool memory lPool = getLendingPool[uniswapV2Pair];
        require(!lPool.initialized, "Tarot: ALREADY_INITIALIZED");

        require(
            lPool.collateral != address(0),
            "Tarot: COLLATERALIZABLE_NOT_CREATED"
        );
        require(
            lPool.borrowable0 != address(0),
            "Tarot: BORROWABLE0_NOT_CREATED"
        );
        require(
            lPool.borrowable1 != address(0),
            "Tarot: BORROWABLE1_NOT_CREATED"
        );

        tarotPriceOracle.getResult(uniswapV2Pair);

        ICollateral(lPool.collateral)._initialize(
            "Tarot Collateral",
            "cTAROT",
            uniswapV2Pair,
            lPool.borrowable0,
            lPool.borrowable1
        );
        IBorrowable(lPool.borrowable0)._initialize(
            "Tarot Borrowable",
            "bTAROT",
            token0,
            lPool.collateral
        );
        IBorrowable(lPool.borrowable1)._initialize(
            "Tarot Borrowable",
            "bTAROT",
            token1,
            lPool.collateral
        );

        getLendingPool[uniswapV2Pair].initialized = true;
        emit LendingPoolInitialized(
            uniswapV2Pair,
            token0,
            token1,
            lPool.collateral,
            lPool.borrowable0,
            lPool.borrowable1,
            lPool.lendingPoolId
        );
    }

    function _setPendingAdmin(address newPendingAdmin) external {
        require(msg.sender == admin, "Tarot: UNAUTHORIZED");
        address oldPendingAdmin = pendingAdmin;
        pendingAdmin = newPendingAdmin;
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
    }

    function _acceptAdmin() external {
        require(msg.sender == pendingAdmin, "Tarot: UNAUTHORIZED");
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;
        admin = pendingAdmin;
        pendingAdmin = address(0);
        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, address(0));
    }

    function _setReservesPendingAdmin(address newReservesPendingAdmin)
        external
    {
        require(msg.sender == reservesAdmin, "Tarot: UNAUTHORIZED");
        address oldReservesPendingAdmin = reservesPendingAdmin;
        reservesPendingAdmin = newReservesPendingAdmin;
        emit NewReservesPendingAdmin(
            oldReservesPendingAdmin,
            newReservesPendingAdmin
        );
    }

    function _acceptReservesAdmin() external {
        require(msg.sender == reservesPendingAdmin, "Tarot: UNAUTHORIZED");
        address oldReservesAdmin = reservesAdmin;
        address oldReservesPendingAdmin = reservesPendingAdmin;
        reservesAdmin = reservesPendingAdmin;
        reservesPendingAdmin = address(0);
        emit NewReservesAdmin(oldReservesAdmin, reservesAdmin);
        emit NewReservesPendingAdmin(oldReservesPendingAdmin, address(0));
    }

    function _setReservesManager(address newReservesManager) external {
        require(msg.sender == reservesAdmin, "Tarot: UNAUTHORIZED");
        address oldReservesManager = reservesManager;
        reservesManager = newReservesManager;
        emit NewReservesManager(oldReservesManager, newReservesManager);
    }
}