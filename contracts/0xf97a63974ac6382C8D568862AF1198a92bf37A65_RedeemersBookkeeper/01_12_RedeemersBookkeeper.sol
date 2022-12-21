// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/IRedeemersBookkeeper.sol";
import "./interfaces/IRedeemer.sol";

/// @title Contract to store the state of all Redeemers
/// @author Fluent Protocol - Development Team

contract RedeemersBookkeeper is
    IRedeemersBookkeeper,
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable
{
    int public constant Version = 3;
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant REDEEMER_CONTRACT = keccak256("REDEEMER_CONTRACT");
    bytes32 public constant PM_CONTRACT = keccak256("PM_CONTRACT");

    /// @dev FedMemberAddress => _refId => ticket
    mapping(address => mapping(bytes32 => IRedeemer.BurnTicket)) burnTickets;

    /// @dev FedMemberAddress => redeemerContractAddress => _refId => bool
    mapping(address => mapping(address => mapping(bytes32 => bool)))
        public rejectedAmount;

    /// @dev FedMemberAddress => role => addressToVerify => bool
    mapping(address => mapping(bytes32 => mapping(address => bool))) roleControl;

    /// @dev Token Allow List
    /// @dev FedMemberAddress => TokenAddress => bool
    mapping(address => mapping(address => bool)) erc20AllowList;

    /// @dev called by the protocol manager
    /// @dev sets if the Redeemer Contract is active or not
    mapping(address => bool) public isRedeemerActive;

    function initialize() public initializer {
        AccessControlUpgradeable._grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        AccessControlUpgradeable._grantRole(PAUSER_ROLE, msg.sender);
    }

    function setRoleControl(
        bytes32 role,
        address account,
        address fedMemberAddr
    ) external onlyRole(REDEEMER_CONTRACT) {
        require(
            isRedeemerActive[msg.sender],
            "Redeemer Contract Caller not Active"
        );
        roleControl[fedMemberAddr][role][account] = true;
    }

    function getRoleControl(
        bytes32 role,
        address account,
        address fedMemberAddr
    ) external view returns (bool _hasRole) {
        _hasRole = roleControl[fedMemberAddr][role][account];
        return _hasRole;
    }

    function revokeRoleControl(
        bytes32 role,
        address account,
        address fedMemberAddr
    ) external onlyRole(REDEEMER_CONTRACT) {
        require(
            isRedeemerActive[msg.sender],
            "Redeemer Contract Caller not Active"
        );
        roleControl[fedMemberAddr][role][account] = false;
    }

    function setTickets(
        address fedMember,
        bytes32 refId,
        IRedeemer.BurnTicket memory ticket
    ) external onlyRole(REDEEMER_CONTRACT) {
        require(
            isRedeemerActive[msg.sender],
            "Redeemer Contract Caller not Active"
        );
        burnTickets[fedMember][refId] = ticket;
    }

    function getBurnTickets(
        address fedMember,
        bytes32 refId
    ) external view returns (IRedeemer.BurnTicket memory _burnTickets) {
        _burnTickets = burnTickets[fedMember][refId];
        return _burnTickets;
    }

    function setRejectedAmounts(
        bytes32 refId,
        address fedMember,
        bool status
    ) external onlyRole(REDEEMER_CONTRACT) {
        require(
            isRedeemerActive[msg.sender],
            "Redeemer Contract Caller not Active"
        );
        rejectedAmount[fedMember][msg.sender][refId] = status;
    }

    function getRejectedAmounts(
        bytes32 refId,
        address fedMember
    ) external view onlyRole(REDEEMER_CONTRACT) returns (bool) {
        require(
            isRedeemerActive[msg.sender],
            "Redeemer Contract Caller not Active"
        );
        return rejectedAmount[fedMember][msg.sender][refId];
    }

    function setErc20AllowListToken(
        address fedMember,
        address tokenAddress,
        bool status
    ) external onlyRole(REDEEMER_CONTRACT) {
        require(
            isRedeemerActive[msg.sender],
            "Redeemer Contract Caller not Active"
        );
        erc20AllowList[fedMember][tokenAddress] = status;
    }

    function getErc20AllowListToken(
        address fedMember,
        address tokenAddress
    ) external view onlyRole(REDEEMER_CONTRACT) returns (bool) {
        require(
            isRedeemerActive[msg.sender],
            "Redeemer Contract Caller not Active"
        );
        return erc20AllowList[fedMember][tokenAddress];
    }

    function setRedeemerStatus(
        address redeemer,
        bool status
    ) external onlyRole(PM_CONTRACT) {
        isRedeemerActive[redeemer] = status;
    }

    function getRedeemerStatus(address redeemer) external view returns (bool) {
        return isRedeemerActive[redeemer];
    }

    function toGrantRole(
        address redeemerContract
    ) external onlyRole(PM_CONTRACT) {
        AccessControlUpgradeable._grantRole(
            REDEEMER_CONTRACT,
            redeemerContract
        );
    }
}