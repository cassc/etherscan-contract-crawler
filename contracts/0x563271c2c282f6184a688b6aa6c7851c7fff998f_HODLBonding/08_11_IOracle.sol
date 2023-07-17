// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IOracle {
    function consult(address tokenIn, uint256 amountIn, address tokenOut) external view returns (uint256 amountOut);

    function convertETHToUSDC(uint256 ethAmount) external view returns (uint256 usdAmount);

    function convertETHToUSDT(uint256 ethAmount) external view returns (uint256 usdAmount);

    function convertUSDCToETH(uint256 usdAmount) external view returns (uint256 ethAmount);

    function convertUSDTToETH(uint256 usdAmount) external view returns (uint256 ethAmount);

    function convertUSDToETH(uint256 usdAmount) external view returns (uint256 ethAmount);

    function ethusd() external view returns (address);

    function getAllObservations() external view returns (SlidingWindowOracle.Observation[] memory);

    function getFirstObservationInWindow()
        external
        view
        returns (SlidingWindowOracle.Observation memory firstObservation);

    function getPriceInETH(uint256 tokenAmount) external view returns (uint256 ethAmount);

    function getPriceInUSDC(uint256 tokenAmount) external view returns (uint256 usdAmount);

    function getPriceInUSDT(uint256 tokenAmount) external view returns (uint256 usdAmount);

    function granularity() external view returns (uint8);

    function observationIndexOf(uint256 timestamp) external view returns (uint8 index);

    function owner() external view returns (address);

    function pair() external view returns (address);

    function pairObservations(
        uint256
    ) external view returns (uint256 timestamp, uint256 price0Cumulative, uint256 price1Cumulative);

    function periodSize() external view returns (uint256);

    function priceFeed() external view returns (address);

    function renounceOwnership() external;

    function setChainlink(address _feed, bool _isUsing) external;

    function token() external view returns (address);

    function transferOwnership(address newOwner) external;

    function update() external;

    function usdcusd() external view returns (address);

    function usdtusd() external view returns (address);

    function weth() external view returns (address);

    function windowSize() external view returns (uint256);
}

interface SlidingWindowOracle {
    struct Observation {
        uint256 timestamp;
        uint256 price0Cumulative;
        uint256 price1Cumulative;
    }
}