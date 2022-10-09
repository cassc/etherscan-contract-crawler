// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../stake/StakeTONStorage.sol";
import "../common/AccessibleCommon.sol";
import "../libraries/FixedPoint96.sol";
import "../libraries/OracleLibrary.sol";
// import "hardhat/console.sol";

interface IQuoter {
     function quoteExactInput(bytes memory path, uint256 amountIn) external returns (uint256 amountOut);
}

interface ITON {
    function approveAndCall(
        address spender,
        uint256 amount,
        bytes memory data
    ) external returns (bool);

}

interface IWTON {

    function swapToTON(uint256 wtonAmount) external returns (bool);
}

interface IIStake1Vault {
    function saleClosed() external view returns (bool);
}

interface IIIDepositManager {

    function pendingUnstaked(address layer2, address account)
        external
        view
        returns (uint256 wtonAmount);

}

interface IISeigManager {
    function stakeOf(address layer2, address account)
        external
        view
        returns (uint256);
}


interface IIUniswapV3Factory {
    function getPool(address,address,uint24) external view returns (address);
}
interface ISelf {
    function isAdmin(address account) external view returns (bool);

    function limitPrameters(
        uint256 amountIn,
        address _pool,
        address token0,
        address token1,
        int24 acceptTickCounts
    ) external view returns  (uint256 amountOutMinimum, uint256 priceLimit, uint160 sqrtPriceX96Limit);

    function acceptMinTick(int24 _tick, int24 _tickSpacings, int24 _acceptTickInterval) external pure returns (int24);
    function acceptMaxTick(int24 _tick, int24 _tickSpacings, int24 _acceptTickInterval) external pure returns (int24);
}

interface IIUniswapV3Pool {

    function token0() external view returns (address);
    function token1() external view returns (address);

    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

}

interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

}
interface IERC20BASE2 {
    function decimals() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external returns (uint256);
}


interface ITokamakRegistry2 {
    function getTokamak()
        external
        view
        returns (
            address,
            address,
            address,
            address,
            address
        );

    function getUniswap()
        external
        view
        returns (
            address,
            address,
            address,
            uint256,
            address
        );
}

/// @title The connector that integrates tokamak
contract TokamakStakeUpgrade5 is
    StakeTONStorage,
    AccessibleCommon
{

    modifier lock() {
        require(_lock == 0, "TokamakStaker:LOCKED");
        _lock = 1;
        _;
        _lock = 0;
    }

    modifier onlyClosed() {
        require(IIStake1Vault(vault).saleClosed(), "TokamakStaker: not closed");
        _;
    }

    /// @dev exchange WTON to TOS using uniswap v3
    /// @param caller the sender
    /// @param amountIn the input amount
    /// @return amountOut the amount of exchanged out token
    event ExchangedWTONtoTOS(
        address caller,
        uint256 amountIn,
        uint256 amountOut
    );


    /// @dev If the tokamak addresses is not set, set the addresses.
    function checkTokamak() public {
        if (ton == address(0)) {
            (
                address _ton,
                address _wton,
                address _depositManager,
                address _seigManager,
                address _swapProxy
            ) = ITokamakRegistry2(stakeRegistry).getTokamak();

            ton = _ton;
            wton = _wton;
            depositManager = _depositManager;
            seigManager = _seigManager;
            swapProxy = _swapProxy;
        }
        require(
            ton != address(0) &&
                wton != address(0) &&
                seigManager != address(0) &&
                depositManager != address(0) &&
                swapProxy != address(0),
            "TokamakStaker:tokamak zero"
        );
    }

    function version() external pure returns (string memory) {
        return "phase1.upgrade.v5";
    }

    function getQuoteAtTick(
        int24 tick,
        uint128 amountIn,
        address baseToken,
        address quoteToken
    ) public pure returns (uint256 amountOut) {
        return OracleLibrary.getQuoteAtTick(tick, amountIn, baseToken, quoteToken);
    }

    function _approveWTON(uint256 amountIn) internal {
        {
            uint256 _amountWTON = IERC20BASE2(wton).balanceOf(address(this));
            uint256 _amountTON = IERC20BASE2(ton).balanceOf(address(this));
            uint256 stakeOf = 0;
            if (tokamakLayer2 != address(0)) {
                stakeOf = IISeigManager(seigManager).stakeOf(
                    tokamakLayer2,
                    address(this)
                );
                stakeOf += (
                    IIIDepositManager(depositManager).pendingUnstaked(
                        tokamakLayer2,
                        address(this)
                    )
                );
            }

            uint256 holdAmount = _amountWTON;
            if (_amountTON > 0) holdAmount = holdAmount + (_amountTON * (10**9));
            require(
                holdAmount >= amountIn,
                "TokamakStaker: wton insufficient"
            );

            if (stakeOf > 0) holdAmount += stakeOf;

            require(
                (holdAmount > totalStakedAmount * (10**9)) &&
                (holdAmount - (totalStakedAmount * (10**9)) >= amountIn),
                "TokamakStaker: insufficient"
            );

            if (_amountWTON < amountIn) {
                bytes memory data = abi.encode(swapProxy, swapProxy);
                require(
                    ITON(ton).approveAndCall(wton, _amountTON, data),
                    "TokamakStaker:exchangeWTONtoTOS approveAndCall fail"
                );
            }
        }
    }

    function swapWtonToTOS() public {
        uint256 _amountWTON = IERC20BASE2(wton).balanceOf(address(this));
        require(_amountWTON > 0, "zero wton balance");
        require(
            IWTON(wton).swapToTON(_amountWTON),
            "TokamakStaker : swapWtonToTOS fail"
        );
    }


    function swapTonToWton() public {
        uint256 _amountTON = IERC20BASE2(ton).balanceOf(address(this));
        require(_amountTON > 0, "zero ton balance");
        bytes memory data = abi.encode(swapProxy, swapProxy);
        require(
            ITON(ton).approveAndCall(wton, _amountTON, data),
            "TokamakStaker : swapTonToWton fail"
        );
    }

    /// @dev exchange holded WTON to TOS using uniswap
    /// @param amountIn the input amount
    function exchangeWTONtoTOS(
        uint256 amountIn
    ) external lock onlyClosed {
        require(amountIn > 0, "zero input amount");
        require(block.number <= endBlock, "TokamakStaker: period end");

        checkTokamak();

        IIUniswapV3Pool pool = IIUniswapV3Pool(getPoolAddress());
        require(address(pool) != address(0), "pool didn't exist");

        (uint160 sqrtPriceX96, int24 tick,,,,,) =  pool.slot0();
        require(sqrtPriceX96 > 0, "pool is not initialized");

        // 오라클 최근 몇 초 동안의 평균가격을 비교할 것인지 , (2분 = 120초)
        int24 timeWeightedAverageTick = OracleLibrary.consult(address(pool), 120);

        // 오라클의 최근 120초 동안의 평균틱과 현재 틱의 허용 범위 ( 1틱 -> 0.6% ) 8틱 -> 4.8%
        require(
            ISelf(address(this)).acceptMinTick(timeWeightedAverageTick, 60, 8) <= tick
            && tick < ISelf(address(this)).acceptMaxTick(timeWeightedAverageTick, 60, 8),
            "It's not allowed changed tick range."
        );

        //스왑시 틱 변경(가격 변경) 허용되는 범위 ( 18 ) -> 10.8%
        (uint256 amountOutMinimum, , uint160 sqrtPriceLimitX96)
            = ISelf(address(this)).limitPrameters(amountIn, address(pool), wton, token, 18);

        _approveWTON(amountIn);

        toUniswapWTON += amountIn;
        (address uniswapRouter, , , uint256 _fee, ) = ITokamakRegistry2(stakeRegistry).getUniswap();
        require(uniswapRouter != address(0), "TokamakStaker:uniswap zero");

        uint256 allowanceAmount = IERC20BASE2(wton).allowance(address(this), uniswapRouter);

        if (allowanceAmount < amountIn) {
            require(
                IERC20BASE2(wton).approve(uniswapRouter, amountIn),
                "TokamakStaker:can't approve uniswapRouter"
            );
        }

        uint256 _amountIn = amountIn;

        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: wton,
                tokenOut: token,
                fee: uint24(_fee),
                recipient: address(this),
                deadline: block.timestamp + 10000,
                amountIn: _amountIn,
                amountOutMinimum: amountOutMinimum,
                sqrtPriceLimitX96: sqrtPriceLimitX96
            });

        uint256 amountOut = ISwapRouter(uniswapRouter).exactInputSingle(params);

        emit ExchangedWTONtoTOS(msg.sender, _amountIn, amountOut);
    }

    function getPoolAddress() public view returns(address) {
        address factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
        return IIUniswapV3Factory(factory).getPool(wton, token, 3000);
    }

    function getDecimals(address token0, address token1) public view returns(uint256 token0Decimals, uint256 token1Decimals) {
        return (IERC20BASE2(token0).decimals(), IERC20BASE2(token1).decimals());
    }

    function getPriceX96FromSqrtPriceX96(uint160 sqrtPriceX96) public pure returns(uint256 priceX96) {
        return FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, FixedPoint96.Q96);
    }

    function getMiniTick(int24 tickSpacings) public pure returns (int24){
           return (TickMath.MIN_TICK / tickSpacings) * tickSpacings ;
    }

    function getMaxTick(int24 tickSpacings) public pure  returns (int24){
           return (TickMath.MAX_TICK / tickSpacings) * tickSpacings ;
    }

    function acceptMinTick(int24 _tick, int24 _tickSpacings, int24 _acceptTickInterval) public pure returns (int24)
    {

        int24 _minTick = getMiniTick(_tickSpacings);
        int24 _acceptMinTick = _tick - (_tickSpacings * _acceptTickInterval);

        if(_minTick < _acceptMinTick) return _acceptMinTick;
        else return _minTick;
    }

    function acceptMaxTick(int24 _tick, int24 _tickSpacings, int24 _acceptTickInterval) public pure returns (int24)
    {
        int24 _maxTick = getMaxTick(_tickSpacings);
        int24 _acceptMinTick = _tick + (_tickSpacings * _acceptTickInterval);

        if(_maxTick < _acceptMinTick) return _maxTick;
        else return _acceptMinTick;
    }

    function limitPrameters(
        uint256 amountIn,
        address _pool,
        address token0,
        address token1,
        int24 acceptTickCounts
    ) public view returns  (uint256 amountOutMinimum, uint256 priceLimit, uint160 sqrtPriceX96Limit)
    {
        IIUniswapV3Pool pool = IIUniswapV3Pool(_pool);
        (, int24 tick,,,,,) =  pool.slot0();

        int24 _tick = tick;
        if(token0 < token1) {
            _tick = tick - acceptTickCounts * 60;
            if(_tick < TickMath.MIN_TICK ) _tick =  TickMath.MIN_TICK ;
        } else {
            _tick = tick + acceptTickCounts * 60;
            if(_tick > TickMath.MAX_TICK ) _tick =  TickMath.MAX_TICK ;
        }
        address token1_ = token1;
        address token0_ = token0;
        return (
              getQuoteAtTick(
                _tick,
                uint128(amountIn),
                token0_,
                token1_
                ),
             getQuoteAtTick(
                _tick,
                uint128(10**27),
                token0_,
                token1_
             ),
             TickMath.getSqrtRatioAtTick(_tick)
        );
    }

}