// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;


import "./external/openzeppelin/token/ERC20/IERC20Metadata.sol";

import "./external/uniswap/v3-core/interfaces/IUniswapV3Factory.sol";
import "./external/uniswap/v3-periphery/interfaces/INonfungiblePositionManager.sol";
import "./external/uniswap/v3-periphery/interfaces/ISwapRouter.sol";

interface ICompounder {

    /**
     * @notice reward paid out to compounder as a fraction of the caller's collected fees. ex: if protocolReward if 5, then the protocol will take 1/5 or 20% of the caller's fees and the caller will take 80%
     * @return the protocolReward
     */
    
    function protocolReward() external view returns (uint64);

    /**
     * @notice 
     * @return the gross reward paid out to the caller. if the fee is 40, then the caller takes 1/40th of tokenA unclaimed fees or of tokenB unclaimed fees  
     */
    
    function grossCallerReward() external view returns (uint64);

    /**
     * @notice //the max slippage allowed before reverting - slippage is a result of doing calculations on current prices and ratios, but these ratios might change after the swap is made.
               //if you compound a position that results in more than this, say 0.6% slippage, then the transaction will revert
               //the caller is often rewarded with an extra 0.01-0.05% of unclaimed fees, and almost never as high as 0.5%+ unless for very unliquid positions, where there is high price impact for swapping
     * @return the this number is a denominator, so 200 means 1/200 or 0.5% slippage is allowed to be given back to the caller
     */
    
    function maxIncreaseLiqSlippage() external view returns (uint64);

    /**
     * @notice Returns unclaimed balance of token of callers
     * @param account Address of account
     * @param token Address of token
     * @return balance amount debted to the position at token
     */
    function callerBalances(address account, address token) external view returns (uint256 balance);

    /**
     * @notice Returns unclaimed balance of the protocol for a specific token
     * @param token Address of token
     * @return balance amount debted to the protocol at token
     */
    function protocolBalances(address token) external view returns (uint256 balance);


    /**
     * @notice Withdraws token balance for a caller (their fees for compounding)
     * @param tokenAddress Address of token to withdraw
     * @param to Address to send to
     */
    function withdrawBalanceCaller(address tokenAddress, address to) external;

    /**
     * @notice Withdraws token balance for the protocol
     * @param tokenAddress Address of token to withdraw
     * @param to Address to send to
     */
    function withdrawBalanceProtocol(address tokenAddress, address to) external;

    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    struct SwapParams {
        uint256 amount0;
        uint256 amount1;
        address token0;
        address token1;
        uint24 fee; 
        int24 tickLower; 
        int24 tickUpper; 
    }

    struct CompoundState {
        uint256 amount0;
        uint256 amount1;
        uint256 maxIncreaseLiqSlippage0;
        uint256 maxIncreaseLiqSlippage1;
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
    }

    struct SwapState {
        uint256 positionAmount0;
        uint256 positionAmount1;
        uint256 amountRatioX96;
        uint256 delta0;
        uint256 delta1;
        uint256 priceX96;
        uint160 sqrtPriceX96;
        int24 tick;
    }

    /**
     * @notice Compounds UniswapV3 fees for a given NFT (anyone can call this and gets a percentage of the fees)
     * @param tokenId the tokenId being selected to compound
     * @param paidIn0 true - take token0 as the caller fee, false - take token1 as the caller fee
     * @return fee0 Amount of token0 caller recieves
     * @return fee1 Amount of token1 caller recieves
     * @dev 
     */
    function compound(uint256 tokenId, bool paidIn0) external returns (uint256 fee0, uint256 fee1);

}