
# @version ^0.3.9
# @title Settled EthXYToken

from vyper.interfaces import ERC20

implements: ERC20

event Transfer:
    _from: indexed(address)
    _to: indexed(address)
    _value: uint256

event Approval:
    _owner: indexed(address)
    _spender: indexed(address)
    _value: uint256

_name: constant(String[24]) = "Settled ETHXY Token"
_symbol: constant(String[5]) = "SEXY"
decimals: public(constant(uint256)) = 18
totalSupply: public(uint256)

balanceOf: public(HashMap[address, uint256])
allowance: public(HashMap[address, HashMap[address, uint256]])

minter: public(address)

@view
@external
def name() -> String[24]:
    return _name

@view
@external
def symbol() -> String[5]:
    return _symbol

@external
def __init__():
    self.minter = msg.sender

@external
def set_minter(minter: address):
    assert msg.sender == self.minter
    self.minter = minter

@external
def approve(spender: address, amount: uint256) -> bool:
    self.allowance[msg.sender][spender] = amount
    log Approval(msg.sender, spender, amount)
    return True

@external
def increaseAllowance(spender: address, addedValue: uint256) -> bool:
    self.allowance[msg.sender][spender] += addedValue
    log Approval(msg.sender, spender, self.allowance[msg.sender][spender])
    return True

@external
def decreaseAllowance(spender: address, subtractedValue: uint256) -> bool:
    self.allowance[msg.sender][spender] -= subtractedValue
    log Approval(msg.sender, spender, self.allowance[msg.sender][spender])
    return True

@external
def transfer(_to: address, _value: uint256) -> bool:
    self.balanceOf[msg.sender] -= _value
    self.balanceOf[_to] += _value
    log Transfer(msg.sender, _to, _value)
    return True

@external
def transferFrom(_from: address, _to: address, _value: uint256) -> bool:
    self.allowance[_from][msg.sender] -= _value
    self.balanceOf[_from] -= _value
    self.balanceOf[_to] += _value
    log Transfer(_from, _to, _value)
    return True

@external
def mint(_to: address, _value: uint256):
    assert msg.sender == self.minter
    self.balanceOf[_to] += _value
    self.totalSupply += _value
    log Transfer(ZERO_ADDRESS, _to, _value)

@external
def burn(_value: uint256) -> uint256:
    self.balanceOf[msg.sender] -= _value
    self.totalSupply -= _value
    log Transfer(msg.sender, ZERO_ADDRESS, _value)
    return _value

################################################################
#                           EIP-2612                           #
################################################################

nonces: public(HashMap[address, uint256])

_DOMAIN_TYPEHASH: constant(bytes32) = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
_PERMIT_TYPE_HASH: constant(bytes32) = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")
_MINT_TYPE_HASH: constant(bytes32) = keccak256("Mint(address to,uint256 value,uint256 amountMinted)")


@external
def permit(owner: address, spender: address, amount: uint256, deadline: uint256, v: uint8, r: bytes32, s: bytes32):
    assert deadline >= block.timestamp
    nonce: uint256 = self.nonces[owner]
    self.nonces[owner] = nonce + 1

    domain_separator: bytes32 = keccak256(
        _abi_encode(_DOMAIN_TYPEHASH, keccak256(_name), keccak256("1.0"), chain.id, self)
    )

    struct_hash: bytes32 = keccak256(_abi_encode(_PERMIT_TYPE_HASH, owner, spender, amount, nonce, deadline))
    hash: bytes32 = keccak256(
        concat(
            b"\x19\x01",
            domain_separator,
            struct_hash
        )
    )

    assert owner == ecrecover(hash, v, r, s)
    self.nonces[owner] += 1
    self.allowance[owner][spender] = amount
    log Approval(owner, spender, amount)

amount_minted: public(HashMap[address, uint256])

@external
def mint_by_sig(to: address, amount: uint256, v: uint8, r: bytes32, s: bytes32):
    domain_separator: bytes32 = keccak256(
        _abi_encode(_DOMAIN_TYPEHASH, keccak256(_name), keccak256("1.0"), chain.id, self)
    )

    struct_hash: bytes32 = keccak256(_abi_encode(_MINT_TYPE_HASH, to, amount, self.amount_minted[to]))
    hash: bytes32 = keccak256(
        concat(
            b"\x19\x01",
            domain_separator,
            struct_hash
        )
    )

    assert self.minter == ecrecover(hash, v, r, s)

    self.amount_minted[to] += amount
    self._mint(to, amount)

@internal
def _mint(_to: address, _value: uint256):
    self.balanceOf[_to] += _value
    self.totalSupply += _value
    log Transfer(ZERO_ADDRESS, _to, _value)

@internal
def _burn(_from: address, _value: uint256):
    assert self.balanceOf[_from] >= _value
    self.balanceOf[_from] -= _value
    self.totalSupply -= _value
    log Transfer(_from, ZERO_ADDRESS, _value)