/*
     ____.  _____ _____________________    _____  .___ 
    |    | /  _  \\______   \__    ___/   /  _  \ |   |
    |    |/  /_\  \|       _/ |    |     /  /_\  \|   |
/\__|    /    |    \    |   \ |    |    /    |    \   |
\________\____|__  /____|_  / |____| /\ \____|__  /___|
                 \/       \/         \/         \/     


Transform words into stunning art 

Website: https://jart.ai/
Twitter: https://twitter.com/jart_ai
Telegram: https://t.me/jart_ai

Total supply: 420,690,000 tokens
Tax: 4% (1% - LP, 1% - operational costs, 2% marketing)
*/



// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}