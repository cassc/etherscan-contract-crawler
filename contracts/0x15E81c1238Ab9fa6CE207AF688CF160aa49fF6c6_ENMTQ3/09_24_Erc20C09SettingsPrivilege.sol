// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";

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
}