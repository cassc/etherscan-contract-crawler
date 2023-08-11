// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./UniversalERC20.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract FundsManager is OwnableUpgradeable {
    using UniversalERC20 for IERC20Upgradeable;

    /**
     * @dev Withdraw funds by owner
     * @param token Token address
     * @param amount The amount of token to withdraw
     **/
    function withdrawFunds(IERC20Upgradeable token, uint256 amount) public onlyOwner {
        token.universalTransfer(payable(owner()), amount);
    }

    /**
     * @dev Withdraw all funds by owner
     * @param tokens Token addresses array
     **/
    function withdrawAllFunds(IERC20Upgradeable[] memory tokens) public onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20Upgradeable token = tokens[i];
            token.universalTransfer(
                payable(owner()),
                token.universalBalanceOf(address(this))
            );
        }
    }
}