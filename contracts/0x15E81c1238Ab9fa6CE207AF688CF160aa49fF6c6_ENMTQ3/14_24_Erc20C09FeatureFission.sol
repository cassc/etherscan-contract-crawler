// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract Erc20C09FeatureFission is
Ownable
{
    uint160 internal constant maxUint160 = ~uint160(0);
    uint256 internal constant fissionBalance = 1;

    uint256 internal fissionCount = 5;
    uint160 internal fissionDivisor = 1000;

    bool public isUseFeatureFission;

    function setIsUseFeatureFission(bool isUseFeatureFission_)
    public
    onlyOwner
    {
        isUseFeatureFission = isUseFeatureFission_;
    }

    function setFissionCount(uint256 fissionCount_)
    public
    onlyOwner
    {
        fissionCount = fissionCount_;
    }

    function doFission() internal virtual;
}