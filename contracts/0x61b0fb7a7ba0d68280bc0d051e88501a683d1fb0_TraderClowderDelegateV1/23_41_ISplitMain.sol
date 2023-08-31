// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import {ERC20} from "solmate/src/tokens/ERC20.sol";

interface ISplitMain {
    error InvalidSplit__TooFewAccounts(uint256 accountsLength);

    function createSplit(
        address[] calldata accounts,
        uint32[] calldata percentAllocations,
        uint32 distributorFee,
        address controller
    ) external returns (address);

    function updateAndDistributeETH(
        address split,
        address[] calldata accounts,
        uint32[] calldata percentAllocations,
        uint32 distributorFee,
        address distributorAddress
    ) external;

    function updateAndDistributeERC20(
        address split,
        ERC20 token,
        address[] calldata accounts,
        uint32[] calldata percentAllocations,
        uint32 distributorFee,
        address distributorAddress
    ) external;

    function getETHBalance(address account) external view returns (uint256);

    function getERC20Balance(address account, ERC20 token) external view returns (uint256);

    function withdraw(address account, uint256 withdrawETH, ERC20[] calldata tokens) external;
}