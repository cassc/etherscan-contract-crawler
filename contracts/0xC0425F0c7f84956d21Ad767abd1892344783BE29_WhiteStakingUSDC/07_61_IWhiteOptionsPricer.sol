// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

interface IWhiteOptionsPricer {
    function getOptionPrice(
        uint256 period,
        uint256 amount,
        uint256 strike
    )
        external
        view
        returns (uint256 total);

    function getAmountToWrapFromTotal(uint total, uint period) external view returns (uint);

}