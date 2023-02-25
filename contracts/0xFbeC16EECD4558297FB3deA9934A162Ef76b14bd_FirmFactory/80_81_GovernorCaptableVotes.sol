// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {Governor} from "@openzeppelin/contracts/governance/Governor.sol";

import {ICaptableVotes} from "../../captable/interfaces/ICaptableVotes.sol";

// Slightly modified of GovernorVotes from OpenZeppelin to use the more limited ICaptableVotes interface
// and set it with an internal function instead of a constructor argument
abstract contract GovernorCaptableVotes is Governor {
    ICaptableVotes public token;

    function _setToken(ICaptableVotes token_) internal {
        token = token_;
    }

    /**
     * Read the voting weight from the token's built in snapshot mechanism (see {Governor-_getVotes}).
     */
    function _getVotes(address account, uint256 blockNumber, bytes memory /*params*/ )
        internal
        view
        virtual
        override
        returns (uint256)
    {
        return token.getPastVotes(account, blockNumber);
    }
}