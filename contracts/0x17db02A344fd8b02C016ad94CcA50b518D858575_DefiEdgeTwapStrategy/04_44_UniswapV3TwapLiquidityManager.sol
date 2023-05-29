//SPDX-License-Identifier: BSL
pragma solidity ^0.7.6;
pragma abicoder v2;

// contracts
import "@openzeppelin/contracts/utils/SafeCast.sol";
import "./TwapStrategyBase.sol";

// interfaces
import "../../libraries/LiquidityHelper.sol";
import "../../libraries/OneInchHelper.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "../../interfaces/IOneInch.sol";

// libraries
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3MintCallback.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract UniswapV3TwapLiquidityManager is TwapStrategyBase, ReentrancyGuard, IUniswapV3MintCallback {
    using SafeMath for uint256;
    using SafeCast for uint256;
    using SafeERC20 for IERC20;

    event Swap(uint256 amountIn, uint256 amountOut, bool _zeroForOne);

    event FeesClaim(address indexed strategy, uint256 amount0, uint256 amount1);

    struct MintCallbackData {
        address payer;
        IUniswapV3Pool pool;
    }

    // to handle stake too deep error inside swap function
    struct LocalVariables_Balances {
        uint256 tokenInBalBefore;
        uint256 tokenOutBalBefore;
        uint256 tokenInBalAfter;
        uint256 tokenOutBalAfter;
        uint256 shareSupplyBefore;
    }

    /**
     * @notice Mints liquidity from V3 Pool
     * @param _tickLower Lower tick
     * @param _tickUpper Upper tick
     * @param _amount0 Amount of token0
     * @param _amount1 Amount of token1
     * @param _payer Address which is adding the liquidity
     */
    function mintLiquidity(
        int24 _tickLower,
        int24 _tickUpper,
        uint256 _amount0,
        uint256 _amount1,
        address _payer
    ) internal returns (uint256 amount0, uint256 amount1) {
        uint128 liquidity = LiquidityHelper.getLiquidityForAmounts(pool, _tickLower, _tickUpper, _amount0, _amount1);
        // add liquidity to Uniswap pool
        (amount0, amount1) = pool.mint(
            address(this),
            _tickLower,
            _tickUpper,
            liquidity,
            abi.encode(MintCallbackData({payer: _payer, pool: pool}))
        );
    }

    /**
     * @notice Burns liquidity in the given range
     * @param _tickLower Lower Tick
     * @param _tickUpper Upper Tick
     * @param _shares The amount of liquidity to be burned based on shares
     */
    function burnLiquidity(
        int24 _tickLower,
        int24 _tickUpper,
        uint256 _shares,
        uint128 _currentLiquidity
    )
        internal
        returns (
            uint256 tokensBurned0,
            uint256 tokensBurned1,
            uint256 fee0,
            uint256 fee1
        )
    {
        uint256 collect0;
        uint256 collect1;

        if (_shares > 0) {
            (_currentLiquidity, , , , ) = pool.positions(PositionKey.compute(address(this), _tickLower, _tickUpper));
            if (_currentLiquidity > 0) {
                uint256 liquidity = FullMath.mulDiv(_currentLiquidity, _shares, totalSupply());

                (tokensBurned0, tokensBurned1) = pool.burn(_tickLower, _tickUpper, liquidity.toUint128());
            }
        } else {
            (tokensBurned0, tokensBurned1) = pool.burn(_tickLower, _tickUpper, _currentLiquidity);
        }
        // collect fees
        (collect0, collect1) = pool.collect(address(this), _tickLower, _tickUpper, type(uint128).max, type(uint128).max);

        fee0 = collect0 > tokensBurned0 ? uint256(collect0).sub(tokensBurned0) : 0;
        fee1 = collect1 > tokensBurned1 ? uint256(collect1).sub(tokensBurned1) : 0;
    }

    /**
     * @notice Splits and transfers the performance fee
     * @param _fee0 Amount of accumulated fee for token0
     * @param _fee1 Amount of accumulated fee for token1
     */
    function _transferPerformanceFees(uint256 _fee0, uint256 _fee1) internal {
        (
            address managerFeeTo,
            address protocolFeeTo,
            uint256 managerToken0Amount,
            uint256 managerToken1Amount,
            uint256 protocolToken0Amount,
            uint256 protocolToken1Amount
        ) = TwapShareHelper.calculateFeeTokenShares(factory, manager, _fee0, _fee1);

        if (managerToken0Amount > 0) {
            TransferHelper.safeTransfer(address(token0), managerFeeTo, managerToken0Amount);
        }

        if (managerToken1Amount > 0) {
            TransferHelper.safeTransfer(address(token1), managerFeeTo, managerToken1Amount);
        }

        if (protocolToken0Amount > 0) {
            TransferHelper.safeTransfer(address(token0), protocolFeeTo, protocolToken0Amount);
        }

        if (protocolToken1Amount > 0) {
            TransferHelper.safeTransfer(address(token1), protocolFeeTo, protocolToken1Amount);
        }

        emit FeesClaim(address(this), _fee0, _fee1);
    }

    /**
     * @notice Burns all the liquidity and collects fees
     */
    function burnAllLiquidity() internal returns (uint256 totalFee0, uint256 totalFee1) {
        for (uint256 _tickIndex = 0; _tickIndex < ticks.length; _tickIndex++) {
            Tick storage tick = ticks[_tickIndex];

            (uint128 currentLiquidity, , , , ) = pool.positions(PositionKey.compute(address(this), tick.tickLower, tick.tickUpper));

            if (currentLiquidity > 0) {
                (, , uint256 fee0, uint256 fee1) = burnLiquidity(tick.tickLower, tick.tickUpper, 0, currentLiquidity);
                totalFee0 = totalFee0.add(fee0);
                totalFee1 = totalFee1.add(fee1);
            }
        }
    }

    /**
     * @notice Burn liquidity from specific tick, used for limit orders
     * @param _tickIndex Index of tick which needs to be burned
     * @return amount0 Amount of token0's liquidity burned
     * @return amount1 Amount of token1's liquidity burned
     * @return fee0 Fee of token0 accumulated in the position which is being burned
     * @return fee1 Fee of token1 accumulated in the position which is being burned
     */
    function burnLiquiditySingle(uint256 _tickIndex)
        public
        nonReentrant
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 fee0,
            uint256 fee1
        )
    {
        require(manager.isAllowedToBurn(msg.sender), "N");
        (amount0, amount1, fee0, fee1) = _burnLiquiditySingle(_tickIndex);
        if (fee0 > 0 || fee1 > 0) {
            _transferPerformanceFees(fee0, fee1);
        }

        // shift the index element at last of array
        ticks[_tickIndex] = ticks[ticks.length - 1];
        // remove last element
        ticks.pop();
    }

    /**
     * @notice Burn liquidity from specific tick
     * @param _tickIndex Index of tick which needs to be burned
     */
    function _burnLiquiditySingle(uint256 _tickIndex)
        internal
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 fee0,
            uint256 fee1
        )
    {
        Tick storage tick = ticks[_tickIndex];

        (uint128 currentLiquidity, , , , ) = pool.positions(PositionKey.compute(address(this), tick.tickLower, tick.tickUpper));

        if (currentLiquidity > 0) {
            (amount0, amount1, fee0, fee1) = burnLiquidity(tick.tickLower, tick.tickUpper, 0, currentLiquidity);
        }
    }

    /**
     * @notice Swap the funds to 1Inch
     * @param data Swap data to perform exchange from 1inch
     */
    function swap(bytes calldata data) public onlyOperator onlyValidStrategy nonReentrant {
        _swap(data);
    }

    /**
     * @notice Swap the funds to 1Inch
     * @param data Swap data to perform exchange from 1inch
     */
    function _swap(bytes calldata data) internal {
        LocalVariables_Balances memory balances;

        (IERC20 srcToken, IERC20 dstToken, uint256 amount) = OneInchHelper.decodeData(
            address(factory),
            IERC20(token0),
            IERC20(token1),
            data
        );

        require((srcToken == token0 && dstToken == token1) || (srcToken == token1 && dstToken == token0), "IA");

        balances.tokenInBalBefore = srcToken.balanceOf(address(this));
        balances.tokenOutBalBefore = dstToken.balanceOf(address(this));
        balances.shareSupplyBefore = totalSupply();

        srcToken.safeIncreaseAllowance(address(oneInchRouter), amount);

        // Interact with 1inch through contract call with data
        (bool success, bytes memory returnData) = address(oneInchRouter).call{value: 0}(data);

        // Verify return status and data
        if (!success) {
            uint256 length = returnData.length;
            if (length < 68) {
                // If the returnData length is less than 68, then the transaction failed silently.
                revert("swap");
            } else {
                // Look for revert reason and bubble it up if present
                uint256 t;
                assembly {
                    returnData := add(returnData, 4)
                    t := mload(returnData) // Save the content of the length slot
                    mstore(returnData, sub(length, 4)) // Set proper length
                }
                string memory reason = abi.decode(returnData, (string));
                assembly {
                    mstore(returnData, t) // Restore the content of the length slot
                }
                revert(reason);
            }
        }

        require(balances.shareSupplyBefore == totalSupply(), "MS");

        balances.tokenInBalAfter = srcToken.balanceOf(address(this));
        balances.tokenOutBalAfter = dstToken.balanceOf(address(this));

        uint256 amountIn = balances.tokenInBalBefore.sub(balances.tokenInBalAfter);
        uint256 amountOut = balances.tokenOutBalAfter.sub(balances.tokenOutBalBefore);

        // used to limit number of swaps a manager can do per day
        manager.incrementSwapCounter();

        require(
            TwapOracleLibrary.allowSwap(pool, factory, amountIn, amountOut, address(srcToken), address(dstToken), manager, useTwap),
            "S"
        );
    }

    /**
     * @dev Callback for Uniswap V3 pool.
     */
    function uniswapV3MintCallback(
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external override {
        require(msg.sender == address(pool));
        MintCallbackData memory decoded = abi.decode(data, (MintCallbackData));
        // check if the callback is received from Uniswap V3 Pool
        if (decoded.payer == address(this)) {
            // transfer tokens already in the contract
            if (amount0 > 0) {
                TransferHelper.safeTransfer(address(token0), msg.sender, amount0);
            }
            if (amount1 > 0) {
                TransferHelper.safeTransfer(address(token1), msg.sender, amount1);
            }
        }
    }

    /**
     * @notice Get's assets under management with realtime fees
     * @param _includeFee Whether to include pool fees in AUM or not. (passing true will also collect fees from pool)
     */
    function getAUMWithFees(bool _includeFee)
        external
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 totalFee0,
            uint256 totalFee1
        )
    {
        // get fees accumulated in each tick
        for (uint256 i = 0; i < ticks.length; i++) {
            Tick memory tick = ticks[i];

            // get current liquidity from the pool
            (uint128 currentLiquidity, , , , ) = pool.positions(PositionKey.compute(address(this), tick.tickLower, tick.tickUpper));

            if (currentLiquidity > 0) {
                // calculate current positions in the pool from currentLiquidity
                (uint256 position0, uint256 position1) = LiquidityHelper.getAmountsForLiquidity(
                    pool,
                    tick.tickLower,
                    tick.tickUpper,
                    currentLiquidity
                );

                amount0 = amount0.add(position0);
                amount1 = amount1.add(position1);
            }

            // collect fees
            if (_includeFee && currentLiquidity > 0) {
                // update fees earned in Uniswap pool
                // Uniswap recalculates the fees and updates the variables when amount is passed as 0
                pool.burn(tick.tickLower, tick.tickUpper, 0);

                (uint256 fee0, uint256 fee1) = pool.collect(
                    address(this),
                    tick.tickLower,
                    tick.tickUpper,
                    type(uint128).max,
                    type(uint128).max
                );

                totalFee0 = totalFee0.add(fee0);
                totalFee1 = totalFee1.add(fee1);

                emit FeesClaim(address(this), totalFee0, totalFee1);
            }
        }

        if (_includeFee && (totalFee0 > 0 || totalFee1 > 0)) {
            // transfer performance fees
            _transferPerformanceFees(totalFee0, totalFee1);
        }

        // get unused amounts
        amount0 = amount0.add(IERC20(token0).balanceOf(address(this)));
        amount1 = amount1.add(IERC20(token1).balanceOf(address(this)));
    }
}