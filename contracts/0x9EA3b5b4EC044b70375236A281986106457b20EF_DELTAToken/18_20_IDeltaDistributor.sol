pragma solidity ^0.7.6;

interface IDeltaDistributor {
    function creditUser(address,uint256) external;
    function addDevested(address, uint256) external;
    function distribute() external;
}