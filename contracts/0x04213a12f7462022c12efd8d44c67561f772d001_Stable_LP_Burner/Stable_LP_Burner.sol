
# @version 0.3.7
"""
@title Stable LP Burner
@notice Withdraws Stable LP tokens
"""

interface ERC20:
    def transfer(_to: address, _value: uint256) -> bool: nonpayable
    def transferFrom(_from: address, _to: address, _value: uint256) -> bool: nonpayable
    def balanceOf(_owner: address) -> uint256: view
    def decimals() -> uint256: view

interface CurveToken:
    def minter() -> address: view

interface StableSwap:
    def remove_liquidity_one_coin(token_amount: uint256, i: int128, min_amount: uint256) -> uint256: nonpayable
    def coins(_i: uint256) -> address: view
    def price_oracle(_i: uint256=0) -> uint256: view
    def get_virtual_price() -> uint256: view


interface Proxy:
    def burners(_coin: address) -> address: view


enum Price:
    CONST
    ORACLE
    ORACLE_NUM


struct SwapData:
    pool: StableSwap
    price: Price
    slippage: uint256  # 0 will use default
    # Should be fetched according to priorities in future
    i: uint8  # No convert checks needed
    coin: ERC20

struct SwapDataInput:
    token: CurveToken
    price: Price
    slippage: uint256  # 0 will use default
    i: uint8
    token_separate: bool  # For old implementations


ETH_ADDRESS: constant(address) = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
ONE: constant(uint256) = 10 ** 18  # Precision

BPS: constant(uint256) = 100 * 100
SLIPPAGE: constant(uint256) = 100  # 1%

swap_data: public(HashMap[address, SwapData])

PROXY: public(immutable(Proxy))

is_killed: public(bool)
killed_coin: public(HashMap[address, bool])

owner: public(address)
emergency_owner: public(address)
future_owner: public(address)
future_emergency_owner: public(address)


@external
def __init__(_proxy: Proxy, _owner: address, _emergency_owner: address):
    """
    @notice Contract constructor
    @param _proxy Owner of admin fees
    @param _owner Owner address. Can kill the contract.
    @param _emergency_owner Emergency owner address. Can kill the contract.
    """
    PROXY = _proxy
    self.owner = _owner
    self.emergency_owner = _emergency_owner


@internal
def _transfer_out(_coin: ERC20):
    if _coin.address == ETH_ADDRESS:
        raw_call(PROXY.address, b"", value=self.balance)
    else:
        assert _coin.transfer(
            PROXY.address, _coin.balanceOf(self), default_return_value=True
        )  # safe transfer


@internal
@pure
def _get_price(_swap_data: SwapData) -> uint256:
    """
    @notice Get price of i-th token in LP accounting decimal difference
    @param _swap_data Swap to find price for
    @return Price with ONE precision
    """
    price: uint256 = 10 ** _swap_data.coin.decimals()

    price = price * _swap_data.pool.get_virtual_price() / ONE

    # Price.CONST = 1:1, no actions needed

    if _swap_data.price == Price.ORACLE:
        if _swap_data.i > 0:
            price = price * ONE / _swap_data.pool.price_oracle()

    if _swap_data.price == Price.ORACLE_NUM:
        if _swap_data.i > 0:
            price = price * ONE / _swap_data.pool.price_oracle(convert(_swap_data.i, uint256))

    return price


@internal
def _fetch_swap_data(_coin: address) -> SwapData:
    data: SwapData = self.swap_data[_coin]
    if data.pool.address == empty(address):
        # Try default swap_data, works for latest implementations
        data = SwapData({
            pool: StableSwap(_coin),
            price: Price.ORACLE,  # TODO: auto-detect num version
            slippage: 0,
            i: 0,  # TODO
            coin: ERC20(StableSwap(_coin).coins(0)),
        })
        self.swap_data[_coin] = data
    return data


@internal
def _burn(_coin: ERC20, _amount: uint256):
    """
    @notice Burn implementation
    """
    assert not self.is_killed and not self.killed_coin[_coin.address], "Is killed"

    swap_data: SwapData = self._fetch_swap_data(_coin.address)

    min_amount: uint256 = _amount * self._get_price(swap_data) / ONE

    slippage: uint256 = swap_data.slippage
    if slippage == 0:
        slippage = SLIPPAGE
    min_amount -= min_amount * slippage / BPS

    swap_data.pool.remove_liquidity_one_coin(_amount, convert(swap_data.i, int128), min_amount)
    self._transfer_out(swap_data.coin)


