// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IERC20SupplyAdmin {
    error ErrMaxSupplyFrozen();

    function setMaxSupply(uint256 newValue) external;

    function freezeMaxSupply() external;

    function maxSupplyFrozen() external view returns (bool);
}