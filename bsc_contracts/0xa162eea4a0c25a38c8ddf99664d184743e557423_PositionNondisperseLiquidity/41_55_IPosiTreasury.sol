/**
 * @author Musket
 */
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

interface IPosiTreasury {
    function mint(address recipient, uint256 amount) external;
}