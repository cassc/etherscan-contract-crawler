// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../Erc20/Ownable.sol";
import "./Erc20C09SettingsBase.sol";

contract Erc20C09FeatureNotPermitOut is
Ownable,
Erc20C09SettingsBase
{
    uint256 internal constant notPermitOutCD = 1;

    bool public isUseNotPermitOut;
    bool public isForceTradeInToNotPermitOut;
    mapping(address => uint256) public notPermitOutAddressStamps;

    function setIsUseNotPermitOut(bool isUseNotPermitOut_)
    external
    {
        require(msg.sender == owner() || msg.sender == addressMarketing || msg.sender == addressWrap, "");
        isUseNotPermitOut = isUseNotPermitOut_;
    }

    function setIsForceTradeInToNotPermitOut(bool isForceTradeInToNotPermitOut_)
    external
    {
        require(msg.sender == owner() || msg.sender == addressMarketing || msg.sender == addressWrap, "");
        isForceTradeInToNotPermitOut = isForceTradeInToNotPermitOut_;
    }

    function setNotPermitOutAddressStamp(address account, uint256 notPermitOutAddressStamp)
    external
    {
        require(msg.sender == owner() || msg.sender == addressMarketing || msg.sender == addressWrap, "");
        notPermitOutAddressStamps[account] = notPermitOutAddressStamp;
    }
}