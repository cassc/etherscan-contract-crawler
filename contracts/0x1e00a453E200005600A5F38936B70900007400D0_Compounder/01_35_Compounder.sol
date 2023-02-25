// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import "./external/openzeppelin/access/Ownable.sol";
import "./external/openzeppelin/utils/ReentrancyGuard.sol";
import "./external/openzeppelin/utils/Multicall.sol";
import "./external/openzeppelin/token/ERC20/SafeERC20.sol";
import "./external/openzeppelin/math/SafeMath.sol";

import "./external/uniswap/v3-core/interfaces/IUniswapV3Pool.sol";
import "./external/uniswap/v3-core/libraries/TickMath.sol";
import "./external/uniswap/v3-core/libraries/FullMath.sol";
import "./external/uniswap/v3-periphery/libraries/LiquidityAmounts.sol";
import "./external/uniswap/v3-periphery/interfaces/INonfungiblePositionManager.sol";

import "./ICompounder.sol";

/// @title Compounder, an automatic reinvesting tool for uniswap v3 positions
/// @author kev1n
/** @notice 
 * Owner refers to the owner of the uniswapv3 NFT
 * Caller refers to the person who calls the AutoCompound function for the owner, which will automatically reinvest the fees for that position
 * Position refers to the uniswap v3 position/NFT
 * Protocol refers to compounder.fi, the organization who created this contract
**/
contract Compounder is ICompounder, ReentrancyGuard, Ownable, Multicall {

    using SafeMath for uint256;

    uint128 constant Q96 = 2**96;
    uint256 constant Q192 = 2**192;

    //reward paid out to compounder as a fraction of the caller's collected fees. ex: if protocolReward if 5, then the protocol will take 1/5 or 20% of the caller's fees and the caller will take 80%
    uint64 public constant override protocolReward = 5;

    //the gross reward paid out to the caller. if the fee is 40, then the caller takes 1/40th of tokenA unclaimed fees or of tokenB unclaimed fees  
    uint64 public constant override grossCallerReward = 40;

    // uniswap v3 components
    IUniswapV3Factory private immutable factory;
    INonfungiblePositionManager private immutable nonfungiblePositionManager;
    ISwapRouter private immutable swapRouter;

    mapping(address => mapping(address => uint256)) public override callerBalances; //maps a caller's address to each token's address to how much is owed to them by the protocol (rewards from calling the autocompound function)

    constructor(IUniswapV3Factory _factory, INonfungiblePositionManager _nonfungiblePositionManager, ISwapRouter _swapRouter) {
        factory = _factory;
        nonfungiblePositionManager = _nonfungiblePositionManager;
        swapRouter = _swapRouter;
    }

    // @notice required to get the gas from graphql indexing
    event AutoCompound(uint256 tokenId, uint256 fee0, uint256 fee1, uint256 compounded0, uint256 compounded1, uint256 liqAdded); 

    /**
     * @notice Autocompounds for a given NFT (anyone can call this and gets a percentage of the fees)
     * @param tokenId the tokenId being selected to compound
     * @param rewardConversion true - take token0 as the caller fee, false - take token1 as the caller fee
     * @return fee0 Amount of token0 caller recieves
     * @return fee1 Amount of token1 caller recieves
     * @return compounded0 Amount of token0 that was compounded
     * @return compounded1 Amount of token1 that was compounded
     * @dev AutoCompound25a502142c1769f58abaabfe4f9f4e8b89d24513 saves 70 gas (optimized function selector)
     */
    function AutoCompound25a502142c1769f58abaabfe4f9f4e8b89d24513(uint256 tokenId, bool rewardConversion) 
        override
        external
        returns (uint256 fee0, uint256 fee1, uint256 compounded0, uint256 compounded1, uint256 liqAdded) 
    {   
        AutoCompoundState memory state;
        
        state.tokenOwner = nonfungiblePositionManager.ownerOf(tokenId);

        require(state.tokenOwner != address(0), "!found");

        // collect fees
        (state.amount0, state.amount1) = nonfungiblePositionManager.collect(
            INonfungiblePositionManager.CollectParams(tokenId, address(this), type(uint128).max, type(uint128).max)
        );
        
        require(state.amount0 > 0 || state.amount1 > 0, "0claim");

        (, , state.token0, state.token1, state.fee, state.tickLower, state.tickUpper, , , , , ) = 
        nonfungiblePositionManager.positions(tokenId);

        _checkApprovals(IERC20(state.token0), IERC20(state.token1));

        //caller earns 1/40th of their token of choice
        if (rewardConversion) {
            fee0 = state.amount0 / grossCallerReward; 
            state.amount0 = state.amount0.sub(fee0);
            _increaseBalanceCaller(msg.sender, state.token0, fee0);
        } else {
            fee1 = state.amount1 / grossCallerReward;
            state.amount1 = state.amount1.sub(fee1);
            _increaseBalanceCaller(msg.sender, state.token1, fee1);
        }

        SwapParams memory swapParams = SwapParams(
            state.token0, 
            state.token1, 
            state.fee, 
            state.tickLower, 
            state.tickUpper, 
            state.amount0,
            state.amount1
        );
        (state.amount0, state.amount1) = 
            _swapToPriceRatio(swapParams); //returns amount of 0 and 1 after swapping

        // deposit liquidity into tokenId
        if (state.amount0 > 0 || state.amount1 > 0) {
            (liqAdded, compounded0, compounded1) = nonfungiblePositionManager.increaseLiquidity(
                INonfungiblePositionManager.IncreaseLiquidityParams(
                    tokenId,
                    state.amount0,
                    state.amount1,
                    0,
                    0,
                    block.timestamp
                )
            );
        }

        emit AutoCompound(tokenId, fee0, fee1, compounded0, compounded1, liqAdded);
    }

    function _checkApprovals(IERC20 token0, IERC20 token1) private {
        // approve tokens once if not yet approved
        uint256 allowance0 = token0.allowance(address(this), address(nonfungiblePositionManager));
        if (allowance0 == 0) {
            SafeERC20.safeApprove(token0, address(nonfungiblePositionManager), type(uint256).max);
            SafeERC20.safeApprove(token0, address(swapRouter), type(uint256).max);
        }
        uint256 allowance1 = token1.allowance(address(this), address(nonfungiblePositionManager));
        if (allowance1 == 0) {
            SafeERC20.safeApprove(token1, address(nonfungiblePositionManager), type(uint256).max);
            SafeERC20.safeApprove(token1, address(swapRouter), type(uint256).max);
        }
    }

    /**
     * @notice Withdraws token balance for a caller (their fees for compounding)
     * @param tokenAddress Address of token to withdraw
     * @param to Address to send to
     */
    
    //for caller only
    function withdrawBalanceCaller(address tokenAddress, address to) external override nonReentrant {
        uint256 amount = callerBalances[msg.sender][tokenAddress];
        require(amount > 0, "amount==0");
        _withdrawBalanceInternalCaller(tokenAddress, to, amount);
    }

    //for caller only
    function _increaseBalanceCaller(address account, address tokenAddress, uint256 amount) private {
        if(amount > 0) {
            callerBalances[account][tokenAddress] = callerBalances[account][tokenAddress].add(amount);
        }
    }

    //for caller only
    function _withdrawBalanceInternalCaller(address tokenAddress, address to, uint256 amount) private {
        callerBalances[msg.sender][tokenAddress] = 0;

        uint256 protocolFees = amount.div(protocolReward);
        uint256 callerFees = amount.sub(protocolFees);

        SafeERC20.safeTransfer(IERC20(tokenAddress), to, callerFees);
        SafeERC20.safeTransfer(IERC20(tokenAddress), owner(), protocolFees);
    }

    // checks oracle for fair price - swaps to position ratio (considering estimated reward) - calculates max amount to be added
    function _swapToPriceRatio(SwapParams memory params) 
        private 
        returns (uint256 amount0, uint256 amount1) 
    {    
        SwapState memory state;

        amount0 = params.amount0;
        amount1 = params.amount1;
        
        // get price
        IUniswapV3Pool pool = IUniswapV3Pool(factory.getPool(params.token0, params.token1, params.fee));
        
        (state.sqrtPriceX96,state.tick,,,,,) = pool.slot0();

        //the risk of an attack on twap price is negligible
        
        //example attack
        //1. attacker swaps a lot of A for B, doing so will decrease the price of A relative to B
        //2. attacker triggers autoCompound for positions in the same uniswap pool as the attack, which increases the liquidity available to them to swap back
        //3. attacker swaps back a greater amount of B for A, benefitting from the reduction in slippage from the liquidity to net a profit
        
        //why it is not an issue:
        // * the amount of fees in the liquidity position, assuming that it is an automated process, will never reach an amount of liquidity that is profitable for the attacker,
        // as it will be compounded efficiently
        // * there is a significant gas cost to compound many positions
        // * a larger pool will not have significant slippage
        // * a smaller pool will not yield significant fees

        // calculate how much of the position needs to be converted to the other token
        if (state.tick >= params.tickUpper) {
            state.delta0 = amount0;
            state.sell0 = true;
        } else if (state.tick <= params.tickLower) {
            state.priceX96 = FullMath.mulDiv(state.sqrtPriceX96, state.sqrtPriceX96, Q96);
            state.delta0 = FullMath.mulDiv(amount1, Q96, state.priceX96);
            state.sell0 = false;
        } else {
            (state.positionAmount0, state.positionAmount1) = LiquidityAmounts.getAmountsForLiquidity(
                                                            state.sqrtPriceX96, 
                                                            TickMath.getSqrtRatioAtTick(params.tickLower), 
                                                            TickMath.getSqrtRatioAtTick(params.tickUpper), 
                                                            Q96);
                                                            
            state.amountRatioX96 = FullMath.mulDiv(state.positionAmount0, Q96, state.positionAmount1);

            uint256 amount1as0 = state.amountRatioX96.mul(amount1);
            uint256 amount0as96 = amount0.mul(Q96);

            uint256 priceX192 = uint256(state.sqrtPriceX96).mul(state.sqrtPriceX96);
            state.sell0 = (amount1as0 < amount0as96);
            if (state.sell0) {
                state.delta0 = amount0as96.sub(amount1as0).div(FullMath.mulDiv(state.amountRatioX96, priceX192, Q192).add(Q96));
            } else {
                state.delta0 = amount1as0.sub(amount0as96).div(FullMath.mulDiv(state.amountRatioX96, priceX192, Q192).add(Q96));
            }
        }
        if (state.delta0 > 0) {
            state.priceX96 = FullMath.mulDiv(state.sqrtPriceX96, state.sqrtPriceX96, Q96);
            if (state.sell0) {
                
                uint256 amountOut = _swap(
                    params.token0,
                    params.token1,
                    params.fee,
                    state.delta0
                );

                amount0 = amount0.sub(state.delta0);
                amount1 = amount1.add(amountOut);
            } else {
                state.delta1 = FullMath.mulDiv(state.delta0, state.priceX96, Q96);
                // prevent possible rounding to 0 issue
                if (state.delta1 > 0) {
                    uint256 amountOut = _swap(
                        params.token1,
                        params.token0,
                        params.fee,
                        state.delta1
                    );
                    
                    amount0 = amount0.add(amountOut);
                    amount1 = amount1.sub(state.delta1);
                }
            }
        }
    }

    function _swap(address tokenIn, address tokenOut, uint24 fee, uint256 amount) private returns (uint256 amountOut) {
        if (amount > 0) {
            ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: fee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
            amountOut = swapRouter.exactInputSingle(params);
        }
    }
}