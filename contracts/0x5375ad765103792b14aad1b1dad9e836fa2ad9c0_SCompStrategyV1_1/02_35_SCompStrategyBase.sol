// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./abstract/BaseStrategy.sol";
import "./utility/TokenSwapPathRegistry.sol";
import "../utility/uniswap/UniswapSwapper.sol";
import "../utility/interface/IBooster.sol";
import "../utility/interface/IBaseRewardsPool.sol";
import "../utility/StableMath.sol";
import "../oracle/OracleRouter.sol";
import "../utility/interface/IBasicToken.sol";
import "../utility/curve/CurveSwapper.sol";

pragma experimental ABIEncoderV2;


/*
Version 1.0:
    - Amount out min calculate with previous balance check
*/
abstract contract SCompStrategyBase is
BaseStrategy,
CurveSwapper,
UniswapSwapper
{

    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    using StableMath for uint256;

    // ===== Token Registry =====
    address public constant crv = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address public constant cvx = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;

    IERC20 public constant crvToken =
    IERC20(crv);
    IERC20 public constant cvxToken =
    IERC20(cvx);

    // ===== Convex Registry =====
    IBooster public constant booster =
    IBooster(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);
    IBaseRewardsPool public baseRewardsPool;

    uint256 public constant MAX_UINT_256 = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    uint256 public pid;
    address public tokenCompoundAddress;
    IERC20 public tokenCompound;

    mapping(address => bool) public whitelistRouter;

    uint256 public slippageSwapCrv = 100; // 5000 -> 50% ; 500 -> 5% ; 50 -> 0.5% ; 5 -> 0.05%
    uint256 public slippageSwapCvx = 100; // 5000 -> 50% ; 500 -> 5% ; 50 -> 0.5% ; 5 -> 0.05%

    uint256 public slippageLiquidity = 100; // 5000 -> 50% ; 500 -> 5% ; 50 -> 0.5% ; 5 -> 0.05%

    address oracleRouter;

    struct CurvePoolConfig {
        address swap;
        uint256 tokenCompoundPosition;
        uint256 numElements;
    }

    struct ParamsSwapHarvest {
        bytes[] listPathData;
        uint[] listTypeSwap;
        address[] listRouterAddress;
    }

    CurvePoolConfig public curvePool;

    string nameStrategy;

    event PerformanceFeeGovernance(
        address indexed destination,
        address indexed token,
        uint256 amount,
        uint256 indexed blockNumber,
        uint256 timestamp
    );
    event PerformanceFeeStrategist(
        address indexed destination,
        address indexed token,
        uint256 amount,
        uint256 indexed blockNumber,
        uint256 timestamp
    );

    event WithdrawState(
        uint256 toWithdraw,
        uint256 preWant,
        uint256 postWant,
        uint256 withdrawn
    );

    struct TendData {
        uint256 crvTended;
        uint256 cvxTended;
    }

    event TendState(uint crvTended, uint cvxTended);

    /**
     * @param _nameStrategy name string of strategy
     * @param _governance is authorized actors, authorized pauser, can call earn, can set params strategy, receive fee harvest
     * @param _strategist receive fee compound
     * @param _want address lp to deposit
     * @param _tokenCompound address token to compound
     * @param _pid id of pool in convex booster
     * @param _feeConfig performanceFee governance e strategist + fee withdraw
     * @param _curvePool curve pool config
     */
    constructor(
        string memory _nameStrategy,
        address _governance,
        address _strategist,
        address _controller,
        address _want,
        address _tokenCompound,
        uint256 _pid,
        uint256[3] memory _feeConfig,
        CurvePoolConfig memory _curvePool
    ) BaseStrategy(_governance, _strategist, _controller) {

        nameStrategy = _nameStrategy;

        want = _want;

        pid = _pid; // Core staking pool ID

        IBooster.PoolInfo memory poolInfo = booster.poolInfo(pid);
        baseRewardsPool = IBaseRewardsPool(poolInfo.crvRewards);

        performanceFeeGovernance = _feeConfig[0];
        performanceFeeStrategist = _feeConfig[1];
        withdrawalFee = _feeConfig[2];

        tokenCompoundAddress = _tokenCompound;
        tokenCompound = IERC20(_tokenCompound);

        // Approvals: Staking Pools
        IERC20(want).approve(address(booster), MAX_UINT_256);

        curvePool = CurvePoolConfig(
            _curvePool.swap,
            _curvePool.tokenCompoundPosition,
            _curvePool.numElements
        );
    }

    function version() virtual external pure returns (string memory);

    function _setOracleRouter(address _router) internal {
        oracleRouter = _router;
    }

    /**
     * @dev add router to whitelist
     * Requirements:
     *
     * - router must be not already whitelist.
     */
    function _addWhitelistRouter(address _address) public virtual {
        require(!isWhitelistedRouter(_address), "already whitelisted");

        whitelistRouter[_address] = true;
    }

    /**
     * @dev remove router to whitelist
     * Requirements:
     *
     * - router must be whitelist.
     */
    function _removeWhitelistRouter(address _address) public virtual {
        require(isWhitelistedRouter(_address), "not whitelisted");

        whitelistRouter[_address] = false;
    }


    function _getAmountOutMinAddLiquidity(uint _amount) virtual public view returns(uint);

    function getName() external view override returns (string memory) {
        return nameStrategy;
    }

    function approveForAll() external {
        // Approvals: Staking Pools
        IERC20(want).approve(address(booster), MAX_UINT_256);
    }

    /// ===== Permissioned Functions =====
    function setPid(uint256 _pid) external {
        _onlyGovernance();
        pid = _pid; // LP token pool ID
    }

    function setCurvePoolSwap(CurvePoolConfig memory _curvePool) external {
        _onlyGovernance();
        curvePool = CurvePoolConfig(
                _curvePool.swap,
                _curvePool.tokenCompoundPosition,
                _curvePool.numElements
        );
    }

    function setTokenCompound(address _tokenCompound, uint _tokenCompoundPosition) external {
        _onlyGovernance();
        tokenCompoundAddress = _tokenCompound;
        tokenCompound = IERC20(_tokenCompound);
        curvePool.tokenCompoundPosition = _tokenCompoundPosition;

    }

    function setOracleRouter(address _router) external {
        _onlyGovernance();
        _setOracleRouter(_router);
    }

    function addWhitelistRouter(address _address) external {
        _onlyGovernance();
        _addWhitelistRouter(_address);
    }

    function removeWhitelistRouter(address _address) external {
        _onlyGovernance();
        _removeWhitelistRouter(_address);
    }

    /**
     * @dev check if router is whitelisted
     */
    function isWhitelistedRouter(address _address) public view returns(bool) {
        return whitelistRouter[_address];
    }

    function setSlippageSwapCrv(uint _slippage) external {
        _onlyGovernance();
        require(_slippage <= PRECISION, "slippage must be less than PRECISION");
        slippageSwapCrv = _slippage;
    }

    function setSlippageSwapCvx(uint _slippage) external {
        _onlyGovernance();
        require(_slippage <= PRECISION, "slippage must be less than PRECISION");
        slippageSwapCvx = _slippage;
    }

    function setSlippageLiquidity(uint _slippage) external {
        _onlyGovernance();
        require(_slippage <= PRECISION, "slippage must be less than PRECISION");
        slippageLiquidity = _slippage;
    }

    function balanceOfPool() public view override returns (uint256) {
        return baseRewardsPool.balanceOf(address(this));
    }

    /// ===== Internal Core Implementations =====
    function _onlyNotProtectedTokens(address _asset) internal view override {
        require(address(want) != _asset, "want");
        require(address(crv) != _asset, "crv");
        require(address(cvx) != _asset, "cvx");
    }

    /// @dev Deposit Badger into the staking contract
    function _deposit(uint256 _want) internal override {
        // Deposit all want in core staking pool
        booster.deposit(pid, _want, true);
    }

    /// @dev Unroll from all strategy positions, and transfer non-core tokens to controller rewards
    function _withdrawAll() internal override {
        baseRewardsPool.withdrawAndUnwrap(balanceOfPool(), false);
        // Note: All want is automatically withdrawn outside this "inner hook" in base strategy function
    }

    /// @dev Withdraw want from staking rewards, using earnings first
    function _withdrawSome(uint256 _amount)
    internal
    override
    returns (uint256)
    {
        // Get idle want in the strategy
        uint256 _preWant = IERC20(want).balanceOf(address(this));

        // If we lack sufficient idle want, withdraw the difference from the strategy position
        if (_preWant < _amount) {
            uint256 _toWithdraw = _amount.sub(_preWant);
            baseRewardsPool.withdrawAndUnwrap(_toWithdraw, false);
        }

        // Confirm how much want we actually end up with
        uint256 _postWant = IERC20(want).balanceOf(address(this));

        // Return the actual amount withdrawn if less than requested
        uint256 _withdrawn = Math.min(_postWant, _amount);
        emit WithdrawState(_amount, _preWant, _postWant, _withdrawn);

        return _withdrawn;
    }

    function _tendGainsFromPositions() internal {
        // Harvest CRV from staking positions
        // Note: Always claim extras
        baseRewardsPool.getReward(address(this), true);
    }

    function _takeFeeAutoCompounded(address _tokenAddress, uint _amount) internal returns(uint) {
        // take fee
        uint256 autoCompoundedPerformanceFeeGovernance;
        if(performanceFeeGovernance > 0) {
            autoCompoundedPerformanceFeeGovernance =
            _amount.mul(performanceFeeGovernance).div(
                PRECISION
            );
            IERC20(_tokenAddress).transfer(
                governance,
                autoCompoundedPerformanceFeeGovernance
            );
            emit PerformanceFeeGovernance(
                governance,
                _tokenAddress,
                autoCompoundedPerformanceFeeGovernance,
                block.number,
                block.timestamp
            );
        }
        uint256 autoCompoundedPerformanceFeeStrategist;
        if(performanceFeeStrategist > 0) {
            autoCompoundedPerformanceFeeStrategist =
            _amount.mul(performanceFeeStrategist).div(
                PRECISION
            );
            IERC20(_tokenAddress).transfer(
                strategist,
                autoCompoundedPerformanceFeeStrategist
            );
            emit PerformanceFeeStrategist(
                strategist,
                _tokenAddress,
                autoCompoundedPerformanceFeeStrategist,
                block.number,
                block.timestamp
            );
        }

        return autoCompoundedPerformanceFeeStrategist + autoCompoundedPerformanceFeeGovernance;

    }

    /// @notice The more frequent the tend, the higher returns will be
    function tend() external whenNotPaused returns (TendData memory) {
        TendData memory tendData;

        // 1. Harvest gains from positions
        _tendGainsFromPositions();

        // Track harvested coins, before conversion
        tendData.crvTended = crvToken.balanceOf(address(this));
        tendData.cvxTended = cvxToken.balanceOf(address(this));

        emit Tend(0);
        emit TendState(
            tendData.crvTended,
            tendData.cvxTended
        );
        return tendData;
    }

    function harvest(ParamsSwapHarvest memory paramsSwap) external whenNotPaused returns (uint256) {
        uint256 idleWant = IERC20(want).balanceOf(address(this));
        uint256 totalWantBefore = balanceOf();

        // 1. Withdraw accrued rewards from staking positions (claim unclaimed positions as well)
        baseRewardsPool.getReward(address(this), true);

        // 2. Sell reward - fee for underlying
        uint crvToSell = crvToken.balanceOf(address(this));
        if(crvToSell > 0)  {
            uint fee = _takeFeeAutoCompounded(crv, crvToSell);
            crvToSell = crvToSell.sub(fee);

            _makeSwap(crv, tokenCompoundAddress, crvToSell,
                paramsSwap.listTypeSwap[0], paramsSwap.listRouterAddress[0], paramsSwap.listPathData[0]);
        }

        uint cvxToSell = cvxToken.balanceOf(address(this));
        if(cvxToSell > 0)  {
            uint fee = _takeFeeAutoCompounded(cvx, cvxToSell);
            cvxToSell = cvxToSell.sub(fee);

            _makeSwap(cvx, tokenCompoundAddress, cvxToSell,
                paramsSwap.listTypeSwap[1], paramsSwap.listRouterAddress[1], paramsSwap.listPathData[1]);
        }

        // 4. Roll Want gained into want position
        uint256 tokenCompoundToDeposit = tokenCompound.balanceOf(address(this));
        uint256 wantGained;

        if (tokenCompoundToDeposit > 0) {

            _addLiquidityCurve(tokenCompoundToDeposit);

            wantGained = IERC20(want).balanceOf(address(this)).sub(idleWant);
        }

        // Deposit remaining want (including idle want) into strategy position
        uint256 wantToDeposited = IERC20(want).balanceOf(address(this));

        if (wantToDeposited > 0) {
            _deposit(wantToDeposited);
        }

        uint256 totalWantAfter = balanceOf();
        require(totalWantAfter >= totalWantBefore, "want-decreased");

        emit Harvest(wantGained, block.number);
        return wantGained;
    }

    function _addLiquidityCurve(uint _amount) internal {
        uint minLpOutput = _getAmountOutMinAddLiquidity(_amount);

        _add_liquidity_single_coin(
            curvePool.swap,
            tokenCompoundAddress,
            _amount,
            curvePool.tokenCompoundPosition,
            curvePool.numElements,
            minLpOutput
        );
    }

    function _makeSwap(address _tokenIn, address _tokenOut, uint _amountIn, uint _swapType, address _router, bytes memory _pathData) internal {
        require(isWhitelistedRouter(_router), "_router is not whitelisted");
        uint amountOutMin = _getAmountOutMinSwap(_tokenIn, _tokenOut, _amountIn);
        if(_swapType == 0) {
            _swapExactTokensForTokens(_router, _tokenIn, _amountIn, amountOutMin, _pathData, address(this));
        } else if(_swapType == 1) {
            _swapExactInputMultihop(_router, _tokenIn, _amountIn, amountOutMin, _pathData, address(this));
        } else {
            _exchange_multiple(_router, _tokenIn, _amountIn, amountOutMin, _pathData, address(this));
        }
    }

    function _getAmountOutMinSwap(address _tokenIn, address _tokenOut, uint _amountIn) public view returns(uint){
        uint slippageTokenOut = _tokenIn == crv ? slippageSwapCrv : slippageSwapCvx;
        (uint tokenInPrice, ) = OracleRouter(oracleRouter).price(_tokenIn);
        (uint tokenOutPrice, ) = OracleRouter(oracleRouter).price(_tokenOut);
        // sanitary check
        if(tokenOutPrice == 0 ) {
            return 0;
        }

        uint amountOutMin = _amountIn * tokenInPrice / tokenOutPrice;
        uint decimalsTokenIn = IBasicToken(_tokenIn).decimals();
        uint decimalsTokenOut = IBasicToken(_tokenOut).decimals();
        amountOutMin = amountOutMin.scaleBy(decimalsTokenOut, decimalsTokenIn);
        amountOutMin -= amountOutMin.mul(slippageTokenOut).div(PRECISION);
        return amountOutMin.mulTruncate(uint256(1e18));
    }

}