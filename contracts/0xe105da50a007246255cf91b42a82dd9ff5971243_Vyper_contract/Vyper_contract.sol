# @version 0.3.9

struct Deposit:
    path: DynArray[address, MAX_SIZE]
    amount1: uint256
    depositor: address

enum WithdrawType:
    CANCEL
    PROFIT_TAKING
    STOP_LOSS

interface ERC20:
    def balanceOf(_owner: address) -> uint256: view

interface WrappedEth:
    def deposit(): payable

interface UniswapV2Router:
    def WETH() -> address: pure
    def swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn: uint256, amountOutMin: uint256, path: DynArray[address, MAX_SIZE], to: address, deadline: uint256): nonpayable
    def swapExactTokensForETHSupportingFeeOnTransferTokens(amountIn: uint256, amountOutMin: uint256, path: DynArray[address, MAX_SIZE], to: address, deadline: uint256): nonpayable
    def getAmountsOut(amountIn: uint256, path: DynArray[address, MAX_SIZE]) -> DynArray[uint256, MAX_SIZE]: view

event Deposited:
    deposit_id: uint256
    token0: address
    token1: address
    amount0: uint256
    amount1: uint256
    depositor: address
    profit_taking: uint256
    stop_loss: uint256

event Withdrawn:
    deposit_id: uint256
    withdrawer: address
    withdraw_type: WithdrawType
    withdraw_amount: uint256

event UpdateCompass:
    old_compass: address
    new_compass: address

event UpdateRefundWallet:
    old_refund_wallet: address
    new_refund_wallet: address

event UpdateFee:
    old_fee: uint256
    new_fee: uint256

event SetPaloma:
    paloma: bytes32

WETH: immutable(address)
VETH: constant(address) = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE # Virtual ETH
MAX_SIZE: constant(uint256) = 8
ROUTER: immutable(address)
compass: public(address)
deposit_size: public(uint256)
deposits: public(HashMap[uint256, Deposit])
refund_wallet: public(address)
fee: public(uint256)
paloma: public(bytes32)

@external
def __init__(_compass: address, router: address, _refund_wallet: address, _fee: uint256):
    self.compass = _compass
    ROUTER = router
    WETH = UniswapV2Router(ROUTER).WETH()
    self.refund_wallet = _refund_wallet
    self.fee = _fee
    log UpdateCompass(empty(address), _compass)
    log UpdateRefundWallet(empty(address), _refund_wallet)
    log UpdateFee(0, _fee)

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
@nonreentrant("lock")
def deposit(path: DynArray[address, MAX_SIZE], amount0: uint256, min_amount1: uint256, profit_taking: uint256, stop_loss: uint256):
    _value: uint256 = msg.value
    _fee: uint256 = self.fee
    assert _value >= _fee, "Insufficient fee"
    assert self.paloma != empty(bytes32), "Paloma not set"
    send(self.refund_wallet, _fee)
    _value = unsafe_sub(_value, _fee)
    assert len(path) >= 2, "Wrong path"
    _path: DynArray[address, MAX_SIZE] = path
    token0: address = path[0]
    last_index: uint256 = unsafe_sub(len(path), 1)
    token1: address = path[last_index]
    _amount0: uint256 = amount0
    if token0 == VETH:
        assert _value >= amount0, "Insufficient deposit"
        if _value > amount0:
            send(msg.sender, unsafe_sub(_value, amount0))
        WrappedEth(WETH).deposit(value=amount0)
        _path[0] = WETH
    else:
        send(msg.sender, _value)
        _amount0 = ERC20(token0).balanceOf(self)
        self._safe_transfer_from(token0, msg.sender, self, amount0)
        _amount0 = ERC20(token0).balanceOf(self) - _amount0
    if token1 == VETH:
        _path[last_index] = WETH
    self._safe_approve(_path[0], ROUTER, _amount0)
    _amount1: uint256 = ERC20(_path[last_index]).balanceOf(self)
    UniswapV2Router(ROUTER).swapExactTokensForTokensSupportingFeeOnTransferTokens(_amount0, min_amount1, _path, self, block.timestamp)
    _amount1 = ERC20(_path[last_index]).balanceOf(self) - _amount1
    assert _amount1 > 0, "Insufficient deposit"
    deposit_id: uint256 = self.deposit_size
    self.deposits[deposit_id] = Deposit({
        path: path,
        amount1: _amount1,
        depositor: msg.sender
    })
    self.deposit_size = unsafe_add(deposit_id, 1)
    log Deposited(deposit_id, token0, token1, amount0, _amount1, msg.sender, profit_taking, stop_loss)

