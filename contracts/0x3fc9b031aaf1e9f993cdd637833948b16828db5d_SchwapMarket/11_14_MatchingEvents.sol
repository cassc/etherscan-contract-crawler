// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

contract MatchingEvents {
    event LogMinSell(address pay_gem, uint min_amount);
    event LogUnsortedOffer(uint id);
    event LogSortedOffer(uint id);
    event LogInsert(address keeper, uint id);
    event LogDelete(address keeper, uint id);
}