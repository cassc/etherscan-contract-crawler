// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Automator.sol";

/// @title AutoExit
/// @notice Lets a v3 position to be automatically removed (limit order) or swapped to the opposite token (stop loss order) when it reaches a certain tick. 
/// A revert controlled bot (operator) is responsible for the execution of optimized swaps (using external swap router)
/// Positions need to be approved (approve or setApprovalForAll) for the contract and configured with configToken method
contract AutoExit is Automator {

    error NoLiquidity();
    error MissingSwapData();

    event Executed(
        uint256 indexed tokenId,
        address account,
        bool isSwap,
        uint256 amountReturned0,
        uint256 amountReturned1,
        address token0,
        address token1
    );
    event PositionConfigured(
        uint256 indexed tokenId,
        bool isActive,
        bool token0Swap,
        bool token1Swap,
        int24 token0TriggerTick,
        int24 token1TriggerTick,
        uint64 token0SlippageX64,
        uint64 token1SlippageX64
    );

    constructor(INonfungiblePositionManager _npm, address _operator, address _withdrawer, uint32 _TWAPSeconds, uint16 _maxTWAPTickDifference, uint64 _protocolRewardX64, address[] memory _swapRouterOptions) 
        Automator(_npm, _operator, _withdrawer, _TWAPSeconds, _maxTWAPTickDifference,  _protocolRewardX64, _swapRouterOptions) {
    }

    // define how stoploss / limit should be handled
    struct PositionConfig {
        bool isActive; // if position is active
        // should swap token to other token when triggered
        bool token0Swap;
        bool token1Swap;
        // when should action be triggered (when this tick is reached - allow execute)
        int24 token0TriggerTick; // when tick is below this one
        int24 token1TriggerTick; // when tick is equal or above this one
        // max price difference from current pool price for swap / Q64
        uint64 token0SlippageX64; // when token 0 is swapped to token 1
        uint64 token1SlippageX64; // when token 1 is swapped to token 0
    }

    // configured tokens
    mapping (uint256 => PositionConfig) public positionConfigs;

    /// @notice params for execute()
    struct ExecuteParams {
        uint256 tokenId; // tokenid to process
        bytes swapData; // if its a swap order - must include swap data
        uint128 liquidity; // liquidity the calculations are based on
        uint256 amountRemoveMin0; // min amount to be removed from liquidity
        uint256 amountRemoveMin1; // min amount to be removed from liquidity
        uint256 deadline; // for uniswap operations - operator promises fair value
    }

    struct ExecuteState {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint128 liquidity;
        uint256 amount0;
        uint256 amount1;
        uint256 amountOutMin;
        uint256 amountInDelta;
        uint256 amountOutDelta;
        IUniswapV3Pool pool;
        uint256 swapAmount;
        int24 tick;
        bool isSwap;
        bool isAbove;
        address owner;
    }

    /**
     * @notice Handle token (must be in correct state)
     * Can only be called only from configured operator account
     * Swap needs to be done with max price difference from current pool price - otherwise reverts
     */
    function execute(ExecuteParams memory params) external {

        if (!operators[msg.sender]) {
            revert Unauthorized();
        }

        ExecuteState memory state;
        PositionConfig memory config = positionConfigs[params.tokenId];

        if (!config.isActive) {
            revert NotConfigured();
        }

        // get position info
        (,,state.token0, state.token1, state.fee, state.tickLower, state.tickUpper, state.liquidity, , , , ) =  nonfungiblePositionManager.positions(params.tokenId);

        // so can be executed only once
        if (state.liquidity == 0) {
            revert NoLiquidity();
        }
        if (state.liquidity != params.liquidity) {
            revert LiquidityChanged();
        }

        state.pool = _getPool(state.token0, state.token1, state.fee);
        (,state.tick,,,,,) = state.pool.slot0();

        // not triggered
        if (config.token0TriggerTick <= state.tick && state.tick < config.token1TriggerTick) {
            revert NotReady();
        }
    
        state.isAbove = state.tick >= config.token1TriggerTick;
        state.isSwap = !state.isAbove && config.token0Swap || state.isAbove && config.token1Swap;
       
        // decrease full liquidity for given position - and return fees as well
        (state.amount0, state.amount1) = _decreaseFullLiquidityAndCollect(params.tokenId, state.liquidity, params.amountRemoveMin0, params.amountRemoveMin1, params.deadline);

        // swap to other token
        if (state.isSwap) {
            if (params.swapData.length == 0) {
                revert MissingSwapData();
            }

            state.swapAmount = state.isAbove ? state.amount1 : state.amount0;
            
            // checks if price in valid oracle range and calculates amountOutMin
            (state.amountOutMin,,,) = _validateSwap(!state.isAbove, state.swapAmount, state.pool, TWAPSeconds, maxTWAPTickDifference, state.isAbove ? config.token1SlippageX64 : config.token0SlippageX64);

            (state.amountInDelta, state.amountOutDelta) = _swap(state.isAbove ? IERC20(state.token1) : IERC20(state.token0), state.isAbove ? IERC20(state.token0) : IERC20(state.token1), state.swapAmount, state.amountOutMin, params.swapData);

            state.amount0 = state.isAbove ? state.amount0 + state.amountOutDelta : state.amount0 - state.amountInDelta;
            state.amount1 = state.isAbove ? state.amount1 - state.amountInDelta : state.amount1 + state.amountOutDelta;
        }
     
        // when swap - protocol reward is removed only from target token (to incentivize optimal swap done by operator)
        if (state.isAbove && state.isSwap || !state.isSwap) {
            state.amount0 -= state.amount0 * protocolRewardX64 / Q64;
        }
        if (!state.isAbove && state.isSwap || !state.isSwap) {
            state.amount1 -= state.amount1 * protocolRewardX64 / Q64;
        }

        state.owner = nonfungiblePositionManager.ownerOf(params.tokenId);
        if (state.amount0 > 0) {
            _transferToken(state.owner, IERC20(state.token0), state.amount0, true);
        }
        if (state.amount1 > 0) {
            _transferToken(state.owner, IERC20(state.token1), state.amount1, true);
        }

        // delete config for position
        delete positionConfigs[params.tokenId];
        emit PositionConfigured(params.tokenId, false, false, false, 0, 0, 0, 0);

        // log event
        emit Executed(params.tokenId, msg.sender, state.isSwap, state.amount0, state.amount1, state.token0, state.token1);
    }

    // function to configure a token to be used with this runner
    // it needs to have approvals set for this contract beforehand
    function configToken(uint256 tokenId, PositionConfig memory config) external {
        address owner = nonfungiblePositionManager.ownerOf(tokenId);
        if (owner != msg.sender) {
            revert Unauthorized();
        }

        if (config.isActive) {
            if (config.token0TriggerTick >= config.token1TriggerTick) {
                revert InvalidConfig();
            }
        }

        positionConfigs[tokenId] = config;

        emit PositionConfigured(
            tokenId,
            config.isActive,
            config.token0Swap,
            config.token1Swap,
            config.token0TriggerTick,
            config.token1TriggerTick,
            config.token0SlippageX64,
            config.token1SlippageX64
        );
    }
}