@internal
def _withdraw(deposit_id: uint256, min_amount0: uint256, withdraw_type: WithdrawType) -> uint256:
    deposit: Deposit = self.deposits[deposit_id]
    if withdraw_type == WithdrawType.CANCEL:
        assert msg.sender == deposit.depositor, "Unauthorized"
    self.deposits[deposit_id] = Deposit({
        path: empty(DynArray[address, MAX_SIZE]),
        amount1: empty(uint256),
        depositor: empty(address)
    })
    assert deposit.amount1 > 0, "Empty deposit"
    last_index: uint256 = unsafe_sub(len(deposit.path), 1)
    path: DynArray[address, MAX_SIZE] = []
    for i in range(MAX_SIZE):
        path.append(deposit.path[unsafe_sub(last_index, i)])
        if i >= last_index:
            break
    if path[0] == VETH:
        path[0] = WETH
    if path[last_index] == VETH:
        path[last_index] = WETH
    self._safe_approve(path[0], ROUTER, deposit.amount1)
    _amount0: uint256 = 0
    if deposit.path[0] == VETH:
        _amount0 = deposit.depositor.balance
        UniswapV2Router(ROUTER).swapExactTokensForETHSupportingFeeOnTransferTokens(deposit.amount1, min_amount0, path, deposit.depositor, block.timestamp)
        _amount0 = deposit.depositor.balance - _amount0
    else:
        _amount0 = ERC20(path[last_index]).balanceOf(self)
        UniswapV2Router(ROUTER).swapExactTokensForTokensSupportingFeeOnTransferTokens(deposit.amount1, min_amount0, path, deposit.depositor, block.timestamp)
        _amount0 = ERC20(path[last_index]).balanceOf(self) - _amount0
    log Withdrawn(deposit_id, msg.sender, withdraw_type, _amount0)
    return _amount0

@external
def cancel(deposit_id: uint256, min_amount0: uint256) -> uint256:
    return self._withdraw(deposit_id, min_amount0, WithdrawType.CANCEL)

@external
def multiple_withdraw(deposit_ids: DynArray[uint256, MAX_SIZE], min_amounts0: DynArray[uint256, MAX_SIZE], withdraw_types: DynArray[WithdrawType, MAX_SIZE]):
    assert msg.sender == self.compass, "Unauthorized"
    _len: uint256 = len(deposit_ids)
    assert _len == len(min_amounts0) and _len == len(withdraw_types), "Validation error"
    _len = unsafe_add(unsafe_mul(unsafe_add(_len, 2), 96), 4)
    assert len(msg.data) == _len, "invalid payload"
    assert self.paloma == convert(slice(msg.data, unsafe_sub(_len, 32), 32), bytes32), "invalid paloma"
    for i in range(MAX_SIZE):
        if i >= len(deposit_ids):
            break
        self._withdraw(deposit_ids[i], min_amounts0[i], withdraw_types[i])

@external
def update_compass(new_compass: address):
    assert msg.sender == self.compass and len(msg.data) == 68 and convert(slice(msg.data, 36, 32), bytes32) == self.paloma, "Unauthorized"
    self.compass = new_compass
    log UpdateCompass(msg.sender, new_compass)

@external
def update_refund_wallet(new_refund_wallet: address):
    assert msg.sender == self.compass and len(msg.data) == 68 and convert(slice(msg.data, 36, 32), bytes32) == self.paloma, "Unauthorized"
    old_refund_wallet: address = self.refund_wallet
    self.refund_wallet = new_refund_wallet
    log UpdateRefundWallet(old_refund_wallet, new_refund_wallet)

@external
def update_fee(new_fee: uint256):
    assert msg.sender == self.compass and len(msg.data) == 68 and convert(slice(msg.data, 36, 32), bytes32) == self.paloma, "Unauthorized"
    old_fee: uint256 = self.fee
    self.fee = new_fee
    log UpdateFee(old_fee, new_fee)

@external
def set_paloma():
    assert msg.sender == self.compass and self.paloma == empty(bytes32) and len(msg.data) == 36, "Invalid"
    _paloma: bytes32 = convert(slice(msg.data, 4, 32), bytes32)
    self.paloma = _paloma
    log SetPaloma(_paloma)