// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./external/openzeppelin/access/Ownable.sol";
import "./external/openzeppelin/utils/ReentrancyGuard.sol";
import "./external/openzeppelin/utils/Multicall.sol";
import "./external/openzeppelin/token/ERC20/SafeERC20.sol";
import "./external/openzeppelin/math/SafeMath.sol";

import "./external/uniswap/v3-core/interfaces/IUniswapV3Pool.sol";
import "./external/uniswap/v3-core/libraries/TickMath.sol";

import "./external/uniswap/v3-periphery/libraries/LiquidityAmounts.sol";
import "./external/uniswap/v3-periphery/interfaces/INonfungiblePositionManager.sol";

import "./ICompoundor.sol";

/*                                                  __          
  _________  ____ ___  ____  ____  __  ______  ____/ /___  _____
 / ___/ __ \/ __ `__ \/ __ \/ __ \/ / / / __ \/ __  / __ \/ ___/
/ /__/ /_/ / / / / / / /_/ / /_/ / /_/ / / / / /_/ / /_/ / /    
\___/\____/_/ /_/ /_/ .___/\____/\__,_/_/ /_/\__,_/\____/_/     
                   /_/
*/                                        
contract Compoundor is ICompoundor, ReentrancyGuard, Ownable, Multicall {

    using SafeMath for uint256;

    uint128 constant Q64 = 2**64;
    uint128 constant Q96 = 2**96;

    // max reward
    uint64 constant public MAX_REWARD_X64 = uint64(Q64 / 50); // 2%

    // max positions
    uint32 constant public MAX_POSITIONS_PER_ADDRESS = 100;

    // changable config values
    uint64 public override totalRewardX64 = MAX_REWARD_X64; // 2%
    uint64 public override compounderRewardX64 = MAX_REWARD_X64 / 2; // 1%
    uint32 public override maxTWAPTickDifference = 100; // 1%
    uint32 public override TWAPSeconds = 60;

    // wrapped native token address
    address override public weth;

    // uniswap v3 components
    IUniswapV3Factory public override factory;
    INonfungiblePositionManager public override nonfungiblePositionManager;
    ISwapRouter public override swapRouter;

    mapping(uint256 => address) public override ownerOf;
    mapping(address => uint256[]) public override accountTokens;
    mapping(address => mapping(address => uint256)) public override accountBalances;

    constructor(address _weth, IUniswapV3Factory _factory, INonfungiblePositionManager _nonfungiblePositionManager, ISwapRouter _swapRouter) {
        weth = _weth;
        factory = _factory;
        nonfungiblePositionManager = _nonfungiblePositionManager;
        swapRouter = _swapRouter;
    }

    /**
     * @notice Management method to lower reward or change ratio between total and compounder reward (onlyOwner)
     * @param _totalRewardX64 new total reward (can't be higher than current total reward)
     * @param _compounderRewardX64 new compounder reward
     */
    function setReward(uint64 _totalRewardX64, uint64 _compounderRewardX64) external override onlyOwner {
        require(_totalRewardX64 <= totalRewardX64, ">totalRewardX64");
        require(_compounderRewardX64 <= _totalRewardX64, "compounderRewardX64>totalRewardX64");
        totalRewardX64 = _totalRewardX64;
        compounderRewardX64 = _compounderRewardX64;
        emit RewardUpdated(msg.sender, _totalRewardX64, _compounderRewardX64);
    }

    /**
     * @notice Management method to change the max tick difference from twap to allow swaps (onlyOwner)
     * @param _maxTWAPTickDifference new max tick difference
     */
    function setTWAPConfig(uint32 _maxTWAPTickDifference, uint32 _TWAPSeconds) external override onlyOwner {
        maxTWAPTickDifference = _maxTWAPTickDifference;
        TWAPSeconds = _TWAPSeconds;
        emit TWAPConfigUpdated(msg.sender, _maxTWAPTickDifference, _TWAPSeconds);
    }

    /**
     * @dev When receiving a Uniswap V3 NFT, deposits token with `from` as owner
     */
    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata
    ) external override nonReentrant returns (bytes4) {
        require(msg.sender == address(nonfungiblePositionManager), "!univ3 pos");

        _addToken(tokenId, from);
        emit TokenDeposited(from, tokenId);
        return this.onERC721Received.selector;
    }

    /**
     * @notice Returns amount of NFTs for a given account
     * @param account Address of account
     * @return balance amount of NFTs for account
     */
    function balanceOf(address account) override external view returns (uint256 balance) {
        return accountTokens[account].length;
    }

    // state used during autocompound execution
    struct AutoCompoundState {
        uint256 amount0;
        uint256 amount1;
        uint256 maxAddAmount0;
        uint256 maxAddAmount1;
        uint256 amount0Fees;
        uint256 amount1Fees;
        uint256 priceX96;
        address tokenOwner;
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
    }

    /**
     * @notice Autocompounds for a given NFT (anyone can call this and gets a percentage of the fees)
     * @param params Autocompound specific parameters (tokenId, ...)
     * @return reward0 Amount of token0 caller recieves
     * @return reward1 Amount of token1 caller recieves
     * @return compounded0 Amount of token0 that was compounded
     * @return compounded1 Amount of token1 that was compounded
     */
    function autoCompound(AutoCompoundParams memory params) 
        override 
        external 
        nonReentrant 
        returns (uint256 reward0, uint256 reward1, uint256 compounded0, uint256 compounded1) 
    {
        require(ownerOf[params.tokenId] != address(0), "!found");

        AutoCompoundState memory state;

        // collect fees
        (state.amount0, state.amount1) = nonfungiblePositionManager.collect(
            INonfungiblePositionManager.CollectParams(params.tokenId, address(this), type(uint128).max, type(uint128).max)
        );

        // get position info
        (, , state.token0, state.token1, state.fee, state.tickLower, state.tickUpper, , , , , ) = 
            nonfungiblePositionManager.positions(params.tokenId);

        state.tokenOwner = ownerOf[params.tokenId];

        // add previous balances from given tokens
        state.amount0 = state.amount0.add(accountBalances[state.tokenOwner][state.token0]);
        state.amount1 = state.amount1.add(accountBalances[state.tokenOwner][state.token1]);

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
                block.timestamp, 
                params.rewardConversion, 
                state.tokenOwner == msg.sender, 
                params.doSwap
            );
    
            // checks oracle for fair price - swaps to position ratio (considering estimated reward) - calculates max amount to be added
            (state.amount0, state.amount1, state.priceX96, state.maxAddAmount0, state.maxAddAmount1) = 
                _swapToPriceRatio(swapParams);

            // deposit liquidity into tokenId
            if (state.maxAddAmount0 > 0 || state.maxAddAmount1 > 0) {
                (, compounded0, compounded1) = nonfungiblePositionManager.increaseLiquidity(
                    INonfungiblePositionManager.IncreaseLiquidityParams(
                        params.tokenId,
                        state.maxAddAmount0,
                        state.maxAddAmount1,
                        0,
                        0,
                        block.timestamp
                    )
                );
            }

            // fees are always calculated based on added amount
            // only calculate them when not tokenOwner
            if (state.tokenOwner != msg.sender) {
                if (params.rewardConversion == RewardConversion.NONE) {
                    state.amount0Fees = compounded0.mul(totalRewardX64).div(Q64);
                    state.amount1Fees = compounded1.mul(totalRewardX64).div(Q64);
                } else {
                    // calculate total added - derive fees
                    uint addedTotal0 = compounded0.add(compounded1.mul(Q96).div(state.priceX96));
                    if (params.rewardConversion == RewardConversion.TOKEN_0) {
                        state.amount0Fees = addedTotal0.mul(totalRewardX64).div(Q64);
                        // if there is not enough token0 to pay fee - pay all there is
                        if (state.amount0Fees > state.amount0.sub(compounded0)) {
                            state.amount0Fees = state.amount0.sub(compounded0);
                        }
                    } else {
                        state.amount1Fees = addedTotal0.mul(state.priceX96).div(Q96).mul(totalRewardX64).div(Q64);
                        // if there is not enough token1 to pay fee - pay all there is
                        if (state.amount1Fees > state.amount1.sub(compounded1)) {
                            state.amount1Fees = state.amount1.sub(compounded1);
                        }
                    }
                }
            }

            // calculate remaining tokens for owner
            _setBalance(state.tokenOwner, state.token0, state.amount0.sub(compounded0).sub(state.amount0Fees));
            _setBalance(state.tokenOwner, state.token1, state.amount1.sub(compounded1).sub(state.amount1Fees));

            // distribute fees - handle 2 cases (nft owner - no protocol reward / anyone else)
            if (state.tokenOwner == msg.sender) {
                reward0 = 0;
                reward1 = 0;
            } else {
                uint64 protocolRewardX64 = totalRewardX64 - compounderRewardX64;
                uint256 protocolFees0 = state.amount0Fees.mul(protocolRewardX64).div(totalRewardX64);
                uint256 protocolFees1 = state.amount1Fees.mul(protocolRewardX64).div(totalRewardX64);

                reward0 = state.amount0Fees.sub(protocolFees0);
                reward1 = state.amount1Fees.sub(protocolFees1);

                _increaseBalance(msg.sender, state.token0, reward0);
                _increaseBalance(msg.sender, state.token1, reward1);
                _increaseBalance(owner(), state.token0, protocolFees0);
                _increaseBalance(owner(), state.token1, protocolFees1);
            }
        }

        if (params.withdrawReward) {
            _withdrawFullBalances(state.token0, state.token1, msg.sender);
        }

        emit AutoCompounded(msg.sender, params.tokenId, compounded0, compounded1, reward0, reward1, state.token0, state.token1);
    }

    /**
     * @notice Special method to decrease liquidity and collect decreased amount - can only be called by the NFT owner
     * @dev Needs to do collect at the same time, otherwise the available amount would be autocompoundable for other positions
     * @param params DecreaseLiquidityAndCollectParams which are forwarded to the Uniswap V3 NonfungiblePositionManager
     * @return amount0 amount of token0 removed and collected
     * @return amount1 amount of token1 removed and collected
     */
    function decreaseLiquidityAndCollect(DecreaseLiquidityAndCollectParams calldata params) 
        override 
        external  
        nonReentrant 
        returns (uint256 amount0, uint256 amount1) 
    {
        require(ownerOf[params.tokenId] == msg.sender, "!owner");
        (amount0, amount1) = nonfungiblePositionManager.decreaseLiquidity(
            INonfungiblePositionManager.DecreaseLiquidityParams(
                params.tokenId, 
                params.liquidity, 
                params.amount0Min, 
                params.amount1Min,
                params.deadline
            )
        );

        INonfungiblePositionManager.CollectParams memory collectParams = 
            INonfungiblePositionManager.CollectParams(
                params.tokenId, 
                params.recipient, 
                LiquidityAmounts.toUint128(amount0), 
                LiquidityAmounts.toUint128(amount1)
            );

        nonfungiblePositionManager.collect(collectParams);
    }

    /**
     * @notice Forwards collect call to NonfungiblePositionManager - can only be called by the NFT owner
     * @param params INonfungiblePositionManager.CollectParams which are forwarded to the Uniswap V3 NonfungiblePositionManager
     * @return amount0 amount of token0 collected
     * @return amount1 amount of token1 collected
     */
    function collect(INonfungiblePositionManager.CollectParams calldata params) 
        override 
        external
        nonReentrant 
        returns (uint256 amount0, uint256 amount1) 
    {
        require(ownerOf[params.tokenId] == msg.sender, "!owner");
        return nonfungiblePositionManager.collect(params);
    }

    /**
     * @notice Removes a NFT from the protocol and safe transfers it to address to
     * @param tokenId TokenId of token to remove
     * @param to Address to send to
     * @param withdrawBalances When true sends the available balances for token0 and token1 as well
     * @param data data which is sent with the safeTransferFrom call
     */
    function withdrawToken(
        uint256 tokenId,
        address to,
        bool withdrawBalances,
        bytes memory data
    ) external override nonReentrant {
        require(to != address(this), "to==this");
        require(ownerOf[tokenId] == msg.sender, "!owner");

        _removeToken(msg.sender, tokenId);
        nonfungiblePositionManager.safeTransferFrom(address(this), to, tokenId, data);
        emit TokenWithdrawn(msg.sender, to, tokenId);

        if (withdrawBalances) {
            (, , address token0, address token1, , , , , , , , ) = nonfungiblePositionManager.positions(tokenId);
            _withdrawFullBalances(token0, token1, to);
        }
    }

    /**
     * @notice Withdraws token balance for a address and token
     * @param token Address of token to withdraw
     * @param to Address to send to
     * @param amount amount to withdraw
     */
    function withdrawBalance(address token, address to, uint256 amount) external override nonReentrant {
        require(amount > 0, "amount==0");
        uint256 balance = accountBalances[msg.sender][token];
        _withdrawBalanceInternal(token, to, balance, amount);
    }

    function _increaseBalance(address account, address token, uint256 amount) internal {
        accountBalances[account][token] = accountBalances[account][token].add(amount);
        emit BalanceAdded(account, token, amount);
    }

    function _setBalance(address account, address token, uint256 amount) internal {
        uint currentBalance = accountBalances[account][token];
        
        if (amount > currentBalance) {
            accountBalances[account][token] = amount;
            emit BalanceAdded(account, token, amount.sub(currentBalance));
        } else if (amount < currentBalance) {
            accountBalances[account][token] = amount;
            emit BalanceRemoved(account, token, currentBalance.sub(amount));
        }
    }

    function _withdrawFullBalances(address token0, address token1, address to) internal {
        uint256 balance0 = accountBalances[msg.sender][token0];
        if (balance0 > 0) {
            _withdrawBalanceInternal(token0, to, balance0, balance0);
        }
        uint256 balance1 = accountBalances[msg.sender][token1];
        if (balance1 > 0) {
            _withdrawBalanceInternal(token1, to, balance1, balance1);
        }
    }

    function _withdrawBalanceInternal(address token, address to, uint256 balance, uint256 amount) internal {
        require(amount <= balance, "amount>balance");
        accountBalances[msg.sender][token] = accountBalances[msg.sender][token].sub(amount);
        emit BalanceRemoved(msg.sender, token, amount);
        SafeERC20.safeTransfer(IERC20(token), to, amount);
        emit BalanceWithdrawn(msg.sender, token, to, amount);
    }

    function _addToken(uint256 tokenId, address account) internal {

        require(accountTokens[account].length < MAX_POSITIONS_PER_ADDRESS, "max positions reached");

        // get tokens for this nft
        (, , address token0, address token1, , , , , , , , ) = nonfungiblePositionManager.positions(tokenId);

        _checkApprovals(IERC20(token0), IERC20(token1));

        accountTokens[account].push(tokenId);
        ownerOf[tokenId] = account;
    }

    function _checkApprovals(IERC20 token0, IERC20 token1) internal {
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

    function _removeToken(address account, uint256 tokenId) internal {
        uint256[] memory accountTokensArr = accountTokens[account];
        uint256 len = accountTokensArr.length;
        uint256 assetIndex = len;

        // limited by MAX_POSITIONS_PER_ADDRESS (no out-of-gas problem)
        for (uint256 i = 0; i < len; i++) {
            if (accountTokensArr[i] == tokenId) {
                assetIndex = i;
                break;
            }
        }

        assert(assetIndex < len);

        uint256[] storage storedList = accountTokens[account];
        storedList[assetIndex] = storedList[storedList.length - 1];
        storedList.pop();

        delete ownerOf[tokenId];
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
        require(other > tick && (uint48(other - tick) < maxDifference) ||
        other <= tick && (uint48(tick - other) < maxDifference),
        "price err");
    }
    // state used during swap execution
    struct SwapState {
        uint256 rewardAmount0;
        uint256 rewardAmount1;
        uint256 positionAmount0;
        uint256 positionAmount1;
        int24 tick;
        int24 otherTick;
        uint160 sqrtPriceX96;
        uint160 sqrtPriceX96Lower;
        uint160 sqrtPriceX96Upper;
        uint256 amountRatioX96;
        uint256 delta0;
        uint256 delta1;
        bool sell0;
        bool twapOk;
        uint256 totalReward0;
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
        RewardConversion bc;
        bool isOwner;
        bool doSwap;
    }

    // checks oracle for fair price - swaps to position ratio (considering estimated reward) - calculates max amount to be added
    function _swapToPriceRatio(SwapParams memory params) 
        internal 
        returns (uint256 amount0, uint256 amount1, uint256 priceX96, uint256 maxAddAmount0, uint256 maxAddAmount1) 
    {    
        SwapState memory state;

        amount0 = params.amount0;
        amount1 = params.amount1;
        
        // get price
        IUniswapV3Pool pool = IUniswapV3Pool(factory.getPool(params.token0, params.token1, params.fee));
        
        (state.sqrtPriceX96,state.tick,,,,,) = pool.slot0();

        // how many seconds are needed for TWAP protection
        uint32 tSecs = TWAPSeconds;
        if (tSecs > 0) {
            // check that price is not too far from TWAP (protect from price manipulation attacks)
            (state.otherTick, state.twapOk) = _getTWAPTick(pool, tSecs);
            if (state.twapOk) {
                _requireMaxTickDifference(state.tick, state.otherTick, maxTWAPTickDifference);
            } else {
                // if there is no valid TWAP - disable swap
                params.doSwap = false;
            }
        }
        
        priceX96 = uint256(state.sqrtPriceX96).mul(state.sqrtPriceX96).div(Q96);
        state.totalReward0 = amount0.add(amount1.mul(Q96).div(priceX96)).mul(totalRewardX64).div(Q64);

        // swap to correct proportions is requested
        if (params.doSwap) {

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
                state.delta0 = amount1.mul(Q96).div(priceX96);
                state.sell0 = false;
            } else {
                state.amountRatioX96 = state.positionAmount0.mul(Q96).div(state.positionAmount1);
                state.sell0 = (state.amountRatioX96.mul(amount1) < amount0.mul(Q96));
                if (state.sell0) {
                    state.delta0 = amount0.mul(Q96).sub(state.amountRatioX96.mul(amount1)).div(state.amountRatioX96.mul(priceX96).div(Q96).add(Q96));
                } else {
                    state.delta0 = state.amountRatioX96.mul(amount1).sub(amount0.mul(Q96)).div(state.amountRatioX96.mul(priceX96).div(Q96).add(Q96));
                }
            }

            // adjust delta considering reward payment mode
            if (!params.isOwner) {
                if (params.bc == RewardConversion.TOKEN_0) {
                    state.rewardAmount0 = state.totalReward0;
                    if (state.sell0) {
                        if (state.delta0 >= state.totalReward0) {
                            state.delta0 = state.delta0.sub(state.totalReward0);
                        } else {
                            state.delta0 = state.totalReward0.sub(state.delta0);
                            state.sell0 = false;
                        }
                    } else {
                        state.delta0 = state.delta0.add(state.totalReward0);
                        if (state.delta0 > amount1.mul(Q96).div(priceX96)) {
                            state.delta0 = amount1.mul(Q96).div(priceX96);
                        }
                    }
                } else if (params.bc == RewardConversion.TOKEN_1) {
                    state.rewardAmount1 = state.totalReward0.mul(priceX96).div(Q96);
                    if (!state.sell0) {
                        if (state.delta0 >= state.totalReward0) {
                            state.delta0 = state.delta0.sub(state.totalReward0);
                        } else {
                            state.delta0 = state.totalReward0.sub(state.delta0);
                            state.sell0 = true;
                        }
                    } else {
                        state.delta0 = state.delta0.add(state.totalReward0);
                        if (state.delta0 > amount0) {
                            state.delta0 = amount0;
                        }
                    }
                }
            }

            if (state.delta0 > 0) {
                if (state.sell0) {
                    uint256 amountOut = _swap(
                                            abi.encodePacked(params.token0, params.fee, params.token1), 
                                            state.delta0, 
                                            params.deadline
                                        );
                    amount0 = amount0.sub(state.delta0);
                    amount1 = amount1.add(amountOut);
                } else {
                    state.delta1 = state.delta0.mul(priceX96).div(Q96);
                    // prevent possible rounding to 0 issue
                    if (state.delta1 > 0) {
                        uint256 amountOut = _swap(abi.encodePacked(params.token1, params.fee, params.token0), state.delta1, params.deadline);
                        amount0 = amount0.add(amountOut);
                        amount1 = amount1.sub(state.delta1);
                    }
                }
            }
        } else {
            if (!params.isOwner) {
                if (params.bc == RewardConversion.TOKEN_0) {
                    state.rewardAmount0 = state.totalReward0;
                } else if (params.bc == RewardConversion.TOKEN_1) {
                    state.rewardAmount1 = state.totalReward0.mul(priceX96).div(Q96);
                }
            }
        }
        
        // calculate max amount to add - considering fees (if token owner is calling - no fees)
        if (params.isOwner) {
            maxAddAmount0 = amount0;
            maxAddAmount1 = amount1;
        } else {
            // in case caller is not owner - max amounts to add are slightly lower than available amounts - to account for reward payments
            if (params.bc == RewardConversion.NONE) {
                maxAddAmount0 = amount0.mul(Q64).div(uint(totalRewardX64).add(Q64));
                maxAddAmount1 = amount1.mul(Q64).div(uint(totalRewardX64).add(Q64));
            } else {
                maxAddAmount0 = amount0 > state.rewardAmount0 ? amount0.sub(state.rewardAmount0) : 0;
                maxAddAmount1 = amount1 > state.rewardAmount1 ? amount1.sub(state.rewardAmount1) : 0;
            }
        }
    }

    function _swap(bytes memory swapPath, uint256 amount, uint256 deadline) internal returns (uint256 amountOut) {
        if (amount > 0) {
            amountOut = swapRouter.exactInput(
                ISwapRouter.ExactInputParams(swapPath, address(this), deadline, amount, 0)
            );
        }
    }
}