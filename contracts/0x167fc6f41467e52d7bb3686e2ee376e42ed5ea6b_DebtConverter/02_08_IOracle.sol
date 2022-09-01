pragma solidity ^0.8.0;

struct FeedData {
    address addr;
    uint8 tokenDecimals;
}

interface IOracle {
    function setFeed(
        address cToken_,
        address feed_,
        uint8 tokenDecimals_
    ) external;

    function getUnderlyingPrice(address cToken_)
        external
        view
        returns (uint256);


}