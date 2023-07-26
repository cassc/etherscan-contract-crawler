pragma solidity ^0.8.13;

interface IOracle {
    struct FeedData {
        IChainlinkFeed feed;
        uint8 tokenDecimals;
    }

    //public variables
    function operator() external view returns(address);
    function pendingOperator() external view returns(address);
    //public mappings
    function feeds(address token) external view returns (FeedData memory); 
    function dailyLows(address token, uint day) external view returns(uint price);
    //public functions
    function viewPrice(address token, uint collateralFactorBps) external view returns (uint);
    function getPrice(address token, uint collateralFactorBps) external returns(uint);
    function getFeedPrice(address token) external view returns(uint);
}

interface IChainlinkFeed {
    function decimals() external view returns (uint8);
    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80);
}