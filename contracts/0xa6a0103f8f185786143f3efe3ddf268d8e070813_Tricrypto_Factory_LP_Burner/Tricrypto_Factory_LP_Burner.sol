
# @version 0.3.7
"""
@title Tricrypto Factory LP Burner
@notice Withdraws Tricrypto LP tokens
"""


interface ERC20:
    def transferFrom(_from: address, _to: address, _value: uint256) -> bool: nonpayable
    def balanceOf(_owner: address) -> uint256: view
    def decimals() -> uint256: view

interface CryptoSwap:
    def remove_liquidity_one_coin(token_amount: uint256, i: uint256, min_amount: uint256,
                                  use_eth: bool = False, receiver: address = msg.sender) -> uint256: nonpayable
    def coins(_i: uint256) -> address: view
    def price_oracle(_i: uint256) -> uint256: view
    def lp_price() -> uint256: view

interface PoolProxy:
    def burners(_coin: address) -> address: view


BPS: constant(uint256) = 10000

slippage_of: public(HashMap[address, uint256])
priority_of: public(HashMap[address, uint256])
receiver_of: public(HashMap[address, address])

pool_proxy: public(address)
slippage: public(uint256)
receiver: public(address)
recovery: public(address)

owner: public(address)
emergency_owner: public(address)
future_owner: public(address)
future_emergency_owner: public(address)


@external
def __init__(_pool_proxy: address, _owner: address, _emergency_owner: address):
    """
    @notice Contract constructor
    @param _pool_proxy Address of pool owner proxy
    @param _owner Owner address
    @param _emergency_owner Emergency owner address
    """
    self.pool_proxy = _pool_proxy
    self.receiver = _pool_proxy
    self.recovery = _pool_proxy
    self.owner = _owner
    self.emergency_owner = _emergency_owner

    self.slippage = 100  # 1%
    # 3crv to fee_distributor
    self.receiver_of[0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490] = 0xA464e6DCda8AC41e03616F95f4BC98a13b8922Dc

    self.priority_of[0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490] = 64  # 3crv
    self.priority_of[0xdAC17F958D2ee523a2206206994597C13D831ec7] = 56  # USDT
    self.priority_of[0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48] = 56  # USDC
    self.priority_of[0x6B175474E89094C44Da98b954EedeAC495271d0F] = 56  # DAI
    self.priority_of[0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E] = 48  # crvUSD


@internal
def _burn(_swap: address, _amount: uint256):
    coins: address[3] = [CryptoSwap(_swap).coins(0), CryptoSwap(_swap).coins(1), CryptoSwap(_swap).coins(2)]
    priorities: uint256[3] = [self.priority_of[coins[0]], self.priority_of[coins[1]], self.priority_of[coins[2]]]
    assert priorities[0] > 0 or priorities[1] > 0 or priorities[2] > 0  # dev: unknown coins

    i: uint256 = 0
    if priorities[1] > priorities[i]:
        i = 1
    if priorities[2] > priorities[i]:
        i = 2

    slippage: uint256 = self.slippage_of[_swap]
    if slippage == 0:
        slippage = self.slippage

    min_amount: uint256 = _amount * CryptoSwap(_swap).lp_price() / 10 ** 18
    if i > 0:
        min_amount = min_amount * 10 ** 18 / CryptoSwap(_swap).price_oracle(i - 1)
    min_amount /= 10 ** (18 - ERC20(coins[i]).decimals())
    min_amount -= min_amount * slippage / BPS

    receiver: address = self.receiver_of[coins[i]]
    if receiver == ZERO_ADDRESS:
        receiver = self.receiver
    CryptoSwap(_swap).remove_liquidity_one_coin(_amount, i, min_amount, True, receiver)


@external
def burn(_coin: address) -> bool:
    """
    @notice Convert `_coin` by removing liquidity
    @param _coin Address of the coin(swap) being converted
    @return bool success
    """
    # transfer coins from caller
    amount: uint256 = ERC20(_coin).balanceOf(msg.sender)
    if amount != 0:
        ERC20(_coin).transferFrom(msg.sender, self, amount)

    # get actual balance in case of pre-existing balance
    amount = ERC20(_coin).balanceOf(self)

    if amount != 0:
        self._burn(_coin, amount)

    return True


@external
def burn_amount(_coin: address, _amount_to_burn: uint256):
    """
    @notice Burn a specific quantity of `_coin`
    @dev Useful when the total amount to burn is so large that it fails from slippage
    @param _coin Address of the coin being converted
    @param _amount_to_burn Amount of the coin to burn
    """
    pool_proxy: address = self.pool_proxy
    amount: uint256 = ERC20(_coin).balanceOf(pool_proxy)
    if PoolProxy(pool_proxy).burners(_coin) == self and amount != 0:
        ERC20(_coin).transferFrom(pool_proxy, self, amount)

    amount = ERC20(_coin).balanceOf(self)
    assert amount >= _amount_to_burn, "Insufficient balance"

    self._burn(_coin, _amount_to_burn)


