// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";

library SendUtils {
    using Address for address payable;

    function _returnAllEth() internal {
        // NOTE: This works on the assumption that the whole balance of the contract consists of
        // the ether sent by the caller.
        // (1) This is never 100% true because anyone can send ether to it with selfdestruct or by using
        // its address as the coinbase when mining a block. Anyone doing that is doing it to their own
        // disavantage though so we're going to disregard these possibilities.
        // (2) For this to be safe we must ensure that no ether is stored in the contract long-term.
        // It's best if it has no receive function and all payable functions should ensure that they
        // use the whole balance or send back the remainder.
        if (address(this).balance > 0)
            payable(msg.sender).sendValue(address(this).balance);
    }
}