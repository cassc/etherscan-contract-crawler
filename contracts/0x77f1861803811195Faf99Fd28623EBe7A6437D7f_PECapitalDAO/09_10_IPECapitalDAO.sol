// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.16;

library Error {
  error ProposalAlreadyExists();
  error ProposalNotFound();
  error VoteNotActive();
  error OnlyMember();
  error OnlyCEO();
  error OnlyDirector();
  error LengthMismatch();
  error AlreadyAdded(address account);
  error NotMemeber(address account);
  error OnlyInternalTransfer();
  error AlreadyCastedVote();
  error CannotRemoveYourself();
}

interface IPECapitalDAO {
  enum State {
    PENDING,
    ACTIVE,
    DEFEATED,
    SUCCEDED
  }

  enum Support {
    FOR,
    AGAINST
  }

  enum Vote {
    NULL,
    FOR,
    AGAINST
  }

  enum Role {
    NON_MEMBER,
    DIRECTOR,
    CEO
  }

  struct Member {
    Role role;
    uint192 share;
  }

  struct Proposal {
    address proposer; // 20
    uint64 quorum; // 8
    Vote overturned; // 1
    uint64 forVotes; // 8
    uint64 againstVotes; // 8
    uint64 startTime; // 8
    uint64 endTime; // 8
    string data;
  }

  event Transfer(address indexed from, address indexed to, uint256 amount);

  event UpdateRole(address indexed account, Role previousRole, Role role);

  event Propose(
    bytes32 indexed proposalId,
    address proposer,
    uint64 startTime,
    uint64 endTime,
    uint64 quorum,
    string data
  );

  event CastVote(bytes32 indexed proposalId, address voter, Support support, string reason);

  event Overturn(bytes32 indexed proposalId, address turner, Support support, string reason);
}