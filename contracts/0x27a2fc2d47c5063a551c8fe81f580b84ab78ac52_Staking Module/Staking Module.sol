# @version 0.3.7
"""
@title Staking Module
@author 0xkorin, Yearn Finance
@license Copyright (c) Yearn Finance, 2023 - all rights reserved
@notice
    Module to deposit into yETH LSD pool.
    Depositing is done indirectly by transfering to treasury, which is then tasked 
    with converting it to yETH in the most economical way
"""

from vyper.interfaces import ERC20

interface POL:
    def receive_native(): payable
    def send_native(_receiver: address, _amount: uint256): nonpayable

pol: public(immutable(address))
management: public(address)
pending_management: public(address)
treasury: public(address)
pending_treasury: public(address)

event FromPOL:
    token: indexed(address)
    amount: uint256

event ToPOL:
    token: indexed(address)
    amount: uint256

event ToTreasury:
    token: indexed(address)
    amount: uint256

event PendingManagement:
    management: indexed(address)

event SetManagement:
    management: indexed(address)

event PendingTreasury:
    treasury: indexed(address)

event SetTreasury:
    treasury: indexed(address)

@external
def __init__(_pol: address, _treasury: address):
    """
    @notice Constructor
    @param _pol POL address
    @param _treasury Treasury address
    """
    pol = _pol
    self.management = msg.sender
    self.treasury = _treasury

@external
@payable
def __default__():
    """
    @notice Receive ETH
    """
    pass

@external
def from_pol(_token: address, _amount: uint256):
    """
    @notice Transfer `_amount` of `_token` from POL to this contract
    @param _token 
        Token to transfer out of POL.
        Use special designated value to transfer ETH
    @param _amount Amount of tokens to transfer
    """
    assert msg.sender == self.management
    if _token == empty(address):
        POL(pol).send_native(self, _amount)
    else:
        assert ERC20(_token).transferFrom(pol, self, _amount, default_return_value=True)
    log FromPOL(_token, _amount)

@external
def to_pol(_token: address, _amount: uint256):
    """
    @notice Transfer `_amount` of `_token` to POL from this contract
    @param _token 
        Token to transfer into POL.
        Use special designated value to transfer ETH
    @param _amount Amount of tokens to transfer
    """
    assert msg.sender == self.management
    if _token == empty(address):
        POL(pol).receive_native(value=_amount)
    else:
        assert ERC20(_token).transfer(pol, _amount, default_return_value=True)
    log ToPOL(_token, _amount)

@external
def to_treasury(_token: address, _amount: uint256):
    """
    @notice Transfer `_amount` of `_token` to treasury
    @param _token 
        Token to transfer to treasury.
        Use special designated value to transfer ETH
    @param _amount Amount of tokens to transfer
    """
    assert msg.sender == self.management
    if _token == empty(address):
        raw_call(self.treasury, b"", value=_amount)
    else:
        assert ERC20(_token).transfer(self.treasury, _amount, default_return_value=True)
    log ToTreasury(_token, _amount)

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

@external
def set_treasury(_treasury: address):
    """
    @notice 
        Set the pending treasury address.
        Needs to be accepted by that account separately to transfer treasury over
    @param _treasury New pending treasury address
    """
    assert msg.sender == self.treasury
    self.pending_treasury = _treasury
    log PendingTreasury(_treasury)

@external
def accept_treasury():
    """
    @notice 
        Accept treasury role.
        Can only be called by account previously marked as pending treasury by current treasury
    """
    assert msg.sender == self.pending_treasury
    self.pending_treasury = empty(address)
    self.treasury = msg.sender
    log SetTreasury(msg.sender)