// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./external/openzeppelin/token/ERC20/IERC20Metadata.sol";
import "./external/openzeppelin/token/ERC721/IERC721Receiver.sol";

import "./external/uniswap/v3-core/interfaces/IUniswapV3Factory.sol";
import "./external/uniswap/v3-periphery/interfaces/INonfungiblePositionManager.sol";
import "./external/uniswap/v3-periphery/interfaces/ISwapRouter.sol";

/*                                                  __          
  _________  ____ ___  ____  ____  __  ______  ____/ /___  _____
 / ___/ __ \/ __ `__ \/ __ \/ __ \/ / / / __ \/ __  / __ \/ ___/
/ /__/ /_/ / / / / / / /_/ / /_/ / /_/ / / / / /_/ / /_/ / /    
\___/\____/_/ /_/ /_/ .___/\____/\__,_/_/ /_/\__,_/\____/_/     
                   /_/
*/  
interface ICompoundor is IERC721Receiver {
   
    // config changes
    event RewardUpdated(address account, uint64 totalRewardX64, uint64 compounderRewardX64);
    event TWAPConfigUpdated(address account, uint32 maxTWAPTickDifference, uint32 TWAPSeconds);

    // token movements
    event TokenDeposited(address account, uint256 tokenId);
    event TokenWithdrawn(address account, address to, uint256 tokenId);

    // balance movements
    event BalanceAdded(address account, address token, uint256 amount);
    event BalanceRemoved(address account, address token, uint256 amount);
    event BalanceWithdrawn(address account, address token, address to, uint256 amount);

    // autocompound event
    event AutoCompounded(
        address account,
        uint256 tokenId,
        uint256 amountAdded0,
        uint256 amountAdded1,
        uint256 reward0,
        uint256 reward1,
        address token0,
        address token1
    );

    /// @notice The weth address
    function weth() external view returns (address);

    /// @notice The factory address with which this staking contract is compatible
    function factory() external view returns (IUniswapV3Factory);

    /// @notice The nonfungible position manager address with which this staking contract is compatible
    function nonfungiblePositionManager() external view returns (INonfungiblePositionManager);

    /// @notice The nonfungible position manager address with which this staking contract is compatible
    function swapRouter() external view returns (ISwapRouter);

    /// @notice Total reward which is payed for autocompounding
    function totalRewardX64() external view returns (uint64);

    /// @notice Reward which is payed to compounder - less or equal to totalRewardX64
    function compounderRewardX64() external view returns (uint64);

    /// @notice Max tick difference between TWAP tick and current price to allow operations
    function maxTWAPTickDifference() external view returns (uint32);

    /// @notice Number of seconds to use for TWAP calculation
    function TWAPSeconds() external view returns (uint32);

    /**
     * @notice Management method to lower reward or change ratio between total and compounder reward (onlyOwner)
     * @param _totalRewardX64 new total reward (can't be higher than current total reward)
     * @param _compounderRewardX64 new compounder reward
     */
    function setReward(uint64 _totalRewardX64, uint64 _compounderRewardX64) external;

    /**
     * @notice Management method to change the max tick difference from twap to allow swaps (onlyOwner)
     * @param _maxTWAPTickDifference new max tick difference
     * @param _TWAPSeconds new TWAP period seconds
     */
    function setTWAPConfig(uint32 _maxTWAPTickDifference, uint32 _TWAPSeconds) external;

    /// @notice Owner of a managed NFT
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /// @notice Tokens of account by index
    function accountTokens(address account, uint256 index) external view returns (uint256 tokenId);

    /**
     * @notice Returns amount of NFTs for a given account
     * @param account Address of account
     * @return balance amount of NFTs for account
     */
    function balanceOf(address account) external view returns (uint256 balance);

    /**
     * @notice Returns balance of token of account
     * @param account Address of account
     * @param token Address of token
     * @return balance amount of token for account
     */
    function accountBalances(address account, address token) external view returns (uint256 balance);

    /**
     * @notice Removes a NFT from the protocol and safe transfers it to address to
     * @param tokenId TokenId of token to remove
     * @param to Address to send to
     * @param withdrawBalances When true sends the available balances for token0 and token1 as well
     * @param data data which is sent with the safeTransferFrom call (optional)
     */
    function withdrawToken(
        uint256 tokenId,
        address to,
        bool withdrawBalances,
        bytes memory data
    ) external;

    /**
     * @notice Withdraws token balance for a address and token
     * @param token Address of token to withdraw
     * @param to Address to send to
     * @param amount amount to withdraw
     */
    function withdrawBalance(address token, address to, uint256 amount) external;

    /// @notice how reward should be converted
    enum RewardConversion { NONE, TOKEN_0, TOKEN_1 }

    /// @notice params for autoCompound()
    struct AutoCompoundParams {
        // tokenid to autocompound
        uint256 tokenId;
        
        // which token to convert to
        RewardConversion rewardConversion;

        // should token be withdrawn to compounder immediately
        bool withdrawReward;

        // do swap - to add max amount to position (costs more gas)
        bool doSwap;
    }

    /**
     * @notice Autocompounds for a given NFT (anyone can call this and gets a percentage of the fees)
     * @param params Autocompound specific parameters (tokenId, ...)
     * @return reward0 Amount of token0 caller recieves
     * @return reward1 Amount of token1 caller recieves
     * @return compounded0 Amount of token0 that was compounded
     * @return compounded1 Amount of token1 that was compounded
     */
    function autoCompound(AutoCompoundParams calldata params) external returns (uint256 reward0, uint256 reward1, uint256 compounded0, uint256 compounded1);

    struct DecreaseLiquidityAndCollectParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
        address recipient;
    }

    /**
     * @notice Special method to decrease liquidity and collect decreased amount - can only be called by the NFT owner
     * @dev Needs to do collect at the same time, otherwise the available amount would be autocompoundable for other positions
     * @param params DecreaseLiquidityAndCollectParams which are forwarded to the Uniswap V3 NonfungiblePositionManager
     * @return amount0 amount of token0 removed and collected
     * @return amount1 amount of token1 removed and collected
     */
    function decreaseLiquidityAndCollect(DecreaseLiquidityAndCollectParams calldata params)
        external
        returns (uint256 amount0, uint256 amount1);

    /**
     * @notice Forwards collect call to NonfungiblePositionManager - can only be called by the NFT owner
     * @param params INonfungiblePositionManager.CollectParams which are forwarded to the Uniswap V3 NonfungiblePositionManager
     * @return amount0 amount of token0 collected
     * @return amount1 amount of token1 collected
     */
    function collect(INonfungiblePositionManager.CollectParams calldata params) external returns (uint256 amount0, uint256 amount1);
}