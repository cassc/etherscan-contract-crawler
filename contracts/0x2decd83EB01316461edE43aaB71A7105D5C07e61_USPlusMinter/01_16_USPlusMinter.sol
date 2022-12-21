// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IUSPlusMinter.sol";
import "./interfaces/IComplianceManager.sol";
import "./interfaces/IFluentUSPlus.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/// @title
/// @author Fluent Group - Development team
/// @notice
/// @dev
contract USPlusMinter is
    IUSPlusMinter,
    PausableUpgradeable,
    AccessControlUpgradeable
{
    int public constant Version = 3;
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant REQUESTER_MINTER_ROLE =
        keccak256("REQUESTER_MINTER_ROLE");
    bytes32 public constant PROTOCOL_MANAGER = keccak256("PROTOCOL_MANAGER");
    bytes32 public constant TRANSFER_ALLOWLIST_TOKEN_OPERATOR_ROLE =
        keccak256("TRANSFER_ALLOWLIST_TOKEN_OPERATOR_ROLE");

    /// @notice 7100 blocks/day
    uint256 public expirationTime;

    /// @notice fired every time a new Mint is requested
    event MintRequest(
        address indexed fedMember,
        bytes32 id,
        uint256 amount,
        address indexed to
    );

    /// @notice fired every time a new Mint is executed
    event MintExecution(
        address indexed vault,
        bytes32 id,
        address indexed to,
        uint256 amount
    );

    mapping(bytes32 => MintTicket) public mintTickets;

    mapping(bytes32 => bool) public usedIDs;

    bytes32[] public ticketsIDs;

    address public complianceManagerAddr;
    address public USPlusAddr;
    address public ProtocolManagerAddr;

    function initialize() public initializer {
        AccessControlUpgradeable._grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        AccessControlUpgradeable._grantRole(PAUSER_ROLE, msg.sender);
        expirationTime = 7100;
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function setExpirationTime(
        uint _expirationTime
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        expirationTime = _expirationTime;
    }

    function setProtocolManager(
        address protocolManager
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            protocolManager != address(0),
            "PROTOCOL_MANAGER_ADDRESS_IS_ZERO"
        );
        ProtocolManagerAddr = protocolManager;
        _grantRole(PROTOCOL_MANAGER, ProtocolManagerAddr);
    }

    function toGrantRole(address to) external onlyRole(PROTOCOL_MANAGER) {
        _grantRole(REQUESTER_MINTER_ROLE, to);
    }

    /// @notice Creates a ticket to request a amount of US+ to mint
    /// @dev
    /// @param id The Ticket Id generated in Core Banking System
    /// @param amount The amount of US+ to be minted
    /// @param to The destination address
    function requestMint(
        bytes32 id,
        uint256 amount,
        address to
    )
        external
        onlyRole(REQUESTER_MINTER_ROLE)
        whenNotPaused
        returns (bool retRequestMint)
    {
        require(!usedIDs[id], "INVALID_ID");
        require(
            !IComplianceManager(complianceManagerAddr).checkBlackList(to),
            "Address blacklisted"
        );

        MintTicket memory ticket = MintTicket({
            ID: id,
            from: msg.sender,
            to: to,
            amount: amount,
            placedBlock: block.number,
            status: true,
            executed: false
        });

        emit MintRequest(msg.sender, id, amount, to);

        ticketsIDs.push(id);
        mintTickets[id] = ticket;

        usedIDs[id] = true;
        retRequestMint = true;
    }

    /// @notice Mints the amount of US+ defined in the ticket
    /// @dev
    /// @param id The Ticket Id generated in Core Banking System
    function mint(bytes32 id) external onlyRole(MINTER_ROLE) whenNotPaused {
        MintTicket storage ticket = mintTickets[id];

        require(usedIDs[id], "TICKET_NOT_EXISTS");

        uint256 ticketValidTime = ticket.placedBlock + expirationTime;
        require(!ticket.executed, "TICKET_ALREADY_EXECUTED");
        require(block.number < ticketValidTime, "TICKET_HAS_EXPIRED");

        emit MintExecution(msg.sender, id, ticket.to, ticket.amount);

        ticket.executed = true;

        require(
            IFluentUSPlus(USPlusAddr).mint(ticket.to, ticket.amount),
            "Mint failed"
        );
    }

    /// @notice Returns a ticket structure
    /// @dev
    /// @param id The Ticket Id generated in Core Banking System
    function getMintReceiptById(
        bytes32 id
    ) external view returns (MintTicket memory) {
        return mintTickets[id];
    }

    /// @notice Returns Status, Execution Status and the Block Number when the mint occurs
    /// @dev
    /// @param id The Ticket Id generated in Core Banking System
    function getMintStatusById(bytes32 id) external view returns (bool, bool) {
        if (usedIDs[id]) {
            return (mintTickets[id].status, mintTickets[id].executed);
        } else {
            return (false, false);
        }
    }

    /// @notice Links the current contract to a White/Black list manager contract
    /// @dev
    /// @param newComplianceManagerAddr The address where the compliance manager was deployed
    function setComplianceManagerAddr(
        address newComplianceManagerAddr
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            newComplianceManagerAddr != address(0x0),
            "ZERO Addr is not allowed"
        );
        complianceManagerAddr = newComplianceManagerAddr;
    }

    /// @notice Links the current contract to US+ Implementation
    /// @dev
    /// @param newUSPlusAddr The address where the US+ was deployed
    function setUSPlusAddr(
        address newUSPlusAddr
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newUSPlusAddr != address(0x0), "ZERO Addr is not allowed");
        USPlusAddr = newUSPlusAddr;
    }

    function transferErc20(
        address to,
        address erc20Addr,
        uint256 amount
    ) external onlyRole(TRANSFER_ALLOWLIST_TOKEN_OPERATOR_ROLE) {
        SafeERC20Upgradeable.safeTransfer(
            IERC20Upgradeable(erc20Addr),
            to,
            amount
        );
    }
}