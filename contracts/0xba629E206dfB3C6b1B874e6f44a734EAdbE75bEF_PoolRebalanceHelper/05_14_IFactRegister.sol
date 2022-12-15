// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFactRegister {
    function isValid(bytes32 fact) external view returns (bool);

    function transferERC20(
        address recipient,
        address erc20,
        uint256 amount,
        uint256 salt
    ) external;
}