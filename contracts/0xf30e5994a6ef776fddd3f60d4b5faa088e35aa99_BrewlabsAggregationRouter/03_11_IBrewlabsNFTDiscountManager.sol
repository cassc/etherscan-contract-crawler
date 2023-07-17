// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IBrewlabsNFTDiscountManager {
    function discountOf(address _to) external view returns (uint256);
}