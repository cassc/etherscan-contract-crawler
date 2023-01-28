pragma solidity ^0.8.0;


interface MinterIERC20 {
    function mint(address to, uint256 amount) external;
}