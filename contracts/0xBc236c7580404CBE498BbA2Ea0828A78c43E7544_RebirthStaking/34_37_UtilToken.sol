// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./ERC20.sol";
import "./Ownable.sol";

/// @title $UTIL Token
/// @author Hub3

/*
 /$$   /$$ /$$$$$$$$ /$$$$$$ /$$       /$$$$$$ /$$$$$$$$ /$$     /$$       /$$$$$$$$ /$$$$$$  /$$   /$$ /$$$$$$$$ /$$   /$$
| $$  | $$|__  $$__/|_  $$_/| $$      |_  $$_/|__  $$__/|  $$   /$$/      |__  $$__//$$__  $$| $$  /$$/| $$_____/| $$$ | $$
| $$  | $$   | $$     | $$  | $$        | $$     | $$    \  $$ /$$/          | $$  | $$  \ $$| $$ /$$/ | $$      | $$$$| $$
| $$  | $$   | $$     | $$  | $$        | $$     | $$     \  $$$$/           | $$  | $$  | $$| $$$$$/  | $$$$$   | $$ $$ $$
| $$  | $$   | $$     | $$  | $$        | $$     | $$      \  $$/            | $$  | $$  | $$| $$  $$  | $$__/   | $$  $$$$
| $$  | $$   | $$     | $$  | $$        | $$     | $$       | $$             | $$  | $$  | $$| $$\  $$ | $$      | $$\  $$$
|  $$$$$$/   | $$    /$$$$$$| $$$$$$$$ /$$$$$$   | $$       | $$             | $$  |  $$$$$$/| $$ \  $$| $$$$$$$$| $$ \  $$
 \______/    |__/   |______/|________/|______/   |__/       |__/             |__/   \______/ |__/  \__/|________/|__/  \__/
*/

contract UtilToken is ERC20, Ownable {
    mapping(address => bool) transferPrivileges;

    constructor() ERC20("Util Token", "UTIL", 18) {}

    uint256 TotalUtil = 1000000000 ether;

    function mintUtil(address recipient, uint256 amount) external {
        require(transferPrivileges[msg.sender], "Sender is not allowed to transfer $UTIL!");
        require(totalSupply + amount <= TotalUtil, "Total $UTIL amount reached");
        _mint(recipient, amount);
    }

    /*///////////////////////////////////////////////////////////////
							ADMIN UTILITIES
	//////////////////////////////////////////////////////////////*/

    function addTransferPrivileges(address contractAddress) public onlyOwner {
        transferPrivileges[contractAddress] = true;
    }

    function revokeTransferPrivileges(address contractAddress) public onlyOwner {
        transferPrivileges[contractAddress] = false;
    }

    /// @notice Allows the contract owner to burn $UTIL owned by the contract.
    function burn(uint256 amount) public onlyOwner {
        _burn(address(this), amount);
    }

    /// @notice Allows the contract owner to airdrop $UTIL owned by the contract.
    function airdrop(address[] calldata accounts, uint256[] calldata amounts) public onlyOwner {
        require(accounts.length == amounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            uint256 amount = amounts[i];
            balanceOf[address(this)] -= amount;

            // Cannot overflow because the sum of all user
            // balances can't exceed the max uint256 value.
            unchecked {
                balanceOf[accounts[i]] += amount;
            }

            emit Transfer(address(this), accounts[i], amount);
        }
    }

    /// @notice Allows the contract owner to mint $UTIL to the contract.
    function mint(uint256 amount) public onlyOwner {
        _mint(address(this), amount);
    }

    /// @notice Withdraw  $UTIL being held on this contract to the requested address.
    /// @param recipient The address to withdraw the funds to.
    /// @param amount The amount of $UTIL to withdraw
    function withdrawUTIL(address recipient, uint256 amount) public onlyOwner {
        balanceOf[address(this)] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[recipient] += amount;
        }

        emit Transfer(address(this), recipient, amount);
    }

    function updateTotalUtil(uint256 _totalUtil) public onlyOwner {
        TotalUtil = _totalUtil;
    }
}