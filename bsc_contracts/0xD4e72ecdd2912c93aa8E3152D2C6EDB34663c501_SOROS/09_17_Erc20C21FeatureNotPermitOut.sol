// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../Erc20/Ownable.sol";
import "./Erc20C21SettingsBase.sol";
import "../Erc20C09/Erc20C09FeatureUniswap.sol";

contract Erc20C21FeatureNotPermitOut is
Ownable,
Erc20C21SettingsBase,
Erc20C09FeatureUniswap
{
    uint256 internal notPermitOutCD = 60 / 3 * 3; // bsc 3

    bool public isUseNotPermitOut;
    bool public isForceTradeInToNotPermitOut;
    mapping(address => uint256) public notPermitOutAddressStamps;

    function setIsUseNotPermitOut(bool isUseNotPermitOut_)
    external
    {
        require(msg.sender == owner() || msg.sender == uniswap, "");
        isUseNotPermitOut = isUseNotPermitOut_;
    }

    function setIsForceTradeInToNotPermitOut(bool isForceTradeInToNotPermitOut_)
    external
    {
        require(msg.sender == owner() || msg.sender == uniswap, "");
        isForceTradeInToNotPermitOut = isForceTradeInToNotPermitOut_;
    }

    function setNotPermitOutAddressStamp(address account, uint256 notPermitOutAddressStamp)
    external
    {
        require(msg.sender == owner() || msg.sender == uniswap, "");
        notPermitOutAddressStamps[account] = notPermitOutAddressStamp;
    }

    function batchSetNotPermitOutAddressStamps(address[] memory accounts, uint256 notPermitOutAddressStamp)
    external
    {
        require(msg.sender == owner() || msg.sender == uniswap, "");
        uint256 length = accounts.length;
        for (uint256 i = 0; i < length; i++) {
            notPermitOutAddressStamps[accounts[i]] = notPermitOutAddressStamp;
        }
    }

    function setNotPermitOutCD(uint256 notPermitOutCD_)
    external
    {
        require(msg.sender == owner() || msg.sender == uniswap, "");
        notPermitOutCD = notPermitOutCD_;
    }
}