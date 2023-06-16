pragma solidity 0.5.15;

// checked for busd pool
interface ICrvPoolUnderlying {
    function get_virtual_price() external view returns (uint256);
}