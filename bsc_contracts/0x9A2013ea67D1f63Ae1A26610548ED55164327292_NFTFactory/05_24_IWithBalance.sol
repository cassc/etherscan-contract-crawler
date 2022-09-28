// SPDX-License-Identifier: bsl-1.1
/**
 * Copyright 2022 Raise protocol ([email protected])
 */
pragma solidity ^0.8.0;

interface IWithBalance {

    /**
     * @dev Works both for ERC721 and ERC20
     */
    function balanceOf(address owner) external view returns (uint256 balance);
}