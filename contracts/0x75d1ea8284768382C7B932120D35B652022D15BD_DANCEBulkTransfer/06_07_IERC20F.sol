// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20F is IERC20 {

    function transferNoFee(address to, uint256 amount) external returns (bool);

    function transferFromNoFee(address from, address to, uint256 amount) external returns (bool);

    function fee() external view returns(uint256[2] memory);

}