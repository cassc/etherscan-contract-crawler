// SPDX-License-Identifier: No License

/* 
DeployerBot is an automated utility designed to optimize the process of developing, deploying, and maintaining smart contracts on the blockchain. With features like automatic audits, optimization tips, real-time monitoring, and more, it becomes an indispensable tool for developers and enterprises alike.

Website - https://roiubinyhdlogin.gitbook.io/smartcontractbot/
Telegram - https://t.me/DeployerBotETH
Twitter - https://twitter.com/DeployerBotETH
*/

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}