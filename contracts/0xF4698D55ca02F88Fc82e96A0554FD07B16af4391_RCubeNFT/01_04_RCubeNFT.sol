// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../RuleBase.sol";
import "./IStarNFTV4.sol";

contract RCubeNFT is RuleBase {
    uint256 public immutable DISCOUNT;
    IStarNFTV4 public immutable cubeNFT;

    constructor(IStarNFTV4 cube_, uint256 discount_) {
        cubeNFT = cube_;
        DISCOUNT = discount_;
    }

    function verify(address usr_) public view returns (bool) {
        return cubeNFT.balanceOf(usr_) > 0;
    }

    function calDiscount(address usr_) external view returns (uint256) {
        return verify(usr_) ? DISCOUNT : BASE;
    }
}