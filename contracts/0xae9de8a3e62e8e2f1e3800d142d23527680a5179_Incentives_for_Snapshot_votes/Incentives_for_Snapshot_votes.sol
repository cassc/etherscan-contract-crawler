
# @version 0.3.7
"""
@title Incentives for Snapshot votes
@author 0xkorin, Yearn Finance
@license Copyright (c) Yearn Finance, 2023 - all rights reserved
"""

from vyper.interfaces import ERC20

management: public(address)
pending_management: public(address)
roots: public(HashMap[bytes32, bytes32]) # vote => claim root
claimed: public(HashMap[bytes32, HashMap[address, HashMap[address, bool]]]) # vote => incentive => user => claimed?

event Deposit:
    vote: indexed(bytes32)
    choice: uint256
    token: indexed(address)
    depositor: address
    amount: uint256

event Claim:
    vote: indexed(bytes32)
    claimer: indexed(address)
    incentive: indexed(address)
    amount: uint256

event SetRoot:
    vote: bytes32
    root: bytes32

event PendingManagement:
    management: indexed(address)

event SetManagement:
    management: indexed(address)

MAX_TREE_DEPTH: constant(uint256) = 32

@external
def __init__():
    """
    @notice Constructor
    """
    self.management = msg.sender

@external
def deposit(_vote: bytes32, _choice: uint256, _incentive: address, _amount: uint256):
    """
    @notice Deposit an incentive for a specific choice in a vote
    @param _vote Vote to deposit incentive for
    @param _choice Sequence number of choice to deposit incentive for
    @param _incentive Address of the incentive token
    @param _amount Amount of tokens to use as incentive
    """
    assert _vote != empty(bytes32)
    assert self.roots[_vote] == empty(bytes32) # dev: vote concluded
    assert _choice > 0 # dev: 1-indexed
    assert _amount > 0
    assert ERC20(_incentive).transferFrom(msg.sender, self, _amount, default_return_value=True)
    log Deposit(_vote, _choice, _incentive, msg.sender, _amount)

@external
def claim(_vote: bytes32, _incentive: address, _amount: uint256, _proof: DynArray[bytes32, MAX_TREE_DEPTH], _claimer: address = msg.sender):
    """
    @notice Claim an incentive
    @param _vote Vote to claim incentive for
    @param _incentive Address of the incentive token
    @param _amount Amount of tokens to claim as incentive
    @param _proof Merkle proof proving inclusion in the tree
    """
    assert _vote != empty(bytes32)
    assert len(_proof) > 0
    assert not self.claimed[_vote][_incentive][_claimer] # dev: already claimed

    # verify proof
    hash: bytes32 = self._leaf(_claimer, _incentive, _amount)
    for sibling in _proof:
        hash = self._hash_siblings(hash, sibling)
    assert hash == self.roots[_vote]

    self.claimed[_vote][_incentive][_claimer] = True
    assert ERC20(_incentive).transfer(_claimer, _amount, default_return_value=True)
    log Claim(_vote, _claimer, _incentive, _amount)

@external
@pure
def leaf(_account: address, _incentive: address, _amount: uint256) -> bytes32:
    """
    @notice Calculate leaf value for inclusion in a Merkle tree
    @param _account Address of claimer
    @param _incentive Address of the incentive token
    @param _amount Amount of tokens
    @return Leaf value
    """
    return self._leaf(_account, _incentive, _amount)

@internal
@pure
def _leaf(_account: address, _incentive: address, _amount: uint256) -> bytes32:
    """
    @notice Calculate leaf value for inclusion in a Merkle tree
    @param _account Address of claimer
    @param _incentive Address of the incentive token
    @param _amount Amount of tokens
    @return Leaf value
    """
    return keccak256(_abi_encode(_account, _incentive, _amount))

@external
@pure
def hash_siblings(_a: bytes32, _b: bytes32) -> bytes32:
    """
    @notice Calculate hash of two siblings
    @param _a Hash of first sibling
    @param _b Hash of second sibling
    @return Hash of siblings
    @dev Ordering of arguments does not matter
    """
    return self._hash_siblings(_a, _b)

@internal
@pure
def _hash_siblings(_a: bytes32, _b: bytes32) -> bytes32:
    """
    @notice Calculate hash of two siblings
    @param _a Hash of first sibling
    @param _b Hash of second sibling
    @return Hash of siblings
    @dev Ordering of arguments does not matter
    """
    if convert(_a, uint256) > convert(_b, uint256):
        return keccak256(_abi_encode(_a, _b))
    else:
        return keccak256(_abi_encode(_b, _a))

@external
def set_root(_vote: bytes32, _root: bytes32):
    """
    @notice Set Merkle root for a specific vote
    @param _vote Vote to set the root for
    @param _root Merkle root
    """
    assert msg.sender == self.management
    assert self.roots[_vote] == empty(bytes32) or _root == empty(bytes32)
    self.roots[_vote] = _root
    log SetRoot(_vote, _root)

@external
def set_management(_management: address):
    """
    @notice 
        Set the pending management address.
        Needs to be accepted by that account separately to transfer management over
    @param _management New pending management address
    """
    assert msg.sender == self.management
    self.pending_management = _management
    log PendingManagement(_management)

@external
def accept_management():
    """
    @notice 
        Accept management role.
        Can only be called by account previously marked as pending management by current management
    """
    assert msg.sender == self.pending_management
    self.pending_management = empty(address)
    self.management = msg.sender
    log SetManagement(msg.sender)