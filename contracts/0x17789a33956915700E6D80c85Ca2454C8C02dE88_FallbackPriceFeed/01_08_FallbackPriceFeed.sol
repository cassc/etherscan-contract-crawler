// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract FallbackPriceFeed is AggregatorV3Interface, AccessControl {
    uint256 public constant version = 1;
    // slither-disable-next-line immutable-states
    string public description;
    uint8 public immutable decimals;
    int256 public price;

    constructor(
        address _admin,
        string memory _description,
        uint8 _decimals,
        int256 _price
    ) {
        description = _description;
        decimals = _decimals;
        price = _price;
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    function setPrice(int256 newPrice) external onlyRole(DEFAULT_ADMIN_ROLE) {
        price = newPrice;
    }

    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (_roundId, price, block.timestamp, block.timestamp, _roundId);
    }

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (1, price, block.timestamp, block.timestamp, 1);
    }
}