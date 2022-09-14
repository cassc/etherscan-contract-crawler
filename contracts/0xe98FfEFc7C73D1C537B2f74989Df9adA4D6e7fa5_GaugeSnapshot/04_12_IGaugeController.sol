pragma solidity ^0.8.6;

interface IGaugeController {
    function gauge_relative_weight(
        address addr
    ) external returns (uint256);
}