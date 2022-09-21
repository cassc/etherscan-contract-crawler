// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title This interface is specific for the frigg router gater
/// @author Frigg team
interface IRouterGater {
    function goldfinchLogic(address _account) external view returns (bool);

    function quadrataLogic(address _account) external payable returns (bool);

    function checkGatedStatus(address _account) external payable returns (bool);
}