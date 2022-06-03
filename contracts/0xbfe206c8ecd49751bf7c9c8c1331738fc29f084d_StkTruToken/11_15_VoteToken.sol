// SPDX-License-Identifier: MIT
// AND COPIED FROM https://github.com/compound-finance/compound-protocol/blob/c5fcc34222693ad5f547b14ed01ce719b5f4b000/contracts/Governance/Comp.sol
// Copyright 2020 Compound Labs, Inc.
// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// Ctrl+f for OLD to see all the modifications.

pragma solidity ^0.8.10;

import {ERC20} from "ERC20.sol";
import {IVoteToken} from "IVoteToken.sol";

/**
 * @title VoteToken
 * @notice Custom token which tracks voting power for governance
 * @dev This is an abstraction of a fork of the Compound governance contract
 * VoteToken is used by TRU and stkTRU to allow tracking voting power
 * Checkpoints are created every time state is changed which record voting power
 * Inherits standard ERC20 behavior
 */
abstract contract VoteToken is ERC20, IVoteToken {
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    function delegate(address delegatee) public override {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @dev Delegate votes using signature
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public override {
        require(block.timestamp <= expiry, "TrustToken::delegateBySig: signature expired");
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name())), block.chainid, address(this)));
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "TrustToken::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "TrustToken::delegateBySig: invalid nonce");
        return _delegate(signatory, delegatee);
    }

    /**
     * @dev Get current voting power for an account
     * @param account Account to get voting power for
     * @return Voting power for an account
     */
    function getCurrentVotes(address account) public view virtual override returns (uint96) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    function getDelegate(address account) public view returns (address) {
        return delegates[account] == address(0) ? account : delegates[account];
    }

    /**
     * @dev Get voting power at a specific block for an account
     * @param account Account to get voting power for
     * @param blockNumber Block to get voting power at
     * @return Voting power for an account at specific block
     */
    function getPriorVotes(address account, uint256 blockNumber) public view virtual override returns (uint96) {
        require(blockNumber < block.number, "TrustToken::getPriorVotes: not yet determined");

        uint32 checkpointsNumber = numCheckpoints[account];
        if (checkpointsNumber == 0) {
            return 0;
        }

        mapping(uint32 => Checkpoint) storage userCheckpoints = checkpoints[account];

        // First check most recent balance
        if (userCheckpoints[checkpointsNumber - 1].fromBlock <= blockNumber) {
            return userCheckpoints[checkpointsNumber - 1].votes;
        }

        // Next check implicit zero balance
        if (userCheckpoints[0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = checkpointsNumber - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory checkpoint = userCheckpoints[center];
            if (checkpoint.fromBlock == blockNumber) {
                return checkpoint.votes;
            } else if (checkpoint.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return userCheckpoints[lower].votes;
    }

    /**
     * @dev Internal function to delegate voting power to an account
     * @param delegator Account to delegate votes from
     * @param delegatee Account to delegate votes to
     */
    function _delegate(address delegator, address delegatee) internal {
        require(delegatee != address(0), "StkTruToken: cannot delegate to AddressZero");
        address currentDelegate = getDelegate(delegator);

        uint96 delegatorBalance = safe96(_balanceOf(delegator), "StkTruToken: uint96 overflow");
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _balanceOf(address account) internal view virtual returns (uint256) {
        return balanceOf[account];
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal virtual override {
        super._transfer(_from, _to, _value);
        _moveDelegates(getDelegate(_from), getDelegate(_to), safe96(_value, "StkTruToken: uint96 overflow"));
    }

    function _mint(address account, uint256 amount) internal virtual override {
        super._mint(account, amount);
        _moveDelegates(address(0), getDelegate(account), safe96(amount, "StkTruToken: uint96 overflow"));
    }

    function _burn(address account, uint256 amount) internal virtual override {
        super._burn(account, amount);
        _moveDelegates(getDelegate(account), address(0), safe96(amount, "StkTruToken: uint96 overflow"));
    }

    /**
     * @dev internal function to move delegates between accounts
     */
    function _moveDelegates(
        address source,
        address destination,
        uint96 amount
    ) internal {
        if (source != destination && amount > 0) {
            if (source != address(0)) {
                uint32 sourceCheckpointsNumber = numCheckpoints[source];
                uint96 sourceOldVotes = sourceCheckpointsNumber > 0 ? checkpoints[source][sourceCheckpointsNumber - 1].votes : 0;
                uint96 sourceNewVotes = sourceOldVotes - amount;
                _writeCheckpoint(source, sourceCheckpointsNumber, sourceOldVotes, sourceNewVotes);
            }

            if (destination != address(0)) {
                uint32 destinationCheckpointsNumber = numCheckpoints[destination];
                uint96 destinationOldVotes = destinationCheckpointsNumber > 0
                    ? checkpoints[destination][destinationCheckpointsNumber - 1].votes
                    : 0;
                uint96 destinationNewVotes = destinationOldVotes + amount;
                _writeCheckpoint(destination, destinationCheckpointsNumber, destinationOldVotes, destinationNewVotes);
            }
        }
    }

    /**
     * @dev internal function to write a checkpoint for voting power
     */
    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint96 oldVotes,
        uint96 newVotes
    ) internal {
        uint32 blockNumber = safe32(block.number, "TrustToken::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    /**
     * @dev internal function to convert from uint256 to uint32
     */
    function safe32(uint256 n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    /**
     * @dev internal function to convert from uint256 to uint96
     */
    function safe96(uint256 n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }
}