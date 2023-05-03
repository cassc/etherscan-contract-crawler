// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.15;

/*
  ______                     ______                                 
 /      \                   /      \                                
|  ▓▓▓▓▓▓\ ______   ______ |  ▓▓▓▓▓▓\__   __   __  ______   ______  
| ▓▓__| ▓▓/      \ /      \| ▓▓___\▓▓  \ |  \ |  \|      \ /      \ 
| ▓▓    ▓▓  ▓▓▓▓▓▓\  ▓▓▓▓▓▓\\▓▓    \| ▓▓ | ▓▓ | ▓▓ \▓▓▓▓▓▓\  ▓▓▓▓▓▓\
| ▓▓▓▓▓▓▓▓ ▓▓  | ▓▓ ▓▓    ▓▓_\▓▓▓▓▓▓\ ▓▓ | ▓▓ | ▓▓/      ▓▓ ▓▓  | ▓▓
| ▓▓  | ▓▓ ▓▓__/ ▓▓ ▓▓▓▓▓▓▓▓  \__| ▓▓ ▓▓_/ ▓▓_/ ▓▓  ▓▓▓▓▓▓▓ ▓▓__/ ▓▓
| ▓▓  | ▓▓ ▓▓    ▓▓\▓▓     \\▓▓    ▓▓\▓▓   ▓▓   ▓▓\▓▓    ▓▓ ▓▓    ▓▓
 \▓▓   \▓▓ ▓▓▓▓▓▓▓  \▓▓▓▓▓▓▓ \▓▓▓▓▓▓  \▓▓▓▓▓\▓▓▓▓  \▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓ 
         | ▓▓                                             | ▓▓      
         | ▓▓                                             | ▓▓      
          \▓▓                                              \▓▓         

 * App:             https://apeswap.finance
 * Medium:          https://ape-swap.medium.com
 * Twitter:         https://twitter.com/ape_swap
 * Discord:         https://discord.com/invite/apeswap
 * Telegram:        https://t.me/ape_swap
 * Announcements:   https://t.me/ape_swap_news
 * GitHub:          https://github.com/ApeSwapFinance
 */

import "./ApeSwapZap.sol";
import "./extensions/bills/ApeSwapZapTBills.sol";
// import "./extensions/pools/ApeSwapZapPools.sol";
import "./extensions/farms/ApeSwapZapMasterApeV2.sol";
import "./extensions/lending/ApeSwapZapLending.sol";
import "./lib/IApeRouter02.sol";

/// @author ApeSwap
/// @dev Zap contract for ApeSwap extended features such as Lending and MasterApeV2
contract ApeSwapZapExtendedV0 is
    ApeSwapZap,
    ApeSwapZapTBills,
    /* ApeSwapZapPools, */
    ApeSwapZapMasterApeV2,
    ApeSwapZapLending
{
    constructor(IApeRouter02 _router) ApeSwapZap(_router) ApeSwapZapMasterApeV2() ApeSwapZapLending() {}

    /// @notice Zap token single asset lending market
    /// @param inputToken Input token to zap
    /// @param inputAmount Amount of input tokens to zap
    /// @param path Path from input token to stake token
    /// @param minAmountsSwap The minimum amount of output tokens that must be received for swap
    /// @param deadline Unix timestamp after which the transaction will revert
    /// @param market Lending market to deposit to
    function zapLendingMarketTBill(
        IERC20 inputToken,
        uint256 inputAmount,
        address[] calldata path,
        uint256 minAmountsSwap,
        uint256 deadline,
        ICErc20 market,
        ICustomBill bill,
        uint256 maxPrice
    ) external nonReentrant {
        inputAmount = _transferIn(inputToken, inputAmount);
        _zapLendingMarketTBill(inputToken, inputAmount, path, minAmountsSwap, deadline, market, bill, maxPrice);
    }

    /// @notice Zap native token to a Lending Market
    /// @param path Path from input token to stake token
    /// @param minAmountsSwap The minimum amount of output tokens that must be received for swap
    /// @param deadline Unix timestamp after which the transaction will revert
    /// @param market Lending market to deposit to
    function zapLendingMarketTBillNative(
        address[] calldata path,
        uint256 minAmountsSwap,
        uint256 deadline,
        ICErc20 market,
        ICustomBill bill,
        uint256 maxPrice
    ) external payable nonReentrant {
        (IERC20 weth, uint256 inputAmount) = _wrapNative();
        _zapLendingMarketTBill(weth, inputAmount, path, minAmountsSwap, deadline, market, bill, maxPrice);
    }

    /** INTERNAL FUNCTIONS **/

    /// @notice Zap token single asset lending market
    /// @param inputToken Input token to zap
    /// @param inputAmount Amount of input tokens to zap
    /// @param path Path from input token to stake token
    /// @param minAmountsSwap The minimum amount of output tokens that must be received for swap
    /// @param deadline Unix timestamp after which the transaction will revert
    /// @param market Lending market to deposit to
    function _zapLendingMarketTBill(
        IERC20 inputToken,
        uint256 inputAmount,
        address[] calldata path,
        uint256 minAmountsSwap,
        uint256 deadline,
        ICErc20 market,
        ICustomBill bill,
        uint256 maxPrice
    ) internal {
        address principalToken = bill.principalToken();
        require(principalToken == address(market), "ApeSwapZapLendingTBill: principalToken must be the same as cToken");

        _zapLendingMarket(inputToken, inputAmount, path, minAmountsSwap, deadline, market);
        _depositTBill(bill, IERC20(principalToken), maxPrice, msg.sender);
    }
}