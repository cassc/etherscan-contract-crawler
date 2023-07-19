/*
 * This file is part of the artèQ Technologies contracts (https://github.com/arteq-tech/contracts).
 * Copyright (c) 2022 artèQ Technologies (https://arteq.tech)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

/// @author Kam Amini <[email protected]>
///
/// @notice Use at your own risk
abstract contract ERC20Vault {

    event ERC20Transferred(address tokenContract, address to, uint256 amount);
    event ERC20Approved(address tokenContract, address spender, uint256 amount);

    function _ERC20Transfer(
        address tokenContract,
        address to,
        uint256 amount
    ) internal {
        require(tokenContract != address(0), "ERC20Vault: zero token address");
        require(to != address(0), "ERC20Vault: cannot transfer to zero");
        require(amount > 0, "ERC20Vault: amount is zero");
        require(amount <= IERC20(tokenContract).balanceOf(address(this)),
                                "ERC20Vault: transfer more than balance");

        IERC20(tokenContract).transfer(to, amount);
        emit ERC20Transferred(tokenContract, to, amount);
    }

    function _ERC20Approve(
        address tokenContract,
        address spender,
        uint256 amount
    ) internal {
        require(tokenContract != address(0), "ERC20Vault: zero token address");
        require(spender != address(0), "ERC20Vault: zero address for spender");

        IERC20(tokenContract).approve(spender, amount);
        emit ERC20Approved(tokenContract, spender, amount);
    }
}