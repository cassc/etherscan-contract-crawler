// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev This contract is used to store numbered ticket ranges and their owners.
 *
 * Ticket range is represented using {TicketNumberRange}, a struct of `owner, `from` and `to`. If account `0x1` buys
 * first ticket, then we store it as `(0x1, 0, 0)`, if then account `0x2` buys ten tickets, then we store next record as
 * `(0x2, 1, 10)`. If after that third account `0x3` buys ten tickets, we store it as `(0x3, 11, 20)`. And so on.
 *
 * Storing ticket numbers in such way allows compact representation of accounts who buy a lot of tickets at once.
 *
 * We set 25000 as limit of how many tickets we can support.
 */
abstract contract TicketStorage {
    event TicketsAssigned(TicketNumberRange ticketNumberRange, uint16 ticketsLeft);

    struct TicketNumberRange {
        address owner;
        uint16 from;
        uint16 to;
    }

    uint16 internal immutable _tickets;
    uint16 internal _ticketsLeft;

    TicketNumberRange[] private _ticketNumberRanges;
    mapping(address => uint16) private _addressToAssignedCountMap;
    mapping(address => uint16[]) private _addressToAssignedTicketNumberRangesMap;

    constructor(uint16 tickets) {
        require(tickets > 0, "Number of tickets must be greater than 0");
        require(tickets <= 25_000, "Number of tickets cannot exceed 25_000");

        _tickets = tickets;
        _ticketsLeft = tickets;
    }

    /**
     * @dev Returns total amount of tickets.
     */
    function getTickets() public view returns (uint16) {
        return _tickets;
    }

    /**
     * @dev Returns amount of unassigned tickets.
     */
    function getTicketsLeft() public view returns (uint16) {
        return _ticketsLeft;
    }

    /**
     * @dev Returns {TicketNumberRange} for given `index`.
     */
    function getTicketNumberRange(uint16 index) public view returns (TicketNumberRange memory) {
        return _ticketNumberRanges[index];
    }

    /**
     * @dev Returns how many tickets are assigned to given `owner`.
     */
    function getAssignedTicketCount(address owner) public view returns (uint16) {
        return _addressToAssignedCountMap[owner];
    }

    /**
     * @dev Returns the index of {TicketNumberRange} in `_ticketNumberRanges` that is assigned to `owner`.
     *
     * For example, if `owner` purchased tickets three times ({getAssignedTicketNumberRanges} will return `3`),
     * we can use this method with `index` of 0, 1 and 2, to get indexes of {TicketNumberRange} in `_ticketNumberRanges`.
     */
    function getAssignedTicketNumberRange(address owner, uint16 index) public view returns (uint16) {
        return _addressToAssignedTicketNumberRangesMap[owner][index];
    }

    /**
     * @dev Returns how many {TicketNumberRange} are assigned for given `owner`.
     *
     * Can be used in combination with {getAssignedTicketNumberRange} and {getTicketNumberRange} to show
     * all actual ticket numbers that are assigned to the `owner`.
     */
    function getAssignedTicketNumberRanges(address owner) public view returns (uint16) {
        return uint16(_addressToAssignedTicketNumberRangesMap[owner].length);
    }

    /**
     * @dev Assigns `count` amount of tickets to `owner` address.
     *
     * Requirements:
     * - there must be enough tickets left
     *
     * Emits a {TicketsAssigned} event.
     */
    function _assignTickets(address owner, uint16 count) internal {
        require(_ticketsLeft > 0, "All tickets are assigned");
        require(_ticketsLeft >= count, "Assigning too many tickets at once");

        uint16 from = _tickets - _ticketsLeft;
        _ticketsLeft -= count;
        TicketNumberRange memory ticketNumberRange = TicketNumberRange({
            owner: owner,
            from: from,
            to: from + count - 1
        });
        _ticketNumberRanges.push(ticketNumberRange);
        _addressToAssignedCountMap[owner] += count;
        _addressToAssignedTicketNumberRangesMap[owner].push(uint16(_ticketNumberRanges.length - 1));

        assert(_ticketNumberRanges[_ticketNumberRanges.length - 1].to == _tickets - _ticketsLeft - 1);

        emit TicketsAssigned(ticketNumberRange, _ticketsLeft);
    }

    /**
     * @dev Returns address of the `owner` of given ticket number.
     *
     * Uses binary search on `_ticketNumberRanges` to find it.
     *
     * Requirements:
     * - all tickets must be assigned
     */
    function findOwnerOfTicketNumber(uint16 ticketNumber) public view returns (address) {
        require(ticketNumber < _tickets, "Ticket number does not exist");
        require(_ticketsLeft == 0, "Not all tickets are assigned");

        uint16 ticketNumberRangesLength = uint16(_ticketNumberRanges.length);
        assert(_ticketNumberRanges[0].from == 0);
        assert(_ticketNumberRanges[ticketNumberRangesLength - 1].to == _tickets - 1);

        uint16 left = 0;
        uint16 right = ticketNumberRangesLength - 1;
        uint16 pivot = (left + right) / 2;
        address ownerAddress = address(0);
        while (ownerAddress == address(0)) {
            pivot = (left + right) / 2;
            TicketNumberRange memory ticketNumberRange = _ticketNumberRanges[pivot];
            if (ticketNumberRange.to < ticketNumber) {
                left = pivot + 1;
            } else if (ticketNumberRange.from > ticketNumber) {
                right = pivot - 1;
            } else {
                ownerAddress = ticketNumberRange.owner;
            }
        }

        return ownerAddress;
    }
}