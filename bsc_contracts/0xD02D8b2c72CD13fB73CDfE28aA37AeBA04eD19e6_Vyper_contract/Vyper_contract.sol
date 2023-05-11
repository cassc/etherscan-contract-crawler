# @version 0.3.7

struct Deposit:
    token0: address
    token1: address
    amount0: uint256
    amount1_min: uint256
    amount1_max: uint256
    pool: address
    depositor: address

interface ERC20:
    def balanceOf(_owner: address) -> uint256: view

interface WrappedEth:
    def deposit(): payable
    def withdraw(amount: uint256): nonpayable

interface UniswapV2Factory:
    def getPair(tokenA: address, tokenB: address) -> address: view

interface UniswapV2Router:
    def WETH() -> address: pure
    def factory() -> address: view
    def swapExactTokensForTokens(amountIn: uint256, amountOutMin: uint256, path: DynArray[address, 2], to: address, deadline: uint256) -> DynArray[uint256, 2]: nonpayable
    def swapExactTokensForETH(amountIn: uint256, amountOutMin: uint256, path: DynArray[address, 2], to: address, deadline: uint256) -> DynArray[uint256, 2]: nonpayable

interface UniswapV2Pair:
    def token0() -> address: view

event Deposited:
    deposit_id: uint256
    token0: address
    token1: address
    amount0: uint256
    amount1_min: uint256
    amount1_max: uint256
    pool: address
    depositor: address

event Withdrawn:
    deposit_id: uint256
    withdrawer: address
    profit_taking_or_stop_loss: bool
    out_amount: uint256

event Ignored:
    deposit_id: uint256

WETH: immutable(address)
VETH: constant(address) = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE # Virtual ETH
MAX_SIZE: constant(uint256) = 16
ROUTER: immutable(address)
FACTORY: immutable(address)
compass: public(address)
admin: public(address)
deposit_size: public(uint256)
deposits: public(HashMap[uint256, Deposit])

@external
def __init__(_compass: address, router: address):
    self.compass = _compass
    self.admin = msg.sender
    ROUTER = router
    WETH = UniswapV2Router(ROUTER).WETH()
    FACTORY = UniswapV2Router(ROUTER).factory()

@internal
def _safe_approve(_token: address, _to: address, _value: uint256):
    _response: Bytes[32] = raw_call(
        _token,
        _abi_encode(_to, _value, method_id=method_id("approve(address,uint256)")),
        max_outsize=32
    )  # dev: failed approve
    if len(_response) > 0:
        assert convert(_response, bool) # dev: failed approve

@internal
def _safe_transfer(_token: address, _to: address, _value: uint256):
    _response: Bytes[32] = raw_call(
        _token,
        _abi_encode(_to, _value, method_id=method_id("transfer(address,uint256)")),
        max_outsize=32
    )  # dev: failed transfer
    if len(_response) > 0:
        assert convert(_response, bool) # dev: failed transfer

@internal
def _safe_transfer_from(_token: address, _from: address, _to: address, _value: uint256):
    _response: Bytes[32] = raw_call(
        _token,
        _abi_encode(_from, _to, _value, method_id=method_id("transferFrom(address,address,uint256)")),
        max_outsize=32
    )  # dev: failed transferFrom
    if len(_response) > 0:
        assert convert(_response, bool) # dev: failed transferFrom

@external
@payable
def deposit(token0: address, token1: address, amount0: uint256, amount1_min: uint256, amount1_max: uint256):
    if token0 == VETH:
        assert msg.value == amount0
        if msg.value > amount0:
            send(msg.sender, msg.value - amount0)
        WrappedEth(WETH).deposit(value=amount0)
    else:
        orig_balance: uint256 = ERC20(token0).balanceOf(self)
        self._safe_transfer_from(token0, msg.sender, self, amount0)
        assert ERC20(token0).balanceOf(self) == orig_balance + amount0
    assert amount1_max > amount1_min
    deposit_id: uint256 = self.deposit_size
    pool: address = UniswapV2Factory(FACTORY).getPair(token0, token1)
    self.deposits[deposit_id] = Deposit({
        token0: token0,
        token1: token1,
        amount0: amount0,
        amount1_min: amount1_min,
        amount1_max: amount1_max,
        pool: pool,
        depositor: msg.sender
    })
    self.deposit_size = deposit_id + 1
    log Deposited(deposit_id, token0, token1, amount0, amount1_min, amount1_max, pool, msg.sender)

