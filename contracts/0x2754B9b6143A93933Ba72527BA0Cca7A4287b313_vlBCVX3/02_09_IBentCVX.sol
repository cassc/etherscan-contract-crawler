// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IBentCVX is IERC20 {
    function setMultisig(address _multisig) external;
    function deposit(uint256 _amount) external;
}