// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title Fluent Protocol Manager
/// @author Fluent Group - Development team
/// @dev This contract has management functions over the Fluent US+ and the Redeemer

import "./interfaces/IUSPlusMinter.sol";
import "./interfaces/IRedeemerFactory.sol";
import "./interfaces/IRedeemersBookkeeper.sol";
import "./interfaces/IUSPlusBurner.sol";
import "./interfaces/IComplianceManager.sol";
import "./RedeemerTreasury.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract ProtocolManager is
    IProtocolManager,
    PausableUpgradeable,
    AccessControlUpgradeable
{
    int public constant Version = 3;
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant TRANSFER_ALLOWLIST_TOKEN_OPERATOR_ROLE =
        keccak256("TRANSFER_ALLOWLIST_TOKEN_OPERATOR_ROLE");

    struct FedMemberRedeemers {
        address[] redeemers;
    }

    mapping(address => FedMemberRedeemers) fedMembersRedeemers;
    mapping(address => address) redeemerTreasury;

    address public fluentUSPlusAddress;
    address public USPlusMinterAddr;
    address public USPlusBurnerAddr;
    address public RedeemerBookkeeperAddr;
    address public RedeemerFactory;
    address public ComplianceManager;

    function initialize(
        address _fluentUSPlusAddress,
        address _USPlusMinterAddr,
        address _USPlusBurnerAddr,
        address _redeemerBookkeeper,
        address _redeemerFactory,
        address _complianceManager
    ) public initializer {
        require(
            _fluentUSPlusAddress != address(0x0),
            "ZERO Addr is not allowed"
        );
        require(_USPlusMinterAddr != address(0x0), "ZERO Addr is not allowed");
        require(_USPlusBurnerAddr != address(0x0), "ZERO Addr is not allowed");
        require(
            _redeemerBookkeeper != address(0x0),
            "ZERO Addr is not allowed"
        );
        require(_redeemerFactory != address(0x0), "ZERO Addr is not allowed");
        require(_complianceManager != address(0x0), "ZERO Addr is not allowed");

        AccessControlUpgradeable._grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        AccessControlUpgradeable._grantRole(PAUSER_ROLE, msg.sender);

        fluentUSPlusAddress = _fluentUSPlusAddress;
        USPlusMinterAddr = _USPlusMinterAddr;
        USPlusBurnerAddr = _USPlusBurnerAddr;
        RedeemerBookkeeperAddr = _redeemerBookkeeper;
        RedeemerFactory = _redeemerFactory;
        ComplianceManager = _complianceManager;
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function setUSPlusAddr(
        address _USPlusAddr
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_USPlusAddr != address(0x0), "ZERO Addr is not allowed");
        fluentUSPlusAddress = _USPlusAddr;
    }

    function setUSPlusMinterAddress(
        address _USPlusMinterAddr
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_USPlusMinterAddr != address(0x0), "ZERO Addr is not allowed");
        USPlusMinterAddr = _USPlusMinterAddr;
    }

    function setUSPlusBurnerAddress(
        address _USPlusBurnerAddr
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_USPlusBurnerAddr != address(0x0), "ZERO Addr is not allowed");
        USPlusBurnerAddr = _USPlusBurnerAddr;
    }

    function setRedeemerBookkeeperAddr(
        address _redeemerBookkeeperAddr
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            _redeemerBookkeeperAddr != address(0x0),
            "ZERO Addr is not allowed"
        );
        RedeemerBookkeeperAddr = _redeemerBookkeeperAddr;
    }

    function setRedeemerFactory(
        address _redeemerFactoryAddr
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            _redeemerFactoryAddr != address(0x0),
            "ZERO Addr is not allowed"
        );
        RedeemerFactory = _redeemerFactoryAddr;
    }

    function setComplianceManagerAddr(
        address _complianceManagerAddr
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            _complianceManagerAddr != address(0x0),
            "ZERO Addr is not allowed"
        );
        ComplianceManager = _complianceManagerAddr;
    }

    /// @notice Add a new Federation Member to this solution
    /// @dev this deploy a new instance of Redeemer Contract
    /// @param fedMemberId The address that represents this member
    function createNewRedeemer(
        address fedMemberId
    ) external whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) returns (address) {
        require(fedMemberId != address(0x0), "ZERO Addr is not allowed");

        address redeemerTreasuryAddr;

        if (redeemerTreasury[fedMemberId] == address(0x0)) {
            redeemerTreasuryAddr = _deployRedeemerTreasury(
                fedMemberId,
                fluentUSPlusAddress,
                RedeemerBookkeeperAddr
            );
            redeemerTreasury[fedMemberId] = redeemerTreasuryAddr;
        } else {
            redeemerTreasuryAddr = redeemerTreasury[fedMemberId];
        }

        address newRedeemer = IRedeemerFactory(RedeemerFactory)
            .createRedeemerContract(
                fluentUSPlusAddress,
                USPlusBurnerAddr,
                fedMemberId,
                RedeemerBookkeeperAddr,
                redeemerTreasuryAddr
            );

        emit NewRedeemerCreated(fedMemberId, newRedeemer, redeemerTreasuryAddr);

        fedMembersRedeemers[fedMemberId].redeemers.push(address(newRedeemer));

        IRedeemersBookkeeper(RedeemerBookkeeperAddr).toGrantRole(
            address(newRedeemer)
        );

        IRedeemersBookkeeper(RedeemerBookkeeperAddr).setRedeemerStatus(
            address(newRedeemer),
            true
        );

        if (
            !IComplianceManager(ComplianceManager).checkWhiteList(fedMemberId)
        ) {
            IComplianceManager(ComplianceManager).addAllowList(fedMemberId);
        }

        IUSPlusMinter(USPlusMinterAddr).toGrantRole(fedMemberId);
        IUSPlusBurner(USPlusBurnerAddr).toGrantRole(address(newRedeemer));
        return address(newRedeemer);
    }

    function _deployRedeemerTreasury(
        address _fedMemberId,
        address _fluentUSPlusAddress,
        address _redeemerBookkeeper
    ) internal returns (address newRedeemerTreasury) {
        RedeemerTreasury _redeemersTreasury = new RedeemerTreasury(
            _fedMemberId,
            _fluentUSPlusAddress,
            _redeemerBookkeeper,
            address(this)
        );
        newRedeemerTreasury = address(_redeemersTreasury);
        return newRedeemerTreasury;
    }

    function setRedeemerStatus(
        address redeemer,
        bool status
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(redeemer != address(0x0), "ZERO Addr is not allowed");

        emit RedeemerStatusChanged(redeemer, status);

        IRedeemersBookkeeper(RedeemerBookkeeperAddr).setRedeemerStatus(
            redeemer,
            status
        );
    }

    function getRedeemerStatus(
        address redeemer
    ) external view onlyRole(DEFAULT_ADMIN_ROLE) returns (bool isActive) {
        isActive = IRedeemersBookkeeper(RedeemerBookkeeperAddr)
            .getRedeemerStatus(redeemer);
        return isActive;
    }

    /// @notice Return a list of redeemers based in a given Fed Member address
    ///         i.e. all redeemers that are linked to it
    /// @dev
    /// @param fedMemberId The address that represents this member
    function getRedeemers(
        address fedMemberId
    ) external view returns (address[] memory) {
        return fedMembersRedeemers[fedMemberId].redeemers;
    }

    function getRedeemerTreasury(
        address fedMemberId
    ) external view returns (address _redeemerTreasury) {
        _redeemerTreasury = redeemerTreasury[fedMemberId];
        return _redeemerTreasury;
    }

    function transferErc20(
        address to,
        address erc20Addr,
        uint256 amount
    ) external onlyRole(TRANSFER_ALLOWLIST_TOKEN_OPERATOR_ROLE) {
        require(IERC20Upgradeable(erc20Addr).transfer(to, amount), "Fail");
    }
}