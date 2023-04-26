// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../Erc20/Ownable.sol";

contract Erc20C09SettingsPrivilege is
Ownable
{
    mapping(address => bool) public isPrivilegeAddresses;

    function setIsPrivilegeAddress(address account, bool isPrivilegeAddress)
    external
    onlyOwner
    {
        isPrivilegeAddresses[account] = isPrivilegeAddress;
    }

    function batchSetIsPrivilegeAddresses(address[] memory accounts, bool isPrivilegeAddress)
    external
    onlyOwner
    {
        uint256 length = accounts.length;

        for (uint256 i = 0; i < length; i++) {
            isPrivilegeAddresses[accounts[i]] = isPrivilegeAddress;
        }
    }
}