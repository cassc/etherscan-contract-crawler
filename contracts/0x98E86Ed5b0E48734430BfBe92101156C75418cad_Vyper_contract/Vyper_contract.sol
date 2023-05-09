# @version 0.3.7

from vyper.interfaces import ERC20
from vyper.interfaces import ERC20Detailed

implements: ERC20
implements: ERC20Detailed

event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    value: uint256

event Mint:
    minter: indexed(address)
    receiver: indexed(address)
    value: uint256

event Approval:
    owner: indexed(address)
    spender: indexed(address)
    value: uint256

event UpdateSweepRecipient:
    sweep_recipient: indexed(address)

BALWETH: constant(address) =        0x5c6Ee304399DBdB9C8Ef030aB642B10820DB8F56 # B-80BAL-20WETH LP token
VOTER: constant(address) =          0xBA11E7024cbEB1dd2B401C70A83E0d964144686C
name: public(String[32])
symbol: public(String[32])
decimals: public(uint8)

balanceOf: public(HashMap[address, uint256])
allowance: public(HashMap[address, HashMap[address, uint256]])
totalSupply: public(uint256)
sweep_recipient: public(address)

@external
def __init__():
    self.name = "Yearn BAL"
    self.symbol = "yBAL"
    self.decimals = 18
    self.sweep_recipient = 0xFEB4acf3df3cDEA7399794D0869ef76A6EfAff52

@external
def transfer(_to : address, _value : uint256) -> bool:
    """
    @dev Transfer token for a specified address
    @param _to The address to transfer to.
    @param _value The amount to be transferred.
    """
    self.balanceOf[msg.sender] -= _value
    self.balanceOf[_to] += _value
    log Transfer(msg.sender, _to, _value)
    return True


@external
def transferFrom(_from : address, _to : address, _value : uint256) -> bool:
    """
     @dev Transfer tokens from one address to another.
     @param _from address The address which you want to send tokens from
     @param _to address The address which you want to transfer to
     @param _value uint256 the amount of tokens to be transferred
    """
    self.balanceOf[_from] -= _value
    self.balanceOf[_to] += _value
    self.allowance[_from][msg.sender] -= _value
    log Transfer(_from, _to, _value)
    return True


@external
def approve(_spender : address, _value : uint256) -> bool:
    """
    @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    @param _spender The address which will spend the funds.
    @param _value The amount of tokens to be spent.
    """
    self.allowance[msg.sender][_spender] = _value
    log Approval(msg.sender, _spender, _value)
    return True
        
@internal
def _mint(_to: address, _value: uint256):
    self.totalSupply += _value
    self.balanceOf[_to] += _value
    log Transfer(empty(address), _to, _value)

@external
def mint(_amount: uint256 = max_value(uint256), _recipient: address = msg.sender) -> uint256:
    """
    @notice Donate any amount of BALWETH to mint yBAL 1 to 1. 
    Donations are non-redeemable, and will be locked forever.
    @param _amount The desired amount of BALWETH to lock and yBAL to mint.
    @param _recipient The address which minted tokens should be received at.
    """
    assert _recipient not in [self, empty(address)]
    amount: uint256 = _amount
    if amount == max_value(uint256):
        amount = ERC20(BALWETH).balanceOf(msg.sender)
    assert amount > 0
    assert ERC20(BALWETH).transferFrom(msg.sender, VOTER, amount)  # dev: no allowance
    self._mint(_recipient, amount)
    log Mint(msg.sender, _recipient, amount)
    return amount

@external
def set_sweep_recipient(_proposed_recipient: address):
    assert msg.sender == self.sweep_recipient
    self.sweep_recipient = _proposed_recipient
    log UpdateSweepRecipient(_proposed_recipient)

@external
def sweep(_token: address, _amount: uint256 = max_value(uint256)):
    assert msg.sender == self.sweep_recipient
    amount: uint256 = _amount
    if amount == max_value(uint256):
        amount = ERC20(_token).balanceOf(self)
    assert amount > 0
    assert ERC20(_token).transfer(self.sweep_recipient, amount, default_return_value=True)