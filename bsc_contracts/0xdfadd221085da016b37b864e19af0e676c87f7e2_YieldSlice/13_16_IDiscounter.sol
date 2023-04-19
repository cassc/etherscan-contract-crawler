// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IDiscounter {
    function DISCOUNT_PERIOD() external view returns (uint256);

    function setDaily(uint256 daily) external;
    function setMaxDays(uint256 maxDays) external;

    function discounted(uint256 generator, uint256 yield) external view returns (uint256);
    function pv(uint256 numDays, uint256 nominal) external view returns (uint256);
    function nominal(uint256 numDays, uint256 pv) external view returns (uint256);
    function shiftNPV(uint256 npv, uint256 numDays) external view returns (uint256);
}