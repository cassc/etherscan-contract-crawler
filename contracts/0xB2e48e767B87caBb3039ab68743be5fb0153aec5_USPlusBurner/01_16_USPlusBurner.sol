// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IComplianceManager.sol";
import "./interfaces/IFluentUSPlus.sol";
import "./interfaces/IUSPlusBurner.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/// @title
/// @author
/// @notice
/// @dev
contract USPlusBurner is
    IUSPlusBurner,
    PausableUpgradeable,
    AccessControlUpgradeable
{
    int public constant Version = 3;
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE"); // assigned to vault
    bytes32 public constant REQUESTER_BURNER_ROLE =
        keccak256("REQUESTER_BURNER_ROLE"); // the redeemers needs to have a request burner role
    bytes32 public constant PROTOCOL_MANAGER = keccak256("PROTOCOL_MANAGER");
    bytes32 public constant TRANSFER_ALLOWLIST_TOKEN_OPERATOR_ROLE =
        keccak256("TRANSFER_ALLOWLIST_TOKEN_OPERATOR_ROLE");

    //burn events
    event BurnRequestUSPlus(
        address indexed executedBy,
        bytes32 refId,
        address indexed redeemerContractAddress,
        address indexed redeemerPerson,
        address fedMemberID,
        uint256 amount
    );

    event BurnExecution(
        address indexed vault,
        bytes32 refId,
        address indexed redeemerContractAddress,
        address indexed fedMemberId,
        uint amount
    );

    mapping(bytes32 => BurnTicket) burnTickets;

    BurnTicketId[] public burnTicketsIDs;

    address public complianceManagerAddr;
    address public USPlusAddr;

    function initialize() public initializer {
        AccessControlUpgradeable._grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        AccessControlUpgradeable._grantRole(PAUSER_ROLE, msg.sender);
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /// @notice Returns a Burn ticket structure
    /// @dev
    /// @param id The Ticket Id generated in Core Banking System
    function getBurnReceiptById(
        bytes32 id
    ) external view returns (BurnTicket memory) {
        return burnTickets[id];
    }

    /// @notice Returns Status, Execution Status and the Block Number when the burn occurs
    /// @dev
    /// @param id The Ticket Id generated in Core Banking System
    function getBurnStatusById(
        bytes32 id
    ) external view returns (bool, bool, uint256) {
        if (burnTickets[id].status) {
            return (
                burnTickets[id].status,
                burnTickets[id].executed,
                burnTickets[id].confirmedBlock
            );
        } else {
            return (false, false, 0);
        }
    }

    function toGrantRole(address _to) external onlyRole(PROTOCOL_MANAGER) {
        _grantRole(REQUESTER_BURNER_ROLE, _to);
    }

    /// @notice Execute transferFrom Executer Acc to this contract, and open a burn Ticket
    /// @dev to match the id the fields should be (burnCounter, _refNo, amount, msg.sender)
    /// @param refId Ref Code provided by customer to identify this request
    /// @param redeemerContractAddress The Federation Member´s REDEEMER contract
    /// @param redeemerPerson The person who is requesting US Redeem
    /// @param fedMemberID Identification for Federation Member
    /// @param amount The amount to be burned
    /// @return isRequestPlaced confirmation if Function gets to the end without revert
    function requestBurnUSPlus(
        bytes32 refId,
        address redeemerContractAddress,
        address redeemerPerson,
        address fedMemberID,
        uint256 amount
    )
        external
        onlyRole(REQUESTER_BURNER_ROLE)
        whenNotPaused
        returns (bool isRequestPlaced)
    {
        require(redeemerContractAddress == msg.sender, "INVALID_ORIGIN_CALL");

        require(
            IERC20Upgradeable(USPlusAddr).balanceOf(msg.sender) >= amount,
            "NOT_ENOUGH_BALANCE"
        );

        require(_isWhiteListed(fedMemberID), "NOT_WHITELISTED");

        BurnTicket memory ticket = BurnTicket({
            refId: refId,
            redeemerContractAddress: redeemerContractAddress,
            redeemerPerson: redeemerPerson,
            fedMemberID: fedMemberID,
            amount: amount,
            placedBlock: block.number,
            confirmedBlock: 0,
            status: true,
            executed: false
        });

        BurnTicketId memory bTicketId = BurnTicketId({
            refId: refId,
            fedMemberId: fedMemberID
        });

        emit BurnRequestUSPlus(
            msg.sender,
            refId,
            redeemerContractAddress,
            redeemerPerson,
            fedMemberID,
            amount
        );

        burnTicketsIDs.push(bTicketId);

        burnTickets[refId] = ticket;

        return true;
    }

    /// @notice Burn the amount of US+ defined in the ticket
    /// @dev Be aware that burnID is formed by a hash of (mapping.burnCounter, mapping._refNo, amount, _redeemBy), see requestBurnUSPlus method
    /// @param refId Burn TicketID
    /// @param redeemerContractAddress address from the amount get out
    /// @param fedMemberId Federation Member ID
    /// @param amount Burn amount requested
    /// @return isAmountBurned confirmation if Function gets to the end without revert
    function executeBurn(
        bytes32 refId,
        address redeemerContractAddress,
        address fedMemberId,
        uint256 amount,
        address vault
    )
        external
        onlyRole(BURNER_ROLE)
        whenNotPaused
        returns (bool isAmountBurned)
    {
        BurnTicket storage ticket = burnTickets[refId];

        require(!ticket.executed, "BURN_ALREADY_EXECUTED");
        require(_isWhiteListed(fedMemberId), "FEDMEMBER_BLACKLISTED");

        require(ticket.status, "TICKET_NOT_EXISTS");

        require(ticket.amount == amount, "WRONG_AMOUNT");

        emit BurnExecution(
            vault,
            refId,
            redeemerContractAddress,
            fedMemberId,
            amount
        );

        ticket.executed = true;
        ticket.confirmedBlock = block.number;

        IFluentUSPlus(USPlusAddr).burnFrom(
            redeemerContractAddress,
            ticket.amount
        );

        return true;
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

    /// @notice Links the current contract to original USPlus contract
    /// @dev
    /// @param newUSPlusAddr The address where the USPlus was deployed
    function setUSPlusAddr(
        address newUSPlusAddr
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newUSPlusAddr != address(0x0), "ZERO Addr is not allowed");
        USPlusAddr = newUSPlusAddr;
    }

    /// @notice Checks if the address is whitelisted or not
    /// @dev use to check before business critical function calls
    /// @param _addr address to be checked
    /// @return booleanValue confirmation if the address is whitelisted or not
    function _isWhiteListed(address _addr) internal view returns (bool) {
        require(complianceManagerAddr != address(0), "COMPLIANCE_MNGR_NOT_SET");

        return IComplianceManager(complianceManagerAddr).checkWhiteList(_addr);
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