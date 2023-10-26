// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IStargatePool {
    function token() external view returns (address _token);
}