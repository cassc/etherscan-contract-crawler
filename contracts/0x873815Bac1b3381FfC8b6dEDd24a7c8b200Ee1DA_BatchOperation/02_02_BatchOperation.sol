// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract BatchOperation {

    struct UserERC20Balance {
        address user;
        uint256[] balance;
    }

    function batchGetBalance(address[] calldata addresses) public view returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](addresses.length);
        for (uint256 i = 0; i < addresses.length; i++) {
            balances[i] = addresses[i].balance;
        }
        return balances;
    }

    function batchIsSmartContract(address[] calldata addresses) public view returns (bool[] memory) {
        bool[] memory isSmartContracts = new bool[](addresses.length);
        for (uint256 i = 0; i < addresses.length; i++) {
            uint256 size;
            address addr = addresses[i];

            assembly {
                size := extcodesize(addr)
            }
            isSmartContracts[i] = size > 0;
        }
        return isSmartContracts;
    }

    function batchGetERC20BalanceByUser(address[] calldata addresses, address erc20Address) public view returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](addresses.length);
        for (uint256 i = 0; i < addresses.length; i++) {
            balances[i] = IERC20(erc20Address).balanceOf(addresses[i]);
        }
        return balances;
    }

    function batchGetERC20BalanceByContract(address addr, address[] calldata erc20Addresses) public view returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](erc20Addresses.length);
        for (uint256 i = 0; i < erc20Addresses.length; i++) {
            balances[i] = IERC20(erc20Addresses[i]).balanceOf(addr);
        }
        return balances;
    }

    function batchGetERC20BalanceByContractAndUser(address[] calldata addresses, address[] calldata erc20Addresses) public view returns (UserERC20Balance[] memory) {
        UserERC20Balance[] memory userERC20Balances = new UserERC20Balance[](addresses.length);
        for (uint256 i = 0; i < addresses.length; i++) {
            userERC20Balances[i].user = addresses[i];
            userERC20Balances[i].balance = batchGetERC20BalanceByContract(addresses[i], erc20Addresses);
        }
        return userERC20Balances;
    }
}