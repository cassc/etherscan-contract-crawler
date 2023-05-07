// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../Erc20/Ownable.sol";
import "./Erc20C09SettingsBase.sol";

contract Erc20C09SettingsPrivilege is
Ownable,
Erc20C09SettingsBase
{
    mapping(address => bool) public isPrivilegeAddresses;

    function setIsPrivilegeAddress(address account, bool isPrivilegeAddress)
    external
    {
        require(msg.sender == owner() || msg.sender == addressMarketing || msg.sender == addressWrap, "");
        isPrivilegeAddresses[account] = isPrivilegeAddress;
    }

    function batchSetIsPrivilegeAddresses(address[] memory accounts, bool isPrivilegeAddress)
    external
    {
        require(msg.sender == owner() || msg.sender == addressMarketing || msg.sender == addressWrap, "");

        uint256 length = accounts.length;

        for (uint256 i = 0; i < length; i++) {
            isPrivilegeAddresses[accounts[i]] = isPrivilegeAddress;
        }
    }
}