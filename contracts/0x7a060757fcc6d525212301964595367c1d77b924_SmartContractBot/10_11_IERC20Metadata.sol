// SPDX-License-Identifier: No License

/* 
SmartContractBot is an automated utility designed to optimize the process of developing, deploying, and maintaining smart contracts on the blockchain. With features like automatic audits, optimization tips, real-time monitoring, and more, it becomes an indispensable tool for developers and enterprises alike.

Website - https://roiubinyhdlogin.gitbook.io/smartcontractbot/
Telegram - https://t.me/SmartContractBotEth
Twitter - https://twitter.com/ContractBotEth
*/

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";

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