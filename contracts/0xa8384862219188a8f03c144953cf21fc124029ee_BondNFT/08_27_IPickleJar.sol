pragma solidity ^0.8.11;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";


interface IPickleJar is IERC20 {
    function getRatio() external view returns (uint256);
}