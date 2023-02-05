// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../vaults/BaseVaults/HashnoteOptionsVault.sol";

/**
 * @title   MockHashnoteOptionsVault
 * @notice  Mock contract to test fees
 */
contract MockHashnoteOptionsVault is HashnoteOptionsVault {
    constructor(address _share, address _marginEngine) HashnoteOptionsVault(_share, _marginEngine) { }

    function transferOut(address erc20, address recipient, uint256 amount) external {
        IERC20(erc20).transfer(recipient, amount);
    }
}