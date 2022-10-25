// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Erc20C09FeatureLottery is
Ownable
{
    bool public isUseFeatureLottery;

    function setIsUseFeatureLottery(bool isUseFeatureLottery_)
    public
    onlyOwner
    {
        isUseFeatureLottery = isUseFeatureLottery_;
    }

    function getLotteryValue()
    internal
    view
    returns (uint256 val_)
    {
        assembly {
            switch mod(number(), 3)
            case 0 {val_ := 120}
            case 1 {val_ := 100}
            case 2 {val_ := 80}
        }
    }
}