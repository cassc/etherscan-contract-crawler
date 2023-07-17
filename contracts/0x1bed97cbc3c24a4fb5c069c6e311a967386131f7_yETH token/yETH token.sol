# @version 0.3.7
"""
@title yETH token
@author 0xkorin, Yearn Finance
@license Copyright (c) Yearn Finance, 2023 - all rights reserved
"""

from vyper.interfaces import ERC20
implements: ERC20

totalSupply: public(uint256)
balanceOf: public(HashMap[address, uint256])
allowance: public(HashMap[address, HashMap[address, uint256]])

name: public(constant(String[11])) = "Yearn Ether"
symbol: public(constant(String[4])) = "yETH"
decimals: public(constant(uint8)) = 18

minters: public(HashMap[address, bool])
management: public(address)

event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    value: uint256

event Approval:
    owner: indexed(address)
    spender: indexed(address)
    value: uint256

event SetManagement:
    account: indexed(address)

event SetMinter:
    account: indexed(address)
    minter: bool

@external
def __init__():
    self.management = msg.sender
    log Transfer(empty(address), msg.sender, 0)

@external
def transfer(_to: address, _value: uint256) -> bool:
    """
    @notice Transfers `_value` tokens from the caller's address to `_to`
    @param _to The address shares are being transferred to. Must not be this contract's
        address, must not be 0x0
    @param _value The quantity of tokens to transfer
    @return True
    """
    assert _to != empty(address) and _to != self
    self.balanceOf[msg.sender] -= _value
    self.balanceOf[_to] += _value
    log Transfer(msg.sender, _to, _value)
    return True

@external
def transferFrom(_from: address, _to: address, _value: uint256) -> bool:
    """
    @notice Transfers `_value` tokens from `_from` to `_to`.
        Transfering tokens will decrement the caller's `allowance` by `_value`
    @param _from The address tokens are being transferred from
    @param _to The address tokens are being transferred to. Must not be this contract's
        address, must not be 0x0
    @param _value The quantity of tokens to transfer
    @return True
    """
    assert _to != empty(address) and _to != self
    self.allowance[_from][msg.sender] -= _value
    self.balanceOf[_from] -= _value
    self.balanceOf[_to] += _value
    log Transfer(_from, _to, _value)
    return True

@external
def approve(_spender: address, _value: uint256) -> bool:
    """
    @notice Approve the passed address to spend the specified amount of tokens on behalf of
        `msg.sender`. Beware that changing an allowance with this method brings the risk
        that someone may use both the old and the new allowance by unfortunate transaction
        ordering. See https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    @param _spender The address which will spend the funds
    @param _value The amount of tokens to be spent
    @return True
    """
    assert _spender != empty(address)
    self.allowance[msg.sender][_spender] = _value
    log Approval(msg.sender, _spender, _value)
    return True

@external
def increaseAllowance(_spender: address, _value: uint256) -> bool:
    """
    @notice Increase the allowance of the passed address to spend the total amount of tokens
        on behalf of `msg.sender`. This method mitigates the risk that someone may use both
        the old and the new allowance by unfortunate transaction ordering.
        See https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    @param _spender The address which will spend the funds
    @param _value The amount of tokens to increase the allowance by
    @return True
    """
    assert _spender != empty(address)
    allowance: uint256 = self.allowance[msg.sender][_spender] + _value
    self.allowance[msg.sender][_spender] = allowance
    log Approval(msg.sender, _spender, allowance)
    return True

@external
def decreaseAllowance(_spender: address, _value: uint256) -> bool:
    """
    @notice Decrease the allowance of the passed address to spend the total amount of tokens
        on behalf of `msg.sender`. This method mitigates the risk that someone may use both
        the old and the new allowance by unfortunate transaction ordering.
        See https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    @param _spender The address which will spend the funds
    @param _value The amount of tokens to decrease the allowance by
    @return True
    """
    assert _spender != empty(address)
    allowance: uint256 = self.allowance[msg.sender][_spender]
    if _value > allowance:
        allowance = 0
    else:
        allowance -= _value
    self.allowance[msg.sender][_spender] = allowance
    log Approval(msg.sender, _spender, allowance)
    return True

@external
def set_management(_management: address):
    """
    @notice Set new management address
    """
    assert msg.sender == self.management
    self.management = _management
    log SetManagement(_management)

@external
def set_minter(_account: address, _minter: bool = True):
    """
    @notice Grant or revoke mint and burn powers to an account
    @param _account The account to change mint/burn powers of
    @param _minter Flag whether or not to allow minting/burning
    """
    assert msg.sender == self.management
    self.minters[_account] = _minter
    log SetMinter(_account, _minter)

@external
def mint(_account: address, _value: uint256):
    """
    @notice Mint `_value` tokens to `_account`
    @param _account The account to mint tokens to
    @param _value Amount of tokens to mint
    """
    assert self.minters[msg.sender]
    self.totalSupply += _value
    self.balanceOf[_account] += _value
    log Transfer(empty(address), _account, _value)

@external
def burn(_account: address, _value: uint256):
    """
    @notice Burn `_value` tokens from `_account`
    @param _account The account to burn tokens from
    @param _value Amount of tokens to burn
    """
    assert self.minters[msg.sender]
    self.totalSupply -= _value
    self.balanceOf[_account] -= _value
    log Transfer(_account, empty(address), _value)