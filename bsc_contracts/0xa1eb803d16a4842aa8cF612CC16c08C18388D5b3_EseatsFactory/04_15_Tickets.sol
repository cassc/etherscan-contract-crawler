// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library Tickets {
  enum TicketState { UNUSED, USED }

  struct Ticket {
    uint256 expiredAt;
    uint256 ticketType;
    TicketState state;
    bytes32[] metadata;
  }

  function mapMinted(Ticket storage _ticket, uint256 _expiry, uint256 _ticketType, bytes32[] memory _metadata) internal {
    _ticket.expiredAt = block.timestamp + _expiry;
    _ticket.ticketType = _ticketType;
    _ticket.state = TicketState.UNUSED;
    _ticket.metadata = _metadata;
  }

  function checkIn(Ticket storage _ticket) internal {
    _ticket.state = TicketState.USED;
    _ticket.expiredAt = 0;
  }
}