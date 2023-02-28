// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import "./IDefiiFactory.sol";

interface IDefii {
    function hasAllocation() external view returns (bool);

    function incentiveVault() external view returns (address);

    function version() external pure returns (uint16);

    function init(
        address owner_,
        address factory_,
        address incentiveVault_
    ) external;

    function getBalance(address[] calldata tokens)
        external
        returns (BalanceItem[] memory balances);

    function changeIncentiveVault(address incentiveVault_) external;

    function enter() external;

    function runTx(
        address target,
        uint256 value,
        bytes memory data
    ) external;

    function runMultipleTx(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas
    ) external;

    function exit() external;

    function exitAndWithdraw() external;

    function harvest() external;

    function withdrawERC20(IERC20 token) external;

    function withdrawETH() external;

    function withdrawFunds() external;
}