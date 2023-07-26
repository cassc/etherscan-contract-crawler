//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IFlashloanExecutor {
    function executeOperation(
        address reserve,
        uint256 amount,
        uint256 fee,
        bytes memory data
    ) external;
}