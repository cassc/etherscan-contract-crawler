// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IDvd is IERC20 {

    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;

    function increaseShareholderPoint(address account, uint256 amount) external;

    function decreaseShareholderPoint(address account, uint256 amount) external;

    function shareholderPointOf(address account) external view returns (uint256);

    function totalShareholderPoint() external view returns (uint256);

}