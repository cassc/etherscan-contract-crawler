pragma solidity ^0.6.12;

import "./IERC20.sol";


interface ILedgity is IERC20 {
    function burn(uint256 amount) external returns (bool);
}