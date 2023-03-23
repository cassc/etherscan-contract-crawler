// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract PriceFeedMock {
    uint256 public mockedPrice;

    constructor(uint256 _mockedPrice) {
        mockedPrice = _mockedPrice;
    }

    function mockPrice(uint256 _mockedPrice) external {
        mockedPrice = _mockedPrice;
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80) {
        return (0, int256(mockedPrice), 0, 0, 0);
    }
}