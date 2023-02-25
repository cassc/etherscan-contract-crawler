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
     * @notice Returns balance of token of callers
     * @param account Address of account
     * @param token Address of token
     * @return balance amount debted to the position at token
     */
    function callerBalances(address account, address token) external view returns (uint256 balance);

    /**
     * @notice Withdraws token balance for a caller (their fees for compounding)
     * @param tokenAddress Address of token to withdraw
     * @param to Address to send to
     */
    function withdrawBalanceCaller(address tokenAddress, address to) external;

    /**  
        @notice the parameters for the autoCompound function
        @param tokenId the tokenId being selected to compound
        @param rewardConversion true - take token0 as the caller fee, false - take token1 as the caller fee
        @param doSwap true - caller incurs the extra gas cost for 2% rewards of their selected token fee, false - caller spends less gas but gets 1.6% rewards of their specified token
    */
    struct AutoCompoundParams {
        // tokenid to autocompound
        uint256 tokenId;
        
        // which token to convert to
        bool rewardConversion;

    }

     struct SwapParams {
        address token0;
        address token1;
        uint24 fee; 
        int24 tickLower; 
        int24 tickUpper; 
        uint256 amount0;
        uint256 amount1;
    }

    struct AutoCompoundState {
        uint256 amount0;
        uint256 amount1;
        uint256 excess0;
        uint256 excess1;
        address tokenOwner;
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
    }

    struct SwapState {
        uint256 positionAmount0;
        uint256 positionAmount1;
        int24 tick;
        uint160 sqrtPriceX96;
        bool sell0;
        uint256 amountRatioX96;
        uint256 delta0;
        uint256 delta1;
        uint256 priceX96;
    }

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
    function AutoCompound25a502142c1769f58abaabfe4f9f4e8b89d24513(uint256 tokenId, bool rewardConversion) external returns (uint256 fee0, uint256 fee1, uint256 compounded0, uint256 compounded1, uint256 liqadded);

}