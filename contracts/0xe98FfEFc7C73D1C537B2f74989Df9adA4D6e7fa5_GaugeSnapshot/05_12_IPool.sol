pragma solidity ^0.8.6;

interface IPool {
    function get_virtual_price() external returns (uint256);
}