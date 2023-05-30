// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./Core.sol";

abstract contract Delegation is Core {
    /// @notice Delegatee records
    mapping(address => address) public delegatedTo;

    event Delegated(address indexed account, address indexed to);
    event Undelegated(address indexed account, address indexed from);

    function delegate(address to) external {
        address previous = delegatedTo[msg.sender];
        require(
            to != msg.sender && to != address(this) && to != address(0) && to != previous,
            "Governance: invalid delegatee"
        );
        if (previous != address(0)) {
            emit Undelegated(msg.sender, previous);
        }
        delegatedTo[msg.sender] = to;
        emit Delegated(msg.sender, to);
    }

    function undelegate() external {
        address previous = delegatedTo[msg.sender];
        require(previous != address(0), "Governance: tokens are already undelegated");

        delegatedTo[msg.sender] = address(0);
        emit Undelegated(msg.sender, previous);
    }

    function proposeByDelegate(address from, address target, string memory description)
        external
        returns (uint256)
    {
        require(delegatedTo[from] == msg.sender, "Governance: not authorized");
        return _propose(from, target, description);
    }

    function _propose(address proposer, address target, string memory description)
        internal
        virtual
        returns (uint256);

    function castDelegatedVote(address[] memory from, uint256 proposalId, bool support) external virtual {
        for (uint256 i = 0; i < from.length; i++) {
            require(delegatedTo[from[i]] == msg.sender, "Governance: not authorized");
            _castVote(from[i], proposalId, support);
        }
        if (lockedBalance[msg.sender] > 0) {
            _castVote(msg.sender, proposalId, support);
        }
    }

    function _castVote(address voter, uint256 proposalId, bool support) internal virtual;
}