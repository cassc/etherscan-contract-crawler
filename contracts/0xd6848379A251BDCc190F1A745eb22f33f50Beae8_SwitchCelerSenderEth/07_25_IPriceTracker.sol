pragma solidity ^0.8.0;

interface IPriceTracker {
    function getPrice(uint256 _srcChainId, uint256 _dstChainId) external view returns(uint256);
}