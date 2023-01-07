// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

contract Disperse is ContextUpgradeable {
    event DisperseEther(address[] recipients, uint256[] values);
    event DisperseToken(bool bTransferFrom, IERC20 token, address[] recipients, uint256[] values, string[] names);
    event DisperseTokenSimple(IERC20 token, address[] recipients, uint256[] values, string[] names);
    ////////////////////////////////////////////////////////////////////////
    // State variables
    ////////////////////////////////////////////////////////////////////////    

    ////////////////////////////////////////////////////////////////////////
    // Events & Modifiers
    ////////////////////////////////////////////////////////////////////////

    ////////////////////////////////////////////////////////////////////////
    // Initialization functions
    ////////////////////////////////////////////////////////////////////////

    function initialize(
    ) public virtual initializer
    {
        __Context_init();
    }

    ////////////////////////////////////////////////////////////////////////
    // External functions
    ////////////////////////////////////////////////////////////////////////

    function disperseEther(address[] memory recipients, uint256[] memory values) external payable {
        for (uint256 i = 0; i < recipients.length; i++)
            payable(recipients[i]).transfer(values[i]);
        uint256 balance = address(this).balance;
        if (balance > 0)
            payable(msg.sender).transfer(balance);

        emit DisperseEther(recipients, values);
    }

    function disperseToken(bool bTransferFrom, IERC20 token, address[] memory recipients, uint256[] memory values, string[] memory names) external {
        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; i++)
            total += values[i];
        if (bTransferFrom) {
            require(token.transferFrom(msg.sender, address(this), total));
        }
        for (uint256 i = 0; i < recipients.length; i++)
            require(token.transfer(recipients[i], values[i]));

        emit DisperseToken(bTransferFrom, token, recipients, values, names);
    }

    function disperseTokenSimple(IERC20 token, address[] memory recipients, uint256[] memory values, string[] memory names) external {
        for (uint256 i = 0; i < recipients.length; i++)
            require(token.transferFrom(msg.sender, recipients[i], values[i]));

        emit DisperseTokenSimple(token, recipients, values, names);
    }
}