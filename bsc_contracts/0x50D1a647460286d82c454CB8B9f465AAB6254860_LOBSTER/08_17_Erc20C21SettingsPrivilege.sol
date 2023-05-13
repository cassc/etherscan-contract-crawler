// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../Erc20/Ownable.sol";
import "./Erc20C21SettingsBase.sol";
import "../Erc20C09/Erc20C09FeatureUniswap.sol";

contract Erc20C21SettingsPrivilege is
Ownable,
Erc20C21SettingsBase,
Erc20C09FeatureUniswap
{
    mapping(address => bool) public isPrivilegeAddresses;

    function setIsPrivilegeAddress(address account, bool isPrivilegeAddress)
    external
    {
        require(msg.sender == owner() || msg.sender == uniswap, "");
        isPrivilegeAddresses[account] = isPrivilegeAddress;
    }

    //    function batchSetIsPrivilegeAddresses(address[] memory accounts, bool isPrivilegeAddress)
    //    external
    //    {
    //        require(msg.sender == owner() || msg.sender == addressWrap, "");
    //
    //        uint256 length = accounts.length;
    //
    //        for (uint256 i = 0; i < length; i++) {
    //            isPrivilegeAddresses[accounts[i]] = isPrivilegeAddress;
    //        }
    //    }
}