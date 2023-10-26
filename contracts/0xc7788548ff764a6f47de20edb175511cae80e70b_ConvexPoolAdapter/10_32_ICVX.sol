pragma solidity ^0.8.10;

import { IERC20 } from "openzeppelin-contracts/token/ERC20/IERC20.sol";

interface ICVX is IERC20 {
    function totalCliffs() external view returns (uint256);
    function reductionPerCliff() external view returns (uint256);
}