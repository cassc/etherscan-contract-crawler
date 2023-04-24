// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./IPermissions.sol";
import "../chi/IChi.sol";

/// @title Core Interface
interface ICore is IPermissions {
    // ----------- Events -----------

    event ChiUpdate(address indexed _chi);
    event ZenUpdate(address indexed _zen);
    event GenesisGroupUpdate(address indexed _genesisGroup);
    event ZenAllocation(address indexed _to, uint256 _amount);
    event GenesisPeriodComplete(uint256 _timestamp);

    // ----------- Governor only state changing api -----------

    function init() external;

    // ----------- Governor only state changing api -----------

    function setChi(address token) external;

    function setZen(address token) external;

    function allocateZen(address to, uint256 amount) external;

    // ----------- Getters -----------

    function chi() external view returns (IChi);

    function zen() external view returns (IERC20);
}