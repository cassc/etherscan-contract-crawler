// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/token/ERC20/IERC20.sol";

interface IAmplifi is IERC20 {
    function burnForAmplifier(address _burnee, uint256 _amount) external returns (bool);
}