// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface IController {
    function isAdmin(address account) external view returns (bool);

    function isRegistrar(address account) external view returns (bool);

    function isOracle(address account) external view returns (bool);

    function isValidator(address account) external view returns (bool);

    function owner() external view returns (address);

    function validatorsCount() external view returns (uint256);

    function settings() external view returns (address);

    function deployer() external view returns (address);

    function feeController() external view returns (address);
}