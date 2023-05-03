// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "../../utils/interfaces/IExpiringMetaTxForwarder.sol";
import "../../utils/interfaces/ISelfMulticall.sol";

interface IAccessControlRegistry is
    IAccessControl,
    IExpiringMetaTxForwarder,
    ISelfMulticall
{
    event InitializedManager(
        bytes32 indexed rootRole,
        address indexed manager,
        address sender
    );

    event InitializedRole(
        bytes32 indexed role,
        bytes32 indexed adminRole,
        string description,
        address sender
    );

    function initializeManager(address manager) external;

    function initializeRoleAndGrantToSender(
        bytes32 adminRole,
        string calldata description
    ) external returns (bytes32 role);
}