pragma solidity ^0.8.0;

import "../openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint wad) external;
}