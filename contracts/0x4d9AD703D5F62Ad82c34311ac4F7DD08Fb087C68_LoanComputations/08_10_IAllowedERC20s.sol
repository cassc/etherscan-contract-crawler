// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IAllowedERC20s {
    function isERC20Permitted(address _erc20) external view returns (bool);
}