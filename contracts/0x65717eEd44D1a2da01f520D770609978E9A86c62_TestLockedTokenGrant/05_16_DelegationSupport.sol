// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.8.16;

import "CommonConstants.sol";
import "IVotes.sol";

/**
  A subset of the Gnosis DelegateRegistry ABI.
*/
interface IDelegateRegistry {
    function setDelegate(bytes32 id, address delegate) external;

    function delegation(address delegator, bytes32 id) external view returns (address);

    function clearDelegate(bytes32 id) external;
}

/**
  This contract implements the delegations made on behalf of the token grant contract.
  Two types of delegation are supported:
  1. Delegation using Gnosis DelegateRegistry.
  2. IVotes (Compound like) delegation, done directly on the ERC20 token.

  Upon construction, the {LockedTokenGrant} is provided with an address of the
  Gnosis DelegateRegistry. In addition, if a different DelegateRegistry is used,
  it can be passed in explicitly as an argument.

  Compound like vote delegation can be done on the StarkNet token, and on the Staking contract,
  assuming it will support that.
*/
abstract contract DelegationSupport {
    address public immutable recipient;

    // A Gnosis DelegateRegistry contract, provided by the common contract.
    // Used for delegation of votes, and also to permit token release and delegation actions.
    IDelegateRegistry public immutable defaultRegistry;

    // StarkNet Token.
    address public immutable token;

    // StarkNet Token Staking contract.
    address public immutable stakingContract;

    modifier onlyRecipient() {
        require(msg.sender == recipient, "ONLY_RECIPIENT");
        _;
    }

    modifier onlyAllowedAgent(bytes32 agentId) {
        require(
            msg.sender == recipient || msg.sender == defaultRegistry.delegation(recipient, agentId),
            "ONLY_RECIPIENT_OR_APPROVED_AGENT"
        );
        _;
    }

    constructor(
        address defaultRegistry_,
        address recipient_,
        address token_,
        address stakingContract_
    ) {
        defaultRegistry = IDelegateRegistry(defaultRegistry_);
        recipient = recipient_;
        token = token_;
        stakingContract = stakingContract_;
    }

    /*
      Clears the {LockedTokenGrant} Gnosis delegation on the provided DelegateRegistry,
      for the ID provided.
      The call is restricted to the recipient or to the appointed delegation agent.
    */
    function clearDelegate(bytes32 id, IDelegateRegistry registry)
        public
        onlyAllowedAgent(LOCKED_TOKEN_DELEGATION_AGENT)
    {
        registry.clearDelegate(id);
    }

    /*
      Sets the {LockedTokenGrant} Gnosis delegation on the provided DelegateRegistry,
      for the ID provided.
      The call is restricted to the recipient or to the appointed delegation agent.
    */
    function setDelegate(
        bytes32 id,
        address delegate,
        IDelegateRegistry registry
    ) public onlyAllowedAgent(LOCKED_TOKEN_DELEGATION_AGENT) {
        registry.setDelegate(id, delegate);
    }

    /*
      Clears the {LockedTokenGrant} Gnosis delegation on the default DelegateRegistry,
      for the ID provided.
      The call is restricted to the recipient or to the appointed delegation agent.
    */
    function clearDelegate(bytes32 id) external {
        clearDelegate(id, defaultRegistry);
    }

    /*
      Sets the {LockedTokenGrant} Gnosis delegation on the default DelegateRegistry,
      for the ID provided.
      The call is restricted to the recipient or to the appointed delegation agent.
    */
    function setDelegate(bytes32 id, address delegate) external {
        setDelegate(id, delegate, defaultRegistry);
    }

    /*
      Sets the {LockedTokenGrant} IVotes delegation on the token.
      The call is restricted to the recipient or to the appointed delegation agent.
    */
    function setDelegateOnToken(address delegatee)
        external
        onlyAllowedAgent(LOCKED_TOKEN_DELEGATION_AGENT)
    {
        _setIVotesDelegation(token, delegatee);
    }

    /*
      Sets the {LockedTokenGrant} IVotes delegation on the staking contract.
      The call is restricted to the recipient or to the appointed delegation agent.
    */
    function setDelegateOnStaking(address delegatee)
        external
        onlyAllowedAgent(LOCKED_TOKEN_DELEGATION_AGENT)
    {
        _setIVotesDelegation(stakingContract, delegatee);
    }

    function _setIVotesDelegation(address target, address delegatee) private {
        IVotes(target).delegate(delegatee);
    }
}