# @version 0.2.7
from vyper.interfaces import ERC20

implements: ERC20

event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    value: uint256

event Approval:
    owner: indexed(address)
    spender: indexed(address)
    value: uint256

event Pickled:
    receiver: indexed(address)
    corn: uint256
    dai: uint256

struct Permit:
    owner: address
    spender: address
    amount: uint256
    nonce: uint256
    expiry: uint256


name: public(String[64])
symbol: public(String[32])
decimals: public(uint256)
balanceOf: public(HashMap[address, uint256])
nonces: public(HashMap[address, uint256])
allowances: HashMap[address, HashMap[address, uint256]]
total_supply: uint256
dai: ERC20
DOMAIN_SEPARATOR: public(bytes32)
contract_version: constant(String[32]) = "1"
DOMAIN_TYPE_HASH: constant(bytes32) = keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)')
PERMIT_TYPE_HASH: constant(bytes32) = keccak256("Permit(address owner,address spender,uint256 amount,uint256 nonce,uint256 expiry)")


@external
def __init__(_name: String[64], _symbol: String[32], _supply: uint256):
    self.name = _name
    self.symbol = _symbol
    self.decimals = 18
    self.dai = ERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F)
    self.balanceOf[msg.sender] = _supply
    self.total_supply = _supply
    log Transfer(ZERO_ADDRESS, msg.sender, _supply)

    self.DOMAIN_SEPARATOR = keccak256(
        concat(
            DOMAIN_TYPE_HASH,
            keccak256(convert(self.name, Bytes[64])),
            keccak256(convert(contract_version, Bytes[32])),
            convert(chain.id, bytes32),
            convert(self, bytes32)
        )
    )


@view
@external
def totalSupply() -> uint256:
    return self.total_supply


@view
@external
def version() -> String[32]:
    return contract_version


@view
@external
def allowance(owner: address, spender: address) -> uint256:
    return self.allowances[owner][spender]


@internal
def _transfer(sender: address, source: address, receiver: address, amount: uint256) -> bool:
    assert not receiver in [self, ZERO_ADDRESS]
    self.balanceOf[source] -= amount
    self.balanceOf[receiver] += amount
    if source != sender and self.allowances[source][sender] != MAX_UINT256:
        self.allowances[source][sender] -= amount
        log Approval(source, sender, amount)
    log Transfer(source, receiver, amount)
    return True


@external
def transfer(receiver: address, amount: uint256) -> bool:
    return self._transfer(msg.sender, msg.sender, receiver, amount)


@external
def transferFrom(source: address, receiver: address, amount: uint256) -> bool:
    return self._transfer(msg.sender, source, receiver, amount)


@external
def approve(spender: address, amount: uint256) -> bool:
    self.allowances[msg.sender][spender] = amount
    log Approval(msg.sender, spender, amount)
    return True


@view
@internal
def _rate(amount: uint256) -> uint256:
    if self.total_supply == 0:
        return 0
    return amount * self.dai.balanceOf(self) / self.total_supply


@view
@external
def rate() -> uint256:
    return self._rate(10 ** self.decimals)


@internal
def _burn(sender: address, source: address, amount: uint256):
    assert source != ZERO_ADDRESS
    redeemed: uint256 = self._rate(amount)
    self.dai.transfer(source, redeemed)
    log Pickled(source, amount, redeemed)
    self.total_supply -= amount
    self.balanceOf[source] -= amount
    if source != sender and self.allowances[source][sender] != MAX_UINT256:
        self.allowances[source][sender] -= amount
        log Approval(source, sender, amount)
    log Transfer(source, ZERO_ADDRESS, amount)


@external
def burn(_amount: uint256 = MAX_UINT256):
    """
    Burn CORN for DAI at a rate of (DAI in contract / CORN supply)
    """
    amount: uint256 = min(_amount, self.balanceOf[msg.sender])
    self._burn(msg.sender, msg.sender, amount)


@external
def burnFrom(source: address, amount: uint256):
    self._burn(msg.sender, source, amount)


@view
@internal
def message_digest(owner: address, spender: address, amount: uint256, nonce: uint256, expiry: uint256) -> bytes32:
    return keccak256(
        concat(
            b'\x19\x01',
            self.DOMAIN_SEPARATOR,
            keccak256(
                concat(
                    PERMIT_TYPE_HASH,
                    convert(owner, bytes32),
                    convert(spender, bytes32),
                    convert(amount, bytes32),
                    convert(nonce, bytes32),
                    convert(expiry, bytes32),
                )
            )
        )
    )


@external
def permit(owner: address, spender: address, amount: uint256, nonce: uint256, expiry: uint256, signature: Bytes[65]) -> bool:
    assert expiry >= block.timestamp  # dev: permit expired
    assert owner != ZERO_ADDRESS  # dev: invalid owner
    assert nonce == self.nonces[owner]  # dev: invalid nonce
    digest: bytes32 = self.message_digest(owner, spender, amount, nonce, expiry)
    # NOTE: signature is packed as r, s, v
    r: uint256 = convert(slice(signature, 0, 32), uint256)
    s: uint256 = convert(slice(signature, 32, 32), uint256)
    v: uint256 = convert(slice(signature, 64, 1), uint256)
    assert ecrecover(digest, v, r, s) == owner  # dev: invalid signature

    self.allowances[owner][spender] = amount
    self.nonces[owner] += 1
    log Approval(owner, spender, amount)
    return True