// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IRedeemer.sol";

interface IRedeemersBookkeeper {
    function setTickets(
        address fedMember,
        bytes32 refId,
        IRedeemer.BurnTicket memory ticket
    ) external;

    function setRoleControl(
        bytes32 role,
        address account,
        address fedMemberAddr
    ) external;

    function getRoleControl(
        bytes32 role,
        address account,
        address fedMemberAddr
    ) external view returns (bool _hasRole);

    function revokeRoleControl(
        bytes32 role,
        address account,
        address fedMemberAddr
    ) external;

    function getBurnTickets(
        address fedMember,
        bytes32 refId
    ) external view returns (IRedeemer.BurnTicket memory _burnTickets);

    function setRejectedAmounts(
        bytes32 refId,
        address fedMember,
        bool status
    ) external;

    function getRejectedAmounts(
        bytes32 refId,
        address fedMember
    ) external view returns (bool);

    function setErc20AllowListToken(
        address fedMember,
        address tokenAddress,
        bool status
    ) external;

    function getErc20AllowListToken(
        address fedMember,
        address tokenAddress
    ) external view returns (bool);

    function setRedeemerStatus(address redeemer, bool status) external;

    function getRedeemerStatus(address redeemer) external view returns (bool);

    function toGrantRole(address redeemerContract) external;
}