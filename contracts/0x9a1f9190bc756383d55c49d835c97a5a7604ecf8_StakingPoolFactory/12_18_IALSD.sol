// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IALSD is IERC20 {
    function lastEmissionTime() external view returns (uint256);

    function mintIncentiveLiquidity(uint256 amount) external returns (bool);


    function burn(uint256 amount) external;
}