@external
def set_priority_of(_coin: address, _priority: uint256):
    """
    @notice Set priority of a coin
    @dev Bigger value means higher priority
    @param _coin Token address
    @param _priority Token priority
    """
    assert msg.sender in [self.owner, self.emergency_owner]  # dev: only owner
    self.priority_of[_coin] = _priority


@external
def set_many_priorities(_coins: address[8], _priorities: uint256[8]):
    """
    @notice Set priority of many coins
    @dev Bigger value means higher priority
    @param _coins Token addresses
    @param _priorities Token priorities
    """
    assert msg.sender in [self.owner, self.emergency_owner]  # dev: only owner
    for i in range(8):
        coin: address = _coins[i]
        if coin == ZERO_ADDRESS:
            break
        self.priority_of[coin] = _priorities[i]


@external
def set_slippage_of(_coin: address, _slippage: uint256):
    """
    @notice Set custom slippage limit of a coin
    @dev Using self.slippage by default
    @param _coin Token address
    @param _slippage Slippage in bps for pool of token
    """
    assert msg.sender in [self.owner, self.emergency_owner]  # dev: only owner
    assert _slippage <= BPS  # dev: slippage too high
    self.slippage_of[_coin] = _slippage


@external
def set_many_slippages(_coins: address[8], _slippages: uint256[8]):
    """
    @notice Set custom slippage limit of a coin
    @dev Using self.slippage by default
    @param _coins Token addresses
    @param _slippages Slippages in bps for each pool of token
    """
    assert msg.sender in [self.owner, self.emergency_owner]  # dev: only owner
    for i in range(8):
        coin: address = _coins[i]
        if coin == ZERO_ADDRESS:
            break
        assert _slippages[i] <= BPS  # dev: slippage too high
        self.slippage_of[coin] = _slippages[i]


@external
def set_slippage(_slippage: uint256):
    """
    @notice Set default slippage parameter
    @param _slippage Slippage value in bps
    """
    assert msg.sender in [self.owner, self.emergency_owner]  # dev: only owner
    assert _slippage <= BPS  # dev: slippage too high
    self.slippage = _slippage


@external
def set_receiver_of(_coin: address, _receiver: address):
    """
    @notice Set receiver of a coin
    @dev Using self.receiver by default
    @param _coin Token address
    @param _receiver Receiver of a token
    """
    assert msg.sender in [self.owner, self.emergency_owner]  # dev: only owner
    self.receiver_of[_coin] = _receiver


@external
def set_many_receivers(_coins: address[8], _receivers: address[8]):
    """
    @notice Set receivers of many coins
    @dev Using self.receiver by default
    @param _coins Token addresses
    @param _receivers Receivers of each token
    """
    assert msg.sender in [self.owner, self.emergency_owner]  # dev: only owner
    for i in range(8):
        coin: address = _coins[i]
        if coin == ZERO_ADDRESS:
            break
        self.receiver_of[coin] = _receivers[i]


@external
def set_receiver(_receiver: address):
    """
    @notice Set default receiver
    @param _receiver Address of default receiver
    """
    assert msg.sender in [self.owner, self.emergency_owner]  # dev: only owner
    self.receiver = _receiver


@external
def recover_balance(_coin: address) -> bool:
    """
    @notice Recover ERC20 tokens from this contract
    @dev Tokens are sent to the recovery address
    @param _coin Token address
    @return bool success
    """
    assert msg.sender in [self.owner, self.emergency_owner]  # dev: only owner

    amount: uint256 = ERC20(_coin).balanceOf(self)
    response: Bytes[32] = raw_call(
        _coin,
        _abi_encode(self.recovery, amount, method_id=method_id("transfer(address,uint256)")),
        max_outsize=32,
    )
    if len(response) != 0:
        assert convert(response, bool)

    return True


@external
def set_recovery(_recovery: address) -> bool:
    """
    @notice Set the token recovery address
    @param _recovery Token recovery address
    @return bool success
    """
    assert msg.sender == self.owner  # dev: only owner
    self.recovery = _recovery

    return True


@external
def commit_transfer_ownership(_future_owner: address) -> bool:
    """
    @notice Commit a transfer of ownership
    @dev Must be accepted by the new owner via `accept_transfer_ownership`
    @param _future_owner New owner address
    @return bool success
    """
    assert msg.sender == self.owner  # dev: only owner
    self.future_owner = _future_owner

    return True


@external
def accept_transfer_ownership() -> bool:
    """
    @notice Accept a transfer of ownership
    @return bool success
    """
    assert msg.sender == self.future_owner  # dev: only owner
    self.owner = msg.sender

    return True


@external
def commit_transfer_emergency_ownership(_future_owner: address) -> bool:
    """
    @notice Commit a transfer of ownership
    @dev Must be accepted by the new owner via `accept_transfer_ownership`
    @param _future_owner New owner address
    @return bool success
    """
    assert msg.sender == self.emergency_owner  # dev: only owner
    self.future_emergency_owner = _future_owner

    return True


@external
def accept_transfer_emergency_ownership() -> bool:
    """
    @notice Accept a transfer of ownership
    @return bool success
    """
    assert msg.sender == self.future_emergency_owner  # dev: only owner
    self.emergency_owner = msg.sender

    return True