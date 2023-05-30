//SPDX-License-Identifier: Unlicense
pragma solidity 0.7.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Detailed is IERC20 {
    function decimals() external view returns (uint8);
}

interface IVault {
    function harvest(uint amount) external returns (uint afterFee);
    function distribute(uint amount) external;
    function underlying() external view returns (IERC20Detailed);
    function target() external view returns (IERC20);
    function owner() external view returns (address);
}