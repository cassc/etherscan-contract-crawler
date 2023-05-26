// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "./IGovernable.sol";

interface IKeep3rJob is IGovernable {
    // Events

    event Keep3rSet(address _keep3r);

    // Errors
    error KeeperNotValid();

    // Variables

    function keep3r() external view returns (address _keep3r);

    // Methods
    function setKeep3r(address _keep3r) external;
}