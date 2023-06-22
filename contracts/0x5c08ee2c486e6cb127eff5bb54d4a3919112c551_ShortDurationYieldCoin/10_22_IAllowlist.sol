// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IAllowlist {
    function hasTokenPrivileges(address _subAccount) external view returns (bool);

    function isOTC(address _address) external view returns (bool);
}