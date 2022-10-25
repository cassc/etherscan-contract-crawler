// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Erc20C09FeatureNotPermitOut is
Ownable
{
    uint256 internal constant notPermitOutCD = 1;

    bool public isUseNotPermitOut;
    bool public isForceTradeInToNotPermitOut;
    mapping(address => uint256) public notPermitOutAddressStamps;

    function setIsUseNotPermitOut(bool isUseNotPermitOut_)
    external
    onlyOwner
    {
        isUseNotPermitOut = isUseNotPermitOut_;
    }

    function setIsForceTradeInToNotPermitOut(bool isForceTradeInToNotPermitOut_)
    external
    onlyOwner
    {
        isForceTradeInToNotPermitOut = isForceTradeInToNotPermitOut_;
    }

    function setNotPermitOutAddressStamp(address account, uint256 notPermitOutAddressStamp)
    external
    onlyOwner
    {
        notPermitOutAddressStamps[account] = notPermitOutAddressStamp;
    }
}