@external
def burn(_coin: ERC20) -> bool:
    """
    @notice Unwrap `_coin`
    @param _coin Address of the coin being unwrapped
    @return bool Success, remained for compatibility
    """
    amount: uint256 = _coin.balanceOf(msg.sender)
    if amount != 0:
        _coin.transferFrom(msg.sender, self, amount)

    amount = _coin.balanceOf(self)

    if amount != 0:
        self._burn(_coin, amount)

    return True


@external
def burn_amount(_coin: ERC20, _amount_to_burn: uint256):
    """
    @notice Burn a specific quantity of `_coin`
    @dev Useful when the total amount to burn is so large that it fails
    @param _coin Address of the coin being converted
    @param _amount_to_burn Amount of the coin to burn
    """
    amount: uint256 = _coin.balanceOf(PROXY.address)
    if amount != 0 and PROXY.burners(_coin.address) == self:
        _coin.transferFrom(PROXY.address, self, amount)

    amount = _coin.balanceOf(self)
    assert amount >= _amount_to_burn, "Insufficient balance"

    self._burn(_coin, _amount_to_burn)


@external
@view
def burns_to(_coin: ERC20) -> DynArray[address, 8]:
    """
    @notice Get resulting coins of burning `_coin`
    @param _coin Coin to burn
    """
    return [self.swap_data[_coin.address].coin.address]


@external
def set_swap_data(_swap_data: SwapDataInput):
    """
    @notice Set custom swap data, needed for old pools
    @param _swap_data Data needed for burning
    """
    assert msg.sender in [self.owner, self.emergency_owner], "Only owner"

    swap: address = _swap_data.token.address
    if _swap_data.token_separate:
        swap = _swap_data.token.minter()

    swap_data: SwapData = SwapData({
            pool: StableSwap(swap),
            price: _swap_data.price,
            slippage: _swap_data.slippage,
            i: _swap_data.i,
            coin: ERC20(StableSwap(swap).coins(convert(_swap_data.i, uint256))),
    })
    self.swap_data[_swap_data.token.address] = swap_data

    if _swap_data.price != Price.CONST:
        self._get_price(swap_data)  # Check call


@external
def recover_balance(_coin: ERC20, _amount: uint256=max_value(uint256)):
    """
    @notice Recover ERC20 tokens or Ether from this contract
    @dev Tokens are sent to proxy
    @param _coin Token address
    @param _amount Amount to recover
    """
    amount: uint256 = _amount
    if _coin.address == ETH_ADDRESS:
        if amount == max_value(uint256):
            amount = self.balance
        raw_call(PROXY.address, b"", value=amount)
    else:
        if amount == max_value(uint256):
            amount = _coin.balanceOf(self)
        _coin.transfer(PROXY.address, amount)  # do not need safe transfer


@external
def set_killed(_is_killed: bool, _coin: address=empty(address)):
    """
    @notice Stop a contract or specific coin to be burnt
    @dev Executable only via owner or emergency owner
    @param _is_killed Boolean value to set
    @param _coin Coin to stop from burning, ZERO_ADDRESS to kill all coins (by default)
    """
    assert msg.sender in [self.owner, self.emergency_owner], "Only owner"

    if _coin == empty(address):
        self.is_killed = _is_killed
    else:
        self.killed_coin[_coin] = _is_killed


@external
def commit_transfer_ownership(_future_owner: address) -> bool:
    """
    @notice Commit a transfer of ownership
    @dev Must be accepted by the new owner via `accept_transfer_ownership`
    @param _future_owner New owner address
    @return bool success
    """
    assert msg.sender == self.owner, "Only owner"
    self.future_owner = _future_owner

    return True


@external
def accept_transfer_ownership() -> bool:
    """
    @notice Accept a transfer of ownership
    @return bool success
    """
    assert msg.sender == self.future_owner, "Only owner"
    self.owner = msg.sender

    return True


@external
def commit_transfer_emergency_ownership(_future_owner: address) -> bool:
    """
    @notice Commit a transfer of emergency ownership
    @dev Must be accepted by the new owner via `accept_transfer_emergency_ownership`
    @param _future_owner New owner address
    @return bool success
    """
    assert msg.sender == self.emergency_owner, "Only owner"
    self.future_emergency_owner = _future_owner

    return True


@external
def accept_transfer_emergency_ownership() -> bool:
    """
    @notice Accept a transfer of emergency ownership
    @return bool success
    """
    assert msg.sender == self.future_emergency_owner, "Only owner"
    self.emergency_owner = msg.sender

    return True