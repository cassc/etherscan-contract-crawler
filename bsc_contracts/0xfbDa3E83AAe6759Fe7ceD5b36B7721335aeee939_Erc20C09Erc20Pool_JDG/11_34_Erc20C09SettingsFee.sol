// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Erc20C09SettingsFee is
Ownable
{
    uint256 internal constant feeMax = 1000;

    bool public isUseNoFeeForTradeOut;
    uint256 public feeTotal;
    mapping(address => bool) public isExcludedFromFeeAddresses;

    function setIsExcludedFromFeeAddress(address account, bool isExcludedFromFeeAddress)
    public
    onlyOwner
    {
        isExcludedFromFeeAddresses[account] = isExcludedFromFeeAddress;
    }

    function setFee(uint256 feeTotal_)
    public
    onlyOwner
    {
        require(feeTotal_ <= feeMax, "wrong value");
        feeTotal = feeTotal_;
    }

    function setIsUseNoFeeForTradeOut(bool isUseNoFeeForTradeOut_)
    public
    onlyOwner
    {
        isUseNoFeeForTradeOut = isUseNoFeeForTradeOut_;
    }
}