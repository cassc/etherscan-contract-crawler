// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.7.6;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import './libraries/PathPrice.sol';
import './interfaces/IHotPotV3Fund.sol';
import './interfaces/IHotPot.sol';
import './interfaces/IHotPotV3FundController.sol';
import './base/Multicall.sol';

contract HotPotV3FundController is IHotPotV3FundController, Multicall {
    using Path for bytes;

    address public override immutable uniV3Factory;
    address public override immutable uniV3Router;
    address public override immutable hotpot;
    address public override governance;
    address public override immutable WETH9;
    uint32 maxPIS = (100 << 16) + 9974;// MaxPriceImpact: 1%, MaxSwapSlippage: 0.5% = (1 - (sqrtSlippage/1e4)^2) * 100%

    mapping (address => bool) public override verifiedToken;
    mapping (address => bytes) public override harvestPath;

    modifier onlyManager(address fund){
        require(msg.sender == IHotPotV3Fund(fund).manager(), "OMC");
        _;
    }

    modifier onlyGovernance{
        require(msg.sender == governance, "OGC");
        _;
    }

    modifier checkDeadline(uint deadline) {
        require(block.timestamp <= deadline, 'CDL');
        _;
    }

    constructor(
        address _hotpot,
        address _governance,
        address _uniV3Router,
        address _uniV3Factory,
        address _weth9
    ) {
        hotpot = _hotpot;
        governance = _governance;
        uniV3Router = _uniV3Router;
        uniV3Factory = _uniV3Factory;
        WETH9 = _weth9;
    }

    /// @inheritdoc IControllerState
    function maxPriceImpact() external override view returns(uint32 priceImpact){
        return maxPIS >> 16;
    }

    /// @inheritdoc IControllerState
    function maxSqrtSlippage() external override view returns(uint32 sqrtSlippage){
        return maxPIS & 0xffff;
    }

    /// @inheritdoc IGovernanceActions
    function setHarvestPath(address token, bytes calldata path) external override onlyGovernance {
        bytes memory _path = path;
        while (true) {
            (address tokenIn, address tokenOut, uint24 fee) = _path.decodeFirstPool();

            // pool is exist
            address pool = IUniswapV3Factory(uniV3Factory).getPool(tokenIn, tokenOut, fee);
            require(pool != address(0), "PIE");
            // at least 2 observations
            (,,,uint16 observationCardinality,,,) = IUniswapV3Pool(pool).slot0();
            require(observationCardinality >= 2, "OC");

            if (_path.hasMultiplePools()) {
                _path = _path.skipToken();
            } else {
                //最后一个交易对：输入WETH9, 输出hotpot
                require(tokenIn == WETH9 && tokenOut == hotpot, "IOT");
                break;
            }
        }
        harvestPath[token] = path;
        emit SetHarvestPath(token, path);
    }

    /// @inheritdoc IGovernanceActions
    function setMaxPriceImpact(uint32 priceImpact) external override onlyGovernance {
        require(priceImpact <= 1e4 ,"SPI");
        maxPIS = (priceImpact << 16) | (maxPIS & 0xffff);
        emit SetMaxPriceImpact(priceImpact);
    }

    /// @inheritdoc IGovernanceActions
    function setMaxSqrtSlippage(uint32 sqrtSlippage) external override onlyGovernance {
        require(sqrtSlippage <= 1e4 ,"SSS");
        maxPIS = maxPIS & 0xffff0000 | sqrtSlippage;
        emit SetMaxSqrtSlippage(sqrtSlippage);
    }

    /// @inheritdoc IHotPotV3FundController
    function harvest(address token, uint amount) external override returns(uint burned) {
        bytes memory path = harvestPath[token];
        PathPrice.verifySlippage(path, uniV3Factory, maxPIS & 0xffff);
        uint value = amount <= IERC20(token).balanceOf(address(this)) ? amount : IERC20(token).balanceOf(address(this));
        TransferHelper.safeApprove(token, uniV3Router, value);

        ISwapRouter.ExactInputParams memory args = ISwapRouter.ExactInputParams({
            path: path,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: value,
            amountOutMinimum: 0
        });
        burned = ISwapRouter(uniV3Router).exactInput(args);
        IHotPot(hotpot).burn(burned);
        emit Harvest(token, amount, burned);
    }

    /// @inheritdoc IGovernanceActions
    function setGovernance(address account) external override onlyGovernance {
        require(account != address(0));
        governance = account;
        emit SetGovernance(account);
    }

    /// @inheritdoc IGovernanceActions
    function setVerifiedToken(address token, bool isVerified) external override onlyGovernance {
        verifiedToken[token] = isVerified;
        emit ChangeVerifiedToken(token, isVerified);
    }

    /// @inheritdoc IManagerActions
    function setDescriptor(address fund, bytes calldata _descriptor) external override onlyManager(fund) {
        return IHotPotV3Fund(fund).setDescriptor(_descriptor);
    }

    /// @inheritdoc IManagerActions
    function setDepositDeadline(address fund, uint deadline) external override onlyManager(fund) {
        return IHotPotV3Fund(fund).setDepositDeadline(deadline);
    }

    /// @inheritdoc IManagerActions
    function setPath(
        address fund,
        address distToken,
        bytes memory path
    ) external override onlyManager(fund){
        require(verifiedToken[distToken]);

        address fundToken = IHotPotV3Fund(fund).token();
        bytes memory _path = path;
        bytes memory _reverse;
        (address tokenIn, address tokenOut, uint24 fee) = path.decodeFirstPool();
        _reverse = abi.encodePacked(tokenOut, fee, tokenIn);
        bool isBuy;
        // 第一个tokenIn是基金token，那么就是buy路径
        if(tokenIn == fundToken){
            isBuy = true;
        }
        // 如果是sellPath, 第一个需要是目标代币
        else{
            require(tokenIn == distToken);
        }

        while (true) {
            require(verifiedToken[tokenIn], "VIT");
            require(verifiedToken[tokenOut], "VOT");
            // pool is exist
            address pool = IUniswapV3Factory(uniV3Factory).getPool(tokenIn, tokenOut, fee);
            require(pool != address(0), "PIE");
            // at least 2 observations
            (,,,uint16 observationCardinality,,,) = IUniswapV3Pool(pool).slot0();
            require(observationCardinality >= 2, "OC");

            if (path.hasMultiplePools()) {
                path = path.skipToken();
                (tokenIn, tokenOut, fee) = path.decodeFirstPool();
                _reverse = abi.encodePacked(tokenOut, fee, _reverse);
            } else {
                /// @dev 如果是buy, 最后一个token要是目标代币;
                /// @dev 如果是sell, 最后一个token要是基金token.
                if(isBuy)
                    require(tokenOut == distToken, "OID");
                else
                    require(tokenOut == fundToken, "OIF");
                break;
            }
        }
        if(!isBuy) (_path, _reverse) = (_reverse, _path);
        IHotPotV3Fund(fund).setPath(distToken, _path, _reverse);
    }

    /// @inheritdoc IManagerActions
    function init(
        address fund,
        address token0,
        address token1,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint amount,
        uint deadline
    ) external override checkDeadline(deadline) onlyManager(fund) returns(uint128 liquidity){
        return IHotPotV3Fund(fund).init(token0, token1, fee, tickLower, tickUpper, amount, maxPIS);
    }

    /// @inheritdoc IManagerActions
    function add(
        address fund,
        uint poolIndex,
        uint positionIndex,
        uint amount,
        bool collect,
        uint deadline
    ) external override checkDeadline(deadline) onlyManager(fund) returns(uint128 liquidity){
        return IHotPotV3Fund(fund).add(poolIndex, positionIndex, amount, collect, maxPIS);
    }

    /// @inheritdoc IManagerActions
    function sub(
        address fund,
        uint poolIndex,
        uint positionIndex,
        uint proportionX128,
        uint deadline
    ) external override checkDeadline(deadline) onlyManager(fund) returns(uint amount){
        return IHotPotV3Fund(fund).sub(poolIndex, positionIndex, proportionX128, maxPIS);
    }

    /// @inheritdoc IManagerActions
    function move(
        address fund,
        uint poolIndex,
        uint subIndex,
        uint addIndex,
        uint proportionX128,
        uint deadline
    ) external override checkDeadline(deadline) onlyManager(fund) returns(uint128 liquidity){
        return IHotPotV3Fund(fund).move(poolIndex, subIndex, addIndex, proportionX128, maxPIS);
    }
}