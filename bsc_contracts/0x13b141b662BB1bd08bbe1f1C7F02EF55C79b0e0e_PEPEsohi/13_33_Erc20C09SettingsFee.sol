// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../Erc20/Ownable.sol";

contract Erc20C09SettingsFee is
Ownable
{
    uint256 internal constant feeMax = 1000;

    uint256 public feeBuyTotal;
    uint256 public feeSellTotal;

    function setFee(uint256 feeBuyTotal_, uint256 feeSellTotal_)
    public
    onlyOwner
    {
        feeBuyTotal = feeBuyTotal_;
        feeSellTotal = feeSellTotal_;
    }
}