@external
def cancel(deposit_id: uint256):
    deposit: Deposit = self.deposits[deposit_id]
    assert msg.sender == deposit.depositor
    self.deposits[deposit_id] = Deposit({
        token0: empty(address),
        token1: empty(address),
        amount0: 0,
        amount1_min: 0,
        amount1_max: 0,
        pool: empty(address),
        depositor: empty(address)
    })
    if deposit.token0 == VETH:
        WrappedEth(WETH).withdraw(deposit.amount0)
        send(msg.sender, deposit.amount0)
    else:
        self._safe_transfer(deposit.token0, msg.sender, deposit.amount0)
    log Withdrawn(deposit_id, msg.sender, False, 0)

@internal
def _withdraw(deposit_id: uint256, profit_taking_or_stop_loss: bool):
    deposit: Deposit = self.deposits[deposit_id]
    self.deposits[deposit_id] = Deposit({
        token0: empty(address),
        token1: empty(address),
        amount0: 0,
        amount1_min: 0,
        amount1_max: 0,
        pool: empty(address),
        depositor: empty(address)
    })
    assert deposit.amount0 > 0
    if deposit.token0 == VETH:
        self._safe_approve(WETH, ROUTER, deposit.amount0)
    else:
        self._safe_approve(deposit.token0, ROUTER, deposit.amount0)
    amounts: DynArray[uint256, 2] = [0, 0]
    if deposit.token1 == VETH:
        if profit_taking_or_stop_loss:
            amounts = UniswapV2Router(ROUTER).swapExactTokensForETH(deposit.amount0, deposit.amount1_max, [deposit.token0, WETH], deposit.depositor, block.timestamp)
        else:
            amounts = UniswapV2Router(ROUTER).swapExactTokensForETH(deposit.amount0, deposit.amount1_min, [deposit.token0, WETH], deposit.depositor, block.timestamp)
    else:
        if profit_taking_or_stop_loss:
            amounts = UniswapV2Router(ROUTER).swapExactTokensForTokens(deposit.amount0, deposit.amount1_max, [deposit.token0, deposit.token1], deposit.depositor, block.timestamp)
        else:
            amounts = UniswapV2Router(ROUTER).swapExactTokensForTokens(deposit.amount0, deposit.amount1_min, [deposit.token0, deposit.token1], deposit.depositor, block.timestamp)
    log Withdrawn(deposit_id, msg.sender, profit_taking_or_stop_loss, amounts[1])

@external
def withdraw(deposit_id: uint256, profit_taking_or_stop_loss: bool):
    assert msg.sender == self.compass
    self._withdraw(deposit_id, profit_taking_or_stop_loss)

@external
def multiple_withdraw(deposit_ids: DynArray[uint256, MAX_SIZE], profit_taking_or_stop_loss: DynArray[bool, MAX_SIZE]):
    assert msg.sender == self.compass
    assert len(deposit_ids) == len(profit_taking_or_stop_loss)
    for i in range(MAX_SIZE):
        if i >= len(deposit_ids):
            break
        self._withdraw(deposit_ids[i], profit_taking_or_stop_loss[i])

@external
def update_admin(new_admin: address):
    assert msg.sender == self.admin
    self.admin = new_admin

@external
def update_compass(new_compass: address):
    assert msg.sender == self.admin
    self.compass = new_compass

@external
@payable
def __default__():
    assert msg.sender == WETH