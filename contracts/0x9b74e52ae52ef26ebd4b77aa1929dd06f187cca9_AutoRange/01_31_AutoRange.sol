// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Automator.sol";

/// @title AutoRange
/// @notice Allows operator of AutoRange contract (Revert controlled bot) to change range for configured positions
/// Positions need to be approved (setApprovalForAll) for the contract and configured with configToken method
/// When executed a new position is created and automatically configured the same way as the original position
contract AutoRange is Automator {

    error SameRange();
    error NotSupportedFeeTier();
    error SwapAmountTooLarge();

    event RangeChanged(
        uint256 indexed oldTokenId, 
        uint256 indexed newTokenId
    );
    event PositionConfigured(
        uint256 indexed tokenId,
        int32 lowerTickLimit,
        int32 upperTickLimit,
        int32 lowerTickDelta,
        int32 upperTickDelta,
        uint64 token0SlippageX64,
        uint64 token1SlippageX64
    );

    constructor(INonfungiblePositionManager _npm, address _operator, address _withdrawer, uint32 _TWAPSeconds, uint16 _maxTWAPTickDifference, uint64 _protocolRewardX64, address[] memory _swapRouterOptions) 
        Automator(_npm, _operator, _withdrawer, _TWAPSeconds, _maxTWAPTickDifference, _protocolRewardX64, _swapRouterOptions) {
    }

    // defines when and how a position can be changed by operator
    // when a position is adjusted config for the position is cleared and copied to the newly created position
    struct PositionConfig {
        // needs more than int24 because it can be [-type(uint24).max,type(uint24).max]
        int32 lowerTickLimit; // if negative also in-range positions may be adjusted / if 0 out of range positions may be adjusted
        int32 upperTickLimit; // if negative also in-range positions may be adjusted / if 0 out of range positions may be adjusted
        int32 lowerTickDelta; // this amount is added to current tick (floored to tickspacing) to define lowerTick of new position
        int32 upperTickDelta; // this amount is added to current tick (floored to tickspacing) to define upperTick of new position
        uint64 token0SlippageX64; // max price difference from current pool price for swap / Q64 for token0
        uint64 token1SlippageX64; // max price difference from current pool price for swap / Q64 for token1
    }

    // configured tokens
    mapping (uint256 => PositionConfig) public positionConfigs;

    /// @notice params for execute()
    struct ExecuteParams {
        uint256 tokenId;
        bool swap0To1;
        uint256 amountIn; // if this is set to 0 no swap happens
        bytes swapData;
        uint128 liquidity; // liquidity the calculations are based on
        uint256 amountRemoveMin0; // min amount to be removed from liquidity
        uint256 amountRemoveMin1; // min amount to be removed from liquidity
        uint256 deadline; // for uniswap operations - operator promises fair value
    }

    struct ExecuteState {
        address owner;
        address currentOwner;
        IUniswapV3Pool pool;
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        int24 currentTick;

        uint256 amount0;
        uint256 amount1;

        uint256 maxAddAmount0;
        uint256 maxAddAmount1;

        uint256 amountAdded0;
        uint256 amountAdded1;

        uint128 liquidity;

        uint256 protocolReward0;
        uint256 protocolReward1;
        uint256 amountOutMin;
        uint256 amountInDelta;
        uint256 amountOutDelta;


        uint256 newTokenId;
    }

    /**
     * @notice Adjust token (must be in correct state)
     * Can only be called only from configured operator account
     * Swap needs to be done with max price difference from current pool price - otherwise reverts
     */
    function execute(ExecuteParams memory params) external {

        if (!operators[msg.sender]) {
            revert Unauthorized();
        }

        ExecuteState memory state;
        PositionConfig memory config = positionConfigs[params.tokenId];

        if (config.lowerTickDelta == config.upperTickDelta) {
            revert NotConfigured();
        }

        // get position info
        (,, state.token0, state.token1, state.fee, state.tickLower, state.tickUpper, state.liquidity, , , , ) =  nonfungiblePositionManager.positions(params.tokenId);

        if (state.liquidity != params.liquidity) {
            revert LiquidityChanged();
        }

        (state.amount0, state.amount1) = _decreaseFullLiquidityAndCollect(params.tokenId, state.liquidity, params.amountRemoveMin0, params.amountRemoveMin1, params.deadline);

        if (params.swap0To1 && params.amountIn > state.amount0 || !params.swap0To1 && params.amountIn > state.amount1) {
            revert SwapAmountTooLarge();
        }

        // get pool info
        state.pool = _getPool(state.token0, state.token1, state.fee);

        // check oracle for swap
        (state.amountOutMin,state.currentTick,,) = _validateSwap(params.swap0To1, params.amountIn, state.pool, TWAPSeconds, maxTWAPTickDifference, params.swap0To1 ? config.token0SlippageX64 : config.token1SlippageX64);

        if (state.currentTick < state.tickLower - config.lowerTickLimit || state.currentTick >= state.tickUpper + config.upperTickLimit) {

            int24 tickSpacing = _getTickSpacing(state.fee);
            int24 baseTick = state.currentTick - (((state.currentTick % tickSpacing) + tickSpacing) % tickSpacing);

            // check if new range same as old range
            if (baseTick + config.lowerTickDelta == state.tickLower && baseTick + config.upperTickDelta == state.tickUpper) {
                revert SameRange();
            }

            (state.amountInDelta, state.amountOutDelta) = _swap(params.swap0To1 ? IERC20(state.token0) : IERC20(state.token1), params.swap0To1 ? IERC20(state.token1) : IERC20(state.token0), params.amountIn, state.amountOutMin, params.swapData);

            state.amount0 = params.swap0To1 ? state.amount0 - state.amountInDelta : state.amount0 + state.amountOutDelta;
            state.amount1 = params.swap0To1 ? state.amount1 + state.amountOutDelta : state.amount1 - state.amountInDelta;
                
            // max amount to add - removing max potential fees
            state.maxAddAmount0 = state.amount0 * Q64 / (protocolRewardX64 + Q64);
            state.maxAddAmount1 = state.amount1 * Q64 / (protocolRewardX64 + Q64);

            INonfungiblePositionManager.MintParams memory mintParams = 
                INonfungiblePositionManager.MintParams(
                    address(state.token0), 
                    address(state.token1), 
                    state.fee, 
                    SafeCast.toInt24(baseTick + config.lowerTickDelta), // reverts if out of valid range
                    SafeCast.toInt24(baseTick + config.upperTickDelta), // reverts if out of valid range
                    state.maxAddAmount0,
                    state.maxAddAmount1, 
                    0,
                    0,
                    address(this), // is sent to real recipient aftwards
                    params.deadline
                );

            // approve npm 
            SafeERC20.safeApprove(IERC20(state.token0), address(nonfungiblePositionManager), state.maxAddAmount0);
            SafeERC20.safeApprove(IERC20(state.token1), address(nonfungiblePositionManager), state.maxAddAmount1);

            // mint is done to address(this) first - its not a safemint
            (state.newTokenId,,state.amountAdded0,state.amountAdded1) = nonfungiblePositionManager.mint(mintParams);

            // remove remaining approval
            SafeERC20.safeApprove(IERC20(state.token0), address(nonfungiblePositionManager), 0);
            SafeERC20.safeApprove(IERC20(state.token1), address(nonfungiblePositionManager), 0);
            
            state.owner = nonfungiblePositionManager.ownerOf(params.tokenId);

            // send it to current owner
            nonfungiblePositionManager.safeTransferFrom(address(this), state.owner, state.newTokenId);

            // protocol reward is calculated based on added amount (to incentivize optimal swap done by operator)
            state.protocolReward0 = state.amountAdded0 * protocolRewardX64 / Q64;
            state.protocolReward1 = state.amountAdded1 * protocolRewardX64 / Q64;

            // send leftover to owner
            if (state.amount0 - state.protocolReward0 - state.amountAdded0 > 0) {
                _transferToken(state.owner, IERC20(state.token0), state.amount0 - state.protocolReward0 - state.amountAdded0, true);
            }
            if (state.amount1 - state.protocolReward1 - state.amountAdded1 > 0) {
                _transferToken(state.owner, IERC20(state.token1), state.amount1 - state.protocolReward1 - state.amountAdded1, true);
            }

            // copy token config for new token
            positionConfigs[state.newTokenId] = config;
            emit PositionConfigured(
                state.newTokenId,
                config.lowerTickLimit,
                config.upperTickLimit,
                config.lowerTickDelta,
                config.upperTickDelta,
                config.token0SlippageX64,
                config.token1SlippageX64
            );

            // delete config for old position
            delete positionConfigs[params.tokenId];
            emit PositionConfigured(params.tokenId, 0, 0, 0, 0, 0, 0);

            emit RangeChanged(params.tokenId, state.newTokenId);

        } else {
            revert NotReady();
        }
    }

    // function to configure a token to be used with this runner
    // it needs to have approvals set for this contract beforehand
    function configToken(uint256 tokenId, PositionConfig memory config) external {
        address owner = nonfungiblePositionManager.ownerOf(tokenId);
        if (owner != msg.sender) {
            revert Unauthorized();
        }

         // lower tick must be always below or equal to upper tick - if they are equal - range adjustment is deactivated
        if (config.lowerTickDelta > config.upperTickDelta) {
            revert InvalidConfig();
        }

        positionConfigs[tokenId] = config;

        emit PositionConfigured(
            tokenId,
            config.lowerTickLimit,
            config.upperTickLimit,
            config.lowerTickDelta,
            config.upperTickDelta,
            config.token0SlippageX64,
            config.token1SlippageX64
        );
    }

    // get tick spacing for fee tier (cached when possible)
    function _getTickSpacing(uint24 fee) internal view returns (int24) {
        if (fee == 10000) {
            return 200;
        } else if (fee == 3000) {
            return 60;
        } else if (fee == 500) {
            return 10;
        } else {
            int24 spacing = factory.feeAmountTickSpacing(fee);
            if (spacing <= 0) {
                revert NotSupportedFeeTier();
            }
            return spacing;
        }
    }
}