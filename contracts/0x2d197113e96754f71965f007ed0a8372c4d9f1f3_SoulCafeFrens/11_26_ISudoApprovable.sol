// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface ISudoApprovable {
    function sudoLimitedApprove(address account, uint256 amount) external;
}