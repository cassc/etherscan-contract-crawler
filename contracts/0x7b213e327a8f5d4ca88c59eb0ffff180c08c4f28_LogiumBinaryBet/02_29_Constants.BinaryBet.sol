// SPDX-License-Identifier: NONE
/** =========================================================================
 *                                   LICENSE
 * 1. The Source code developed by the Owner, may be used in interaction with
 *    any smart contract only within the logium.org platform on which all
 *    transactions using the Source code shall be conducted. The source code may
 *    be also used to develop tools for trading at logium.org platform.
 * 2. It is unacceptable for third parties to undertake any actions aiming to
 *    modify the Source code of logium.org in order to adapt it to work with a
 *    different smart contract than the one indicated by the Owner by default,
 *    without prior notification to the Owner and obtaining its written consent.
 * 3. It is prohibited to copy, distribute, or modify the Source code without
 *    the prior written consent of the Owner.
 * 4. Source code is subject to copyright, and therefore constitutes the subject
 *    to legal protection. It is unacceptable for third parties to use all or
 *    any parts of the Source code for any purpose without the Owner's prior
 *    written consent.
 * 5. All content within the framework of the Source code, including any
 *    modifications and changes to the Source code provided by the Owner,
 *    constitute the subject to copyright and is therefore protected by law. It
 *    is unacceptable for third parties to use contents found within the
 *    framework of the product without the Owner’s prior written consent.
 * 6. To the extent permitted by applicable law, the Source code is provided on
 *    an "as is" basis. The Owner hereby disclaims all warranties and
 *    conditions, express or implied, including (without limitation) warranties
 *    of merchantability or fitness for a particular purpose.
 * ========================================================================= */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

/// @title Logium constants
/// @notice All constants relevant in Logium for ex. USDC address
/// @dev This library contains only "public constant" state variables
library Constants {
    /// USDC contract
    IERC20 public constant USDC =
        IERC20(address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48));
    /// Wrapped ETH contract
    IERC20 public constant WETH =
        IERC20(address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2));
    /// DAI contract
    IERC20 public constant DAI =
        IERC20(address(0x6B175474E89094C44Da98b954EedeAC495271d0F));
    /// USDT contract
    IERC20 public constant USDT =
        IERC20(address(0xdAC17F958D2ee523a2206206994597C13D831ec7));

    /// Uniswap V3 Pool for conversion rate between ETH & USDC
    IUniswapV3Pool public constant ETH_USDC_POOL =
        IUniswapV3Pool(address(0x8ad599c3A0ff1De082011EFDDc58f1908eb6e6D8));

    /// Estimated gas usage of bet exerciseOther, used for extra gas fee when exercising with bot
    /// @dev calculated based on simulations, rounded down to 100
    uint256 public constant EXERCISE_GAS = 90400;

    /// Max Fee with 9 decimal places
    uint256 public constant MAX_FEE_X9 = 20 * 10**7; //20%
}