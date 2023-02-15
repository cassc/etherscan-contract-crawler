pragma solidity ^0.8.9;

interface IPriceFeed {
    function getTomiPrice() external view returns(uint256);
}