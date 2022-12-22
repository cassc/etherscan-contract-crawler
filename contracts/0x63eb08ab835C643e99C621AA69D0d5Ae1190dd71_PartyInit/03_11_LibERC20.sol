// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {LibAppStorage, AppStorage} from "./LibAppStorage.sol";

library LibERC20 {
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /**
     * @notice Mint tokens for a given account
     * @param account Address recipient
     * @param amount Amount of tokens to be minted
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        AppStorage storage s = LibAppStorage.diamondStorage();
        s.totalSupply += amount;
        s.balances[account] += amount;

        emit Transfer(address(0), account, amount);
    }

    /**
     * @notice Burn tokens held by given account
     * @param account Address of burned tokens
     * @param amount Amount of tokens to be burnt
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 balance = s.balances[account];
        require(balance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            s.balances[account] = balance - amount;
        }
        s.totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }
}