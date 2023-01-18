//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC20TokenBank {
    function issue(address _to, uint256 _amount) external returns (bool);
}