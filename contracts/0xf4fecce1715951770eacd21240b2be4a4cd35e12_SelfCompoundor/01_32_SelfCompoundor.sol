// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./external/openzeppelin/access/Ownable.sol";
import "./external/openzeppelin/token/ERC20/SafeERC20.sol";
import "./external/openzeppelin/math/SafeMath.sol";
import "./external/openzeppelin/utils/ReentrancyGuard.sol";

import "./external/uniswap/v3-core/interfaces/IUniswapV3Factory.sol";
import "./external/uniswap/v3-core/interfaces/IUniswapV3Pool.sol";
import "./external/uniswap/v3-core/libraries/TickMath.sol";

import "./external/uniswap/v3-periphery/libraries/LiquidityAmounts.sol";
import "./external/uniswap/v3-periphery/interfaces/INonfungiblePositionManager.sol";
import "./external/uniswap/v3-periphery/interfaces/IV3SwapRouter.sol";

/**
 * @title SelfCompoundor
 * @dev Contract for manually compounding Uniswap V3 NFT positions which are not in auto-compoundor
 * Positions are sent to this contract, compounded and returned in the same tx
 * Simplified design with protocol rewards kept in the contract, to be withdrawn by the contract owner.
 * Leftover tokens are always returned to owner
 */
contract SelfCompoundor is Ownable, ReentrancyGuard {

    using SafeMath for uint256;

    uint128 constant Q64 = 2**64;
    uint128 constant Q96 = 2**96;

    // fixed config values (proven values from autocompounder contract - this contract can be redeployed if values need to change)
    uint64 constant public totalRewardX64 = 0; // 0% fixed reward for protocol
    uint32 constant public maxTWAPTickDifference = 100; // 1% max tick difference
    uint32 constant public TWAPSeconds = 60; // TWAP period in seconds

    // wrapped native token address
    address immutable public weth;

    // uniswap v3 components
    IUniswapV3Factory immutable public factory;
    INonfungiblePositionManager immutable public nonfungiblePositionManager;
    IV3SwapRouter immutable public swapRouter;

    // autocompound event
    event AutoCompounded(
        address indexed account,
        uint256 indexed tokenId,
        uint256 amountAdded0,
        uint256 amountAdded1,
        uint256 reward0,
        uint256 reward1,
        address token0,
        address token1
    );

    constructor(INonfungiblePositionManager _nonfungiblePositionManager, IV3SwapRouter _swapRouter) {

        require(address(_nonfungiblePositionManager) != address(0) && address(_swapRouter) != address(0));

        weth = _nonfungiblePositionManager.WETH9();
        factory = IUniswapV3Factory(_nonfungiblePositionManager.factory());
        nonfungiblePositionManager = _nonfungiblePositionManager;
        swapRouter = _swapRouter;
    }

    /**
     * @notice Withdraws protocol fees (onlyOwner)
     * @param tokens Addresses of tokens to withdraw
     * @param to Address to send to
     */
    function withdrawBalances(address[] calldata tokens, address to) external onlyOwner {

        require(to != address(0));

        uint count = tokens.length;
        uint i;
        for(;i<count;++i) {
            IERC20 token = IERC20(tokens[i]);
            uint256 balance = token.balanceOf(address(this));
            SafeERC20.safeTransfer(token, to, balance);
        }
    }

    /**
     * @dev When receiving a Uniswap V3 NFT, executes autocompound and returns NFT in same tx
     */
    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external nonReentrant returns (bytes4) {
        require(msg.sender == address(nonfungiblePositionManager), "!univ3 pos");

        bool doSwap;
        bytes memory returnData;

        if (data.length > 0) {
            (doSwap, returnData) = abi.decode(data, (bool, bytes));
        } else {
            doSwap = true; // default do swap and empty returnData
        }

        _autoCompound(tokenId, from, doSwap);

        nonfungiblePositionManager.safeTransferFrom(address(this), from, tokenId, returnData);

        return this.onERC721Received.selector;
    }

    // state used during autocompound execution
    struct AutoCompoundState {
        uint256 amount0;
        uint256 amount1;
        uint256 maxAddAmount0;
        uint256 maxAddAmount1;
        uint256 compounded0;
        uint256 compounded1;
        uint256 amount0Fees;
        uint256 amount1Fees;
        uint256 priceX96;
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
    }

    /**
     * @notice Autocompounds for a given NFT
     * @param tokenId token id
     * @param from address which sent NFT 
     * @param doSwap is swap requested
     */
    function _autoCompound(uint256 tokenId, address from, bool doSwap) internal
    {
        AutoCompoundState memory state;

        // collect fees
        (state.amount0, state.amount1) = nonfungiblePositionManager.collect(INonfungiblePositionManager.CollectParams(tokenId, address(this), type(uint128).max, type(uint128).max));

        // get position info
        (, , state.token0, state.token1, state.fee, state.tickLower, state.tickUpper, , , , , ) = nonfungiblePositionManager.positions(tokenId);

        // only if there are balances to work with - start autocompounding process
        if (state.amount0 > 0 || state.amount1 > 0) {

            SwapParams memory swapParams = SwapParams(
                state.token0, 
                state.token1, 
                state.fee, 
                state.tickLower, 
                state.tickUpper, 
                state.amount0, 
                state.amount1, 
                block.timestamp
            );

            if (doSwap) {
                (state.amount0, state.amount1) = _swapToPriceRatio(swapParams);
            }

            state.maxAddAmount0 = state.amount0.mul(Q64).div(uint(totalRewardX64).add(Q64));	
            state.maxAddAmount1 = state.amount1.mul(Q64).div(uint(totalRewardX64).add(Q64));

            // deposit liquidity into tokenId
            if (state.maxAddAmount0 > 0 || state.maxAddAmount1 > 0) {
                
                if (state.maxAddAmount0 > 0) {
                    SafeERC20.safeApprove(IERC20(state.token0), address(nonfungiblePositionManager), state.maxAddAmount0);
                }
                if (state.maxAddAmount1 > 0) {
                    SafeERC20.safeApprove(IERC20(state.token1), address(nonfungiblePositionManager), state.maxAddAmount1);
                }                

                (, state.compounded0, state.compounded1) = nonfungiblePositionManager.increaseLiquidity(
                    INonfungiblePositionManager.IncreaseLiquidityParams(
                        tokenId,
                        state.maxAddAmount0,
                        state.maxAddAmount1,
                        0,
                        0,
                        block.timestamp
                    )
                );

                if (state.maxAddAmount0 > 0) {
                    SafeERC20.safeApprove(IERC20(state.token0), address(nonfungiblePositionManager), 0);
                }
                if (state.maxAddAmount1 > 0) {
                    SafeERC20.safeApprove(IERC20(state.token1), address(nonfungiblePositionManager), 0);
                }

                // fees are always calculated based on added amount
                state.amount0Fees = state.compounded0.mul(totalRewardX64).div(Q64);
                state.amount1Fees = state.compounded1.mul(totalRewardX64).div(Q64);
            }

            // return remaining tokens to owner
            if (state.amount0.sub(state.compounded0).sub(state.amount0Fees) > 0) {
                SafeERC20.safeTransfer(IERC20(state.token0), from, state.amount0.sub(state.compounded0).sub(state.amount0Fees));
            }
            if (state.amount1.sub(state.compounded1).sub(state.amount1Fees) > 0) {
                SafeERC20.safeTransfer(IERC20(state.token1), from, state.amount1.sub(state.compounded1).sub(state.amount1Fees));
            }
            
            // protocol reward is kept in contract (leftover tokens)
        }

        emit AutoCompounded(from, tokenId, state.compounded0, state.compounded1, state.amount0Fees, state.amount1Fees, state.token0, state.token1);
    }

    function _getTWAPTick(IUniswapV3Pool pool, uint32 twapPeriod) internal view returns (int24, bool) {
        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = 0; // from (before)
        secondsAgos[1] = twapPeriod; // from (before)
        // pool observe may fail when there is not enough history available
        try pool.observe(secondsAgos) returns (int56[] memory tickCumulatives, uint160[] memory) {
            return (int24((tickCumulatives[0] - tickCumulatives[1]) / twapPeriod), true);
        } catch {
            return (0, false);
        } 
    }
   
    function _requireMaxTickDifference(int24 tick, int24 other, uint32 maxDifference) internal pure {	
        require(other > tick && (uint48(other - tick) < maxDifference) || other <= tick && (uint48(tick - other) < maxDifference), "price err");	
    }

    // state used during swap execution
    struct SwapState {
        uint256 positionAmount0;
        uint256 positionAmount1;
        int24 tick;
        int24 otherTick;
        uint160 sqrtPriceX96;
        uint160 sqrtPriceX96Lower;
        uint160 sqrtPriceX96Upper;
        uint256 priceX96;
        uint256 amountRatioX96;
        uint256 delta0;
        uint256 delta1;
        bool sell0;
        bool twapOk;
    }

    struct SwapParams {
        address token0;
        address token1;
        uint24 fee; 
        int24 tickLower; 
        int24 tickUpper; 
        uint256 amount0;
        uint256 amount1;
        uint256 deadline;
    }

    // checks oracle for fair price - swaps to position ratio (considering estimated reward) - calculates max amount to be added
    function _swapToPriceRatio(SwapParams memory params) internal returns (uint256 amount0, uint256 amount1) 
    {    
        SwapState memory state;

        amount0 = params.amount0;
        amount1 = params.amount1;
        
        // get price
        IUniswapV3Pool pool = IUniswapV3Pool(factory.getPool(params.token0, params.token1, params.fee));
        
        (state.sqrtPriceX96,state.tick,,,,,) = pool.slot0();

        // oracle validation
        // check that price is not too far from TWAP (protect from price manipulation attacks)
        (state.otherTick, state.twapOk) = _getTWAPTick(pool, TWAPSeconds);

        // if not enough history do not allow swapping
        require(state.twapOk, "twap not available");

        _requireMaxTickDifference(state.tick, state.otherTick, maxTWAPTickDifference);
        
        state.priceX96 = uint256(state.sqrtPriceX96).mul(state.sqrtPriceX96).div(Q96);

        // calculate ideal position amounts
        state.sqrtPriceX96Lower = TickMath.getSqrtRatioAtTick(params.tickLower);
        state.sqrtPriceX96Upper = TickMath.getSqrtRatioAtTick(params.tickUpper);
        (state.positionAmount0, state.positionAmount1) = LiquidityAmounts.getAmountsForLiquidity(
                                                            state.sqrtPriceX96, 
                                                            state.sqrtPriceX96Lower, 
                                                            state.sqrtPriceX96Upper, 
                                                            Q96); // dummy value we just need ratio

        // calculate how much of the position needs to be converted to the other token
        if (state.positionAmount0 == 0) {
            state.delta0 = amount0;
            state.sell0 = true;
        } else if (state.positionAmount1 == 0) {
            state.delta0 = amount1.mul(Q96).div(state.priceX96);
            state.sell0 = false;
        } else {
            state.amountRatioX96 = state.positionAmount0.mul(Q96).div(state.positionAmount1);
            state.sell0 = (state.amountRatioX96.mul(amount1) < amount0.mul(Q96));
            if (state.sell0) {
                state.delta0 = amount0.mul(Q96).sub(state.amountRatioX96.mul(amount1)).div(state.amountRatioX96.mul(state.priceX96).div(Q96).add(Q96));
            } else {
                state.delta0 = state.amountRatioX96.mul(amount1).sub(amount0.mul(Q96)).div(state.amountRatioX96.mul(state.priceX96).div(Q96).add(Q96));
            }
        }

        if (state.delta0 > 0) {
            if (state.sell0) {
                SafeERC20.safeApprove(IERC20(params.token0), address(swapRouter), state.delta0);
                uint256 amountOut = _swap(abi.encodePacked(params.token0, params.fee, params.token1), state.delta0);
                SafeERC20.safeApprove(IERC20(params.token0), address(swapRouter), 0);

                amount0 = amount0.sub(state.delta0);
                amount1 = amount1.add(amountOut);
            } else {
                state.delta1 = state.delta0.mul(state.priceX96).div(Q96);
                // prevent possible rounding to 0 issue
                if (state.delta1 > 0) {
                    SafeERC20.safeApprove(IERC20(params.token1), address(swapRouter), state.delta1);
                    uint256 amountOut = _swap(abi.encodePacked(params.token1, params.fee, params.token0), state.delta1);
                    SafeERC20.safeApprove(IERC20(params.token1), address(swapRouter), 0);

                    amount0 = amount0.add(amountOut);
                    amount1 = amount1.sub(state.delta1);
                }
            }
        }
    }

    function _swap(bytes memory swapPath, uint256 amount) internal returns (uint256 amountOut) {
        amountOut = swapRouter.exactInput(IV3SwapRouter.ExactInputParams(swapPath, address(this), amount, 0)); // oracle price check prevents sandwich attacks
    }
}