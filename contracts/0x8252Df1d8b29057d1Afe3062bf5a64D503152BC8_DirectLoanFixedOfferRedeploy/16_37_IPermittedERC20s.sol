// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

interface IPermittedERC20s {
    function getERC20Permit(address _erc20) external view returns (bool);
}