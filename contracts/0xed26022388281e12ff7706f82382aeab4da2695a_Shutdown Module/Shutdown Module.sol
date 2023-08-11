# @version 0.3.7
"""
@title Shutdown Module
@author 0xkorin, Yearn Finance
@license Copyright (c) Yearn Finance, 2023 - all rights reserved
@notice
    Module that allows yETH redemptions for ETH in 1:1 if either pool or POL is killed.
    Redeemed yETH is burned by bootstrap contract to repay its debt
"""

from vyper.interfaces import ERC20

interface Pool:
    def killed() -> bool: view

interface Bootstrap:
    def repay(_amount: uint256): nonpayable

interface POL:
    def send_native(_receiver: address, _amount: uint256): nonpayable
    def killed() -> bool: view

token: public(immutable(address))
bootstrap: public(immutable(address))
pol: public(immutable(address))
pool: public(address)
management: public(address)

event Redeem:
    account: indexed(address)
    amount: uint256

@external
def __init__(_token: address, _bootstrap: address, _pol: address):
    """
    @notice Constructor
    @param _token yETH token address
    @param _bootstrap Bootstrap address
    @param _pol POL address
    """
    token = _token
    bootstrap = _bootstrap
    pol = _pol
    self.management = msg.sender
    assert ERC20(_token).approve(_bootstrap, max_value(uint256), default_return_value=True)

@external
def redeem(_amount: uint256, _receiver: address = msg.sender):
    """
    @notice Redeem yETH for ETH 1:1
    @param _amount of yETH to redeem
    @param _receiver Account to send ETH to
    """
    assert Pool(self.pool).killed() or POL(pol).killed()
    ERC20(token).transferFrom(msg.sender, self, _amount)
    Bootstrap(bootstrap).repay(_amount)
    POL(pol).send_native(_receiver, _amount)
    log Redeem(msg.sender, _amount)

@external
def set_pool(_pool: address):
    """
    @notice Set yETH LSD pool address
    @param _pool yETH pool
    """
    assert msg.sender == self.management
    assert self.pool == empty(address)
    self.pool = _pool
    self.management = empty(address)