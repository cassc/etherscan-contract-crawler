// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IRedeemer.sol";
import "./interfaces/IUSPlusBurner.sol";
import "./interfaces/IFluentUSPlus.sol";
import "./interfaces/IRedeemersBookkeeper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/// @title Federation member´s Contract for redeem balance
/// @author Fluent Group - Development team
/// @notice Use this contract for request US dollars back
/// @dev
contract Redeemer is IRedeemer, Pausable, AccessControl {
    int public constant Version = 3;
    bytes32 public constant USER_ROLE = keccak256("USER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant APPROVER_ROLE = keccak256("APPROVER_ROLE");
    bytes32 public constant TRANSFER_REJECTED_AMOUNTS_OPERATOR_ROLE =
        keccak256("TRANSFER_REJECTED_AMOUNTS_OPERATOR_ROLE");
    bytes32 public constant TRANSFER_ALLOWLIST_TOKEN_OPERATOR_ROLE =
        keccak256("TRANSFER_ALLOWLIST_TOKEN_OPERATOR_ROLE");
    bytes32 public constant TRANSFER_ALLOWLIST_TOKEN_COMPLIANCE_ROLE =
        keccak256("TRANSFER_ALLOWLIST_TOKEN_COMPLIANCE_ROLE");

    address public fedMemberId;
    address public USPlusBurnerAddr;
    address public fluentUSPlusAddress;
    address public redeemersBookkeeper;
    address public redeemerTreasury;

    constructor(
        address _fluentUSPlusAddress,
        address _USPlusBurnerAddr,
        address _fedMemberId,
        address _redeemerBookkeeper,
        address _redeemerTreasury
    ) {
        require(
            _fluentUSPlusAddress != address(0x0),
            "ZERO Addr is not allowed"
        );
        require(_USPlusBurnerAddr != address(0x0), "ZERO Addr is not allowed");
        require(_fedMemberId != address(0x0), "ZERO Addr is not allowed");
        require(
            _redeemerBookkeeper != address(0x0),
            "ZERO Addr is not allowed"
        );
        require(_redeemerTreasury != address(0x0), "ZERO Addr is not allowed");

        _grantRole(DEFAULT_ADMIN_ROLE, _fedMemberId);
        _grantRole(PAUSER_ROLE, _fedMemberId);
        _grantRole(APPROVER_ROLE, _fedMemberId);

        fluentUSPlusAddress = _fluentUSPlusAddress;
        USPlusBurnerAddr = _USPlusBurnerAddr;
        fedMemberId = _fedMemberId;
        redeemersBookkeeper = _redeemerBookkeeper;
        redeemerTreasury = _redeemerTreasury;
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /// @notice Entry point to a user request redeem their US+ back to FIAT
    /// @dev
    /// @param amount The requested amount
    /// @param refId The Ticket Id generated in Core Banking System
    function requestRedeem(
        uint256 amount,
        bytes32 refId
    ) external whenNotPaused returns (bool isRequestPlaced) {
        require(
            verifyRole(USER_ROLE, msg.sender),
            "Caller does not have the role to request redeem"
        );
        require(
            IERC20(fluentUSPlusAddress).balanceOf(msg.sender) >= amount,
            "NOT_ENOUGH_BALANCE"
        );
        require(
            IERC20(fluentUSPlusAddress).allowance(msg.sender, address(this)) >=
                amount,
            "NOT_ENOUGH_ALLOWANCE"
        );

        require(!getUsedTicketsInfo(refId), "ALREADY_USED_REFID"); //needs to send to redeemers bookkeeping

        emit RedeemRequested(msg.sender, amount, refId);

        BurnTicket memory ticket = IRedeemer.BurnTicket({
            refId: refId,
            from: msg.sender,
            amount: amount,
            placedBlock: block.number,
            confirmedBlock: 0,
            usedTicket: true,
            ticketStatus: TicketStatus.PENDING
        });

        _setBurnTickets(refId, ticket);
        require(
            IERC20(fluentUSPlusAddress).transferFrom(
                msg.sender,
                address(this),
                amount
            ),
            "FAIL_TRANSFER"
        );

        return true;
    }

    /// @notice Set a Ticket to approved or not approved
    /// @dev
    /// @param refId The Ticket Id generated in Core Banking System
    /// @param isApproved boolean condition for this Ticket
    function approveTickets(
        bytes32 refId,
        bool isApproved
    ) external onlyRole(APPROVER_ROLE) {
        BurnTicket memory ticket = _getBurnTicketInfo(refId);
        require(ticket.usedTicket, "INVALID_TICKED_ID");
        require(
            ticket.ticketStatus == TicketStatus.PENDING,
            "INVALID_TICKED_STATUS"
        );

        if (isApproved) {
            _approvedTicket(refId);
        } else {
            _setRejectedAmounts(refId, true);

            BurnTicket memory _ticket = IRedeemer.BurnTicket({
                refId: ticket.refId,
                from: ticket.from,
                amount: ticket.amount,
                placedBlock: ticket.placedBlock,
                confirmedBlock: ticket.confirmedBlock,
                usedTicket: ticket.usedTicket,
                ticketStatus: TicketStatus.REJECTED
            });

            _setBurnTickets(refId, _ticket);
        }
    }

    /// @notice Set a Ticket to approved and send it to US+
    /// @dev
    /// @param refId The Ticket Id generated in Core Banking System
    function _approvedTicket(
        bytes32 refId
    )
        internal
        onlyRole(APPROVER_ROLE)
        whenNotPaused
        returns (bool isTicketApproved)
    {
        emit RedeemApproved(refId);

        BurnTicket memory ticket = _getBurnTicketInfo(refId); //retrieve from the bookkeeper

        BurnTicket memory _ticket = IRedeemer.BurnTicket({
            refId: ticket.refId,
            from: ticket.from,
            amount: ticket.amount,
            placedBlock: ticket.placedBlock,
            confirmedBlock: ticket.confirmedBlock,
            usedTicket: ticket.usedTicket,
            ticketStatus: TicketStatus.APPROVED
        });

        _setBurnTickets(refId, _ticket);
        require(
            IUSPlusBurner(USPlusBurnerAddr).requestBurnUSPlus(
                ticket.refId,
                address(this),
                ticket.from,
                fedMemberId,
                ticket.amount
            )
        );

        require(
            IFluentUSPlus(fluentUSPlusAddress).increaseAllowance(
                USPlusBurnerAddr,
                ticket.amount
            ),
            "INCREASE_ALLOWANCE_FAIL"
        );

        return true;
    }

    /// @notice Allows the FedMember give a destination for a seized value
    /// @dev
    /// @param _refId The Ticket Id generated in Core Banking System
    /// @param recipient The target address where the values will be addressed
    function transferRejectedAmounts(
        bytes32 refId,
        address recipient
    ) external onlyRole(TRANSFER_REJECTED_AMOUNTS_OPERATOR_ROLE) whenNotPaused {
        require(
            !hasRole(APPROVER_ROLE, msg.sender),
            "Call not allowed. Caller has also Approver Role"
        );

        require(_getRejectedAmounts(refId), "Not a rejected refId");

        BurnTicket memory ticket = _getBurnTicketInfo(refId); //retrieve from the keeper
        require(
            ticket.ticketStatus == TicketStatus.REJECTED,
            "Ticket not rejected"
        );

        BurnTicket memory _ticket = IRedeemer.BurnTicket({
            refId: ticket.refId,
            from: ticket.from,
            amount: ticket.amount,
            placedBlock: ticket.placedBlock,
            confirmedBlock: ticket.confirmedBlock,
            usedTicket: ticket.usedTicket,
            ticketStatus: TicketStatus.TRANSFERED
        });

        emit RejectedAmountsTransfered(refId, recipient);

        _setBurnTickets(refId, _ticket);

        _setRejectedAmounts(refId, false); //send to the keeper
        require(
            IERC20(fluentUSPlusAddress).transfer(recipient, ticket.amount),
            "FAIL_TRANSFER"
        );
    }

    function revertTicketRejection(
        bytes32 refId
    ) external onlyRole(APPROVER_ROLE) whenNotPaused {
        BurnTicket memory ticket = _getBurnTicketInfo(refId);
        require(
            ticket.ticketStatus == TicketStatus.REJECTED,
            "Ticket not rejected"
        );

        BurnTicket memory _ticket = IRedeemer.BurnTicket({
            refId: ticket.refId,
            from: ticket.from,
            amount: ticket.amount,
            placedBlock: ticket.placedBlock,
            confirmedBlock: ticket.confirmedBlock,
            usedTicket: ticket.usedTicket,
            ticketStatus: TicketStatus.PENDING
        });

        _setBurnTickets(refId, _ticket);

        _setRejectedAmounts(refId, false);
    }

    /// @notice Returns a Burn ticket structure
    /// @dev
    /// @param refId The Ticket Id generated in Core Banking System
    function getBurnReceiptById(
        bytes32 refId
    ) external view returns (BurnTicket memory) {
        // return burnTickets[refId];
        return _getBurnTicketInfo(refId); //retrieve from the bookkeper
    }

    /// @notice Returns Status, Execution Status and the Block Number when the burn occurs
    /// @dev
    /// @param _refId The Ticket Id generated in Core Banking System
    function getBurnStatusById(
        bytes32 refId
    ) external view returns (bool, TicketStatus, uint256) {
        BurnTicket memory ticket = _getBurnTicketInfo(refId);

        if (ticket.usedTicket) {
            return (
                ticket.usedTicket,
                ticket.ticketStatus,
                ticket.confirmedBlock //retrieve from the bookkeper
            );
        } else {
            return (false, TicketStatus.NOT_EXIST, 0);
        }
    }

    function rejectedAmount(bytes32 refId) external view returns (bool) {
        return _getRejectedAmounts(refId);
    }

    function setErc20AllowList(
        address erc20Addr,
        bool status
    ) external onlyRole(TRANSFER_ALLOWLIST_TOKEN_COMPLIANCE_ROLE) {
        require(
            !_getErc20AllowList(erc20Addr),
            "Address already in the ERC20 AllowList"
        );
        _setErc20AllowList(erc20Addr, status);
    }

    function transferErc20(
        address to,
        address erc20Addr,
        uint256 amount
    ) external onlyRole(TRANSFER_ALLOWLIST_TOKEN_OPERATOR_ROLE) {
        require(
            _getErc20AllowList(erc20Addr),
            "Address not in the ERC20 AllowList"
        );
        require(IERC20(erc20Addr).transfer(to, amount), "Fail");
    }

    //Access control stored in the redeemersKeeper
    function grantRole(
        bytes32 role,
        address account
    ) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(role, account);
        IRedeemersBookkeeper(redeemersBookkeeper).setRoleControl(
            role,
            account,
            fedMemberId
        );
    }

    function verifyRole(
        bytes32 role,
        address account
    ) public view returns (bool _hasRole) {
        _hasRole = IRedeemersBookkeeper(redeemersBookkeeper).getRoleControl(
            role,
            account,
            fedMemberId
        );
        return _hasRole;
    }

    function revokeRole(
        bytes32 role,
        address account
    ) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(role, account);
        IRedeemersBookkeeper(redeemersBookkeeper).revokeRoleControl(
            role,
            account,
            fedMemberId
        );
    }

    function getUsedTicketsInfo(bytes32 refId) public view returns (bool) {
        return
            IRedeemersBookkeeper(redeemersBookkeeper)
                .getBurnTickets(fedMemberId, refId)
                .usedTicket;
    }

    function _getBurnTicketInfo(
        bytes32 refId
    ) internal view returns (IRedeemer.BurnTicket memory _burnTickets) {
        _burnTickets = IRedeemersBookkeeper(redeemersBookkeeper).getBurnTickets(
            fedMemberId,
            refId
        );
        return _burnTickets;
    }

    function _setBurnTickets(bytes32 refId, BurnTicket memory ticket) internal {
        IRedeemersBookkeeper(redeemersBookkeeper).setTickets(
            fedMemberId,
            refId,
            ticket
        );
    }

    function _setRejectedAmounts(bytes32 refId, bool status) internal {
        emit RedeemRejected(refId);

        IRedeemersBookkeeper(redeemersBookkeeper).setRejectedAmounts(
            refId,
            fedMemberId,
            status
        );
    }

    function _getRejectedAmounts(bytes32 refId) internal view returns (bool) {
        return
            IRedeemersBookkeeper(redeemersBookkeeper).getRejectedAmounts(
                refId,
                fedMemberId
            );
    }

    function _setErc20AllowList(address tokenAddress, bool status) internal {
        IRedeemersBookkeeper(redeemersBookkeeper).setErc20AllowListToken(
            fedMemberId,
            tokenAddress,
            status
        );
    }

    function _getErc20AllowList(
        address tokenAddress
    ) internal view returns (bool) {
        return
            IRedeemersBookkeeper(redeemersBookkeeper).getErc20AllowListToken(
                fedMemberId,
                tokenAddress
            );
    }

    function getErc20AllowList(
        address tokenAddress
    ) external view onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        return
            IRedeemersBookkeeper(redeemersBookkeeper).getErc20AllowListToken(
                fedMemberId,
                tokenAddress
            );
    }

    function prepareMigration() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint currentBalance = IERC20(fluentUSPlusAddress).balanceOf(
            address(this)
        );
        require(
            IFluentUSPlus(fluentUSPlusAddress).increaseAllowance(
                redeemerTreasury,
                currentBalance
            ),
            "Fail to increase allowance"
        );
    }

    function increaseAllowanceToBurner(
        uint amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            IFluentUSPlus(fluentUSPlusAddress).increaseAllowance(
                USPlusBurnerAddr,
                amount
            ),
            "INCREASE_ALLOWANCE_FAIL"
        );
    }
}