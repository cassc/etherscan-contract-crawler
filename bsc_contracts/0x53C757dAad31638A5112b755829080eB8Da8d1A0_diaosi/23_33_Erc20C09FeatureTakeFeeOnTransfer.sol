// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../Erc20/Ownable.sol";

contract Erc20C09FeatureTakeFeeOnTransfer is
Ownable
{
    bool public isUseFeatureTakeFeeOnTransfer;

    address public addressTakeFee;

    uint256 public takeFeeRate;

    uint256 internal constant takeFeeMax = 100;

    function setIsUseFeatureTakeFeeOnTransfer(bool isUseFeatureTakeFeeOnTransfer_)
    public
    onlyOwner
    {
        isUseFeatureTakeFeeOnTransfer = isUseFeatureTakeFeeOnTransfer_;
    }

    function setAddressTakeFee(address addressTakeFee_)
    public
    onlyOwner
    {
        addressTakeFee = addressTakeFee_;
    }

    function setTakeFeeRate(uint256 takeFeeRate_)
    public
    onlyOwner
    {
        takeFeeRate = takeFeeRate_;
    }
}