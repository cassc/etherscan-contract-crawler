//SPDX-License-Identifier: Unlicense
pragma solidity =0.7.6;
pragma abicoder v2;

import "./interfaces/ITidePool.sol";
import "./libraries/TidePoolMath.sol";
import "./libraries/PoolActions.sol";
import "@openzeppelin/contracts/utils/SafeCast.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3MintCallback.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

contract TidePool is ITidePool, IUniswapV3MintCallback, IUniswapV3SwapCallback, ERC20 {

    using SafeCast for uint256;
    using PoolActions for IUniswapV3Pool;

    // amount of acceptable slippage in basis points: > 0 && < 1e6
    uint160 public immutable slippage = 1000;
    // deposits will be prevented if a swap goes over slippage. It will unlock after a rebalance below slippage.
    // users can always withdraw. the locking prevents the system from getting too large for the pool and being eaten by slippage.
    bool public locked;

    address public immutable treasury;
    IUniswapV3Pool public immutable pool;

    // Number of ticks between upper and lower
    int24 public window;
    // limits of the range
    int24 public upper;
    int24 public lower;
    // timestamp of the last rebalance or re-range
    uint256 public lastRebalance;

    address public immutable token0;
    address public immutable token1;

    constructor(IUniswapV3Pool _pool, address _treasury) ERC20("TidePool", "TPOOL") {
        pool = _pool;
        
        lastRebalance = block.timestamp;
        treasury = _treasury;
        int24 tickSpacing = _pool.tickSpacing();
        window = tickSpacing == 200 ? 10 : tickSpacing == 60 ? 30 : 100;
        token0 = _pool.token0();
        token1 = _pool.token1();

        // one-time approval to the Uniswap pool for max values, never rescinded
        TransferHelper.safeApprove(_pool.token0(), address(_pool), type(uint256).max);
        TransferHelper.safeApprove(_pool.token1(), address(_pool), type(uint256).max);
    }

    // Deposit any amount of token0 and token1 into the contract. The contract will perform the swap into the correct ratio and mint liquidity.
    function deposit(uint256 amount0, uint256 amount1) external override returns (uint128 liquidity) {
        require(amount0 > 0 || amount1 > 0, "V");
        require(!locked,"L");

        // harvest rewards and compound to prevent economic exploits
        (uint256 rewards0, uint256 rewards1,,) = harvest();
        pool.mintManagedLiquidity(rewards0, rewards1, lower, upper);

        // pull payment from the user.
        pay(token0, msg.sender, address(this), amount0);
        pay(token1, msg.sender, address(this), amount1);

        if(pool.getPosition(lower, upper) == 0)
            (upper, lower) = TidePoolMath.calculateWindow(pool.getTick(), pool.tickSpacing(), window, 50);

        (uint256 amount0In, uint256 amount1In) = swapIntoRatio(amount0, amount1);

        (liquidity) = pool.mintManagedLiquidity(amount0In, amount1In, lower, upper);
        require(liquidity > 0,"L0");

        // user is given TPOOL tokens to represent their share of the pool
        _mint(msg.sender, liquidity);

        // refund leftover amounts that weren't minted
        (uint256 leftover0, uint256 leftover1) = pool.calculateRefund(liquidity, amount0, amount1, lower, upper);
        pay(token0, address(this), msg.sender, leftover0);
        pay(token1, address(this), msg.sender, leftover1);
        
    }

    // Withdraws managed liquidity for msg.sender. Burns all TPOOL tokens and distributes a percentage of the pool.
    function withdraw() external override {
        uint256 balance = balanceOf(msg.sender);
        require(balance > 0, "B");

        uint128 liquidity = pool.getPosition(lower, upper);
        uint256 total = totalSupply();
        uint256 amount0;
        uint256 amount1;

        if(liquidity > 0) {
            (uint256 rewards0, uint256 rewards1,,) = harvest();

            // compound any leftover rewards back into the pool
            pool.mintManagedLiquidity(rewards0, rewards1, lower, upper);

            // burn liquidity proportial to user's share
            // user liquidity is a simple percentage of total supply
            (amount0, amount1) = pool.burnManagedLiquidity(
                (uint256(pool.getPosition(lower, upper)) * balance / total).toUint128(),
                lower,
                upper);
        }

        uint256 t0 = IERC20(token0).balanceOf(address(this));
        uint256 t1 = IERC20(token1).balanceOf(address(this));

        // distribute share of unminted tokens
        uint256 userTokenShare0 =  t0 * balance / total + amount0;
        uint256 userTokenShare1 =  t1 * balance / total + amount1;

        _burn(msg.sender, balance);

        pay(token0, address(this), msg.sender, userTokenShare0 > t0 ? t0 : userTokenShare0);
        pay(token1, address(this), msg.sender, userTokenShare1 > t1 ? t1 : userTokenShare1);
    }

    function harvest() public returns (uint256 rewards0, uint256 rewards1, uint256 fees0, uint256 fees1) {
        if(totalSupply() == 0) {
            return (rewards0, rewards1, fees0, fees1);
        }
        
        (rewards0, rewards1, fees0, fees1) = pool.harvest(lower, upper);

        pay(token0, address(this), treasury, fees0);
        pay(token1, address(this), treasury, fees1);
    }

    // Given any amount0 and any amount1, swap into the ratio given by the range lower and upper
    function swapIntoRatio(uint256 amount0, uint256 amount1) private returns (uint256 desired0, uint256 desired1) {

        uint256 amountIn;
        uint256 amountOut;
        uint256 leftover;

        // 1) calculate how much liquidity we can generate with what we're given
        (uint256 useable0, uint256 useable1) = pool.getUsableLiquidity(amount0, amount1, lower, upper);

        // 2) swap the leftover tokens into a ratio to maximimze the liquidity we can mint
        // pool.normalizeRange(lower, upper) will return a number from 0-100
        // This is a measure of where tick is in relation to the the upper and lower parts of the range
        // The ratio of token0:token1 will be n:(100-n)
        uint256 n = pool.normalizeRange(lower, upper);

        if(TidePoolMath.zeroIsLessUsed(useable0, amount0, useable1, amount1)) {
            amountIn = (amount0 - useable0) * n / 100;
            
            // corner case where we already have correct ratio and don't need to swap
            if(amountIn > 0) {
                (amountOut, leftover) = pool.swapWithLimit(token0, token1, amountIn, slippage);
                locked = leftover > amountIn * slippage / 1e5 ? true : false;
            }

            desired0 = amount0 - amountIn;
            desired1 = amountOut + amount1;
        } else {
            amountIn = (amount1 - useable1) * (100-n) / 100;
            
            // corner case where we already have correct ratio and don't need to swap
            if(amountIn > 0)  {
                (amountOut, leftover) = pool.swapWithLimit(token1, token0, amountIn, slippage);
                locked = leftover > amountIn * slippage / 1e5 ? true : false;
            }

            desired1 = amount1 - amountIn;
            desired0 = amountOut + amount0;
        }
    }

    function needsRebalance() public view returns (bool) {
        int24 tick = pool.getTick();
        return totalSupply() > 0 && ((tick > upper || tick < lower) || block.timestamp > (lastRebalance + 7 days) || (locked && block.timestamp > (lastRebalance + 1 hours)));
    }

    // A rebalance is when we are out of range, 7+ days have passed, or the pool is locked and +1 hours have passed.
    // We recalculate our position, swap into the correct ratios, and re-mint the position.
    // Designed to be called by anyone.
    function rebalance() external override {
        require(needsRebalance(),"IR");

        // collect rewards and fees
        harvest();

        // get current liquidity and burn it
        pool.burnManagedLiquidity(pool.getPosition(lower, upper), lower, upper);

        // expand the window size by 4 ticks, subtracting 1 tick per day. Safety checks happen in calculateWindow.
        // if we are out of range, we swap to a 50/50 position. If in range, we keep the current ratio.
        int24 tick = pool.getTick();
        window = TidePoolMath.getWindowSize(window, lastRebalance, tick > upper || tick < lower);

        (upper, lower) = TidePoolMath.calculateWindow(
            tick,
            pool.tickSpacing(),
            window,
            50);

        (uint256 desired0, uint256 desired1) = swapIntoRatio(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)));
        
        pool.mintManagedLiquidity(desired0, desired1, lower, upper);
        
        lastRebalance = block.timestamp;
        emit Rebalance();
    }

    /// @inheritdoc IUniswapV3MintCallback
    function uniswapV3MintCallback(uint256 amount0Owed, uint256 amount1Owed, bytes calldata data) external override {
        require(msg.sender == address(pool),"P");
        MintCallbackData memory decoded = abi.decode(data, (MintCallbackData));

        pay(token0, decoded.payer, msg.sender, amount0Owed);
        pay(token1, decoded.payer, msg.sender, amount1Owed);
    }

    /// @inheritdoc IUniswapV3SwapCallback
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata _data) external override {
        require(msg.sender == address(pool),"P");
        require(amount0Delta > 0 || amount1Delta > 0,"Z"); // swaps entirely within 0-liquidity regions are not supported
        SwapCallbackData memory data = abi.decode(_data, (SwapCallbackData));
        
        if(data.zeroForOne) {
            pay(token0, address(this), msg.sender, uint256(amount0Delta));
        } else {
            pay(token1, address(this), msg.sender, uint256(amount1Delta));
        }
    }

    function pay(address token, address payer, address recipient, uint256 value) private {
        if(value > 0) {
            if (payer == address(this)) {
                // pay with tokens already in the contract (for the exact input multihop case)
                TransferHelper.safeTransfer(token, recipient, value);
            } else {
                // pull payment
                TransferHelper.safeTransferFrom(token, payer, recipient, value);
            }
        }
    }
}