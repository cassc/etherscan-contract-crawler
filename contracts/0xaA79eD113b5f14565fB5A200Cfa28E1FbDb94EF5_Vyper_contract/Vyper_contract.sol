# @version 0.3.9

struct Deposit:
    depositor: address
    path: DynArray[address, MAX_SIZE]
    input_amount: uint256
    number_trades: uint256
    interval: uint256
    remaining_counts: uint256
    starting_time: uint256

interface WrappedEth:
    def deposit(): payable

interface UniswapV2Router:
    def WETH() -> address: pure
    def swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn: uint256, amountOutMin: uint256, path: DynArray[address, MAX_SIZE], to: address, deadline: uint256): nonpayable
    def swapExactTokensForETHSupportingFeeOnTransferTokens(amountIn: uint256, amountOutMin: uint256, path: DynArray[address, MAX_SIZE], to: address, deadline: uint256): nonpayable
    def getAmountsOut(amountIn: uint256, path: DynArray[address, 8]) -> DynArray[uint256, 7]: view

interface ERC20:
    def balanceOf(_owner: address) -> uint256: view

WETH: immutable(address)
VETH: constant(address) = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE # Virtual ETH
ROUTER: immutable(address)
MAX_SIZE: constant(uint256) = 8
compass_evm: public(address)
admin: public(address)
deposit_list: HashMap[uint256, Deposit]
next_deposit: public(uint256)
refund_wallet: public(address)
fee: public(uint256)
paloma: public(bytes32)

event Deposited:
    swap_id: uint256
    token0: address
    token1: address
    input_amount: uint256
    number_trades: uint256
    interval: uint256
    starting_time: uint256
    depositor: address

event Swapped:
    swap_id: uint256
    remaining_counts: uint256
    amount: uint256
    out_amount: uint256

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

@external
def __init__(_compass_evm: address, router: address, _refund_wallet: address, _fee: uint256):
    self.compass_evm = _compass_evm
    ROUTER = router
    WETH = UniswapV2Router(ROUTER).WETH()
    self.refund_wallet = _refund_wallet
    self.fee = _fee
    log UpdateCompass(empty(address), _compass_evm)
    log UpdateRefundWallet(empty(address), _refund_wallet)
    log UpdateFee(0, _fee)

@internal
def _safe_transfer_from(_token: address, _from: address, _to: address, _value: uint256):
    _response: Bytes[32] = raw_call(
        _token,
        _abi_encode(_from, _to, _value, method_id=method_id("transferFrom(address,address,uint256)")),
        max_outsize=32
    )  # dev: failed transferFrom
    if len(_response) > 0:
        assert convert(_response, bool), "failed transferFrom"  # dev: failed transferFrom

@external
@payable
@nonreentrant('lock')
def deposit(path: DynArray[address, 8], input_amount: uint256, number_trades: uint256, interval: uint256, starting_time: uint256):
    _value: uint256 = msg.value
    _fee: uint256 = self.fee
    assert _value >= _fee, "Insufficient fee"
    send(self.refund_wallet, _fee)
    _value = unsafe_sub(_value, _fee)
    assert len(path) >= 2, "Wrong path"
    last_index: uint256 = unsafe_sub(len(path), 1)
    token1: address = path[last_index]
    _amount0: uint256 = input_amount
    if path[0] == VETH:
        assert _value >= input_amount, "Insufficient deposit"
        if _value > input_amount:
            send(msg.sender, unsafe_sub(_value, input_amount))
        WrappedEth(WETH).deposit(value=input_amount)
    else:
        send(msg.sender, _value)
        _amount0 = ERC20(path[0]).balanceOf(self)
        self._safe_transfer_from(path[0], msg.sender, self, input_amount)
        _amount0 = ERC20(path[0]).balanceOf(self) - _amount0
    _next_deposit: uint256 = self.next_deposit
    _starting_time: uint256 = starting_time
    if starting_time <= block.timestamp:
        _starting_time = block.timestamp
    self.deposit_list[_next_deposit] = Deposit({
        depositor: msg.sender,
        path: path,
        input_amount: _amount0,
        number_trades: number_trades,
        interval: interval,
        remaining_counts: number_trades,
        starting_time: _starting_time
    })
    log Deposited(_next_deposit, path[0], path[last_index], input_amount, number_trades, interval, _starting_time, msg.sender)
    _next_deposit += 1
    self.next_deposit = _next_deposit

@internal
def _safe_approve(_token: address, _to: address, _value: uint256):
    _response: Bytes[32] = raw_call(
        _token,
        _abi_encode(_to, _value, method_id=method_id("approve(address,uint256)")),
        max_outsize=32
    )  # dev: failed approve
    if len(_response) > 0:
        assert convert(_response, bool), "failed approve"  # dev: failed approve

@external
@nonreentrant('lock')
def swap(swap_id: uint256, amount_out_min: uint256) -> uint256:
    _deposit: Deposit = self.deposit_list[swap_id]
    if msg.sender == self.compass_evm:
        assert len(msg.data) == 100, "invalid payload"
        assert self.paloma == convert(slice(msg.data, 68, 32), bytes32), "invalid paloma"
    else:
        assert _deposit.depositor == msg.sender or msg.sender == empty(address), "unauthorized"
    assert _deposit.remaining_counts > 0, "all traded"
    assert _deposit.starting_time + _deposit.interval * (_deposit.number_trades - _deposit.remaining_counts) <= block.timestamp, "too early"
    _amount: uint256 = _deposit.input_amount / _deposit.remaining_counts
    _deposit.input_amount -= _amount
    _deposit.remaining_counts -= 1
    _path: DynArray[address, MAX_SIZE] = _deposit.path
    if _path[0] == VETH:
        _path[0] = WETH
    self._safe_approve(_deposit.path[0], ROUTER, _amount)
    last_index: uint256 = unsafe_sub(len(_path), 1)
    _out_amount: uint256 = 0
    if _path[last_index] == VETH:
        _path[last_index] = WETH
        _out_amount = _deposit.depositor.balance
        UniswapV2Router(ROUTER).swapExactTokensForETHSupportingFeeOnTransferTokens(_amount, amount_out_min, _deposit.path, _deposit.depositor, block.timestamp)
        _out_amount = _deposit.depositor.balance - _out_amount
    else:
        _out_amount = ERC20(_path[last_index]).balanceOf(_deposit.depositor)
        UniswapV2Router(ROUTER).swapExactTokensForTokensSupportingFeeOnTransferTokens(_amount, amount_out_min, _deposit.path, _deposit.depositor, block.timestamp)
        _out_amount = ERC20(_path[last_index]).balanceOf(_deposit.depositor) - _out_amount
    log Swapped(swap_id, _deposit.remaining_counts, _amount, _out_amount)
    return _out_amount

@external
def update_compass(new_compass: address):
    assert msg.sender == self.compass_evm and len(msg.data) == 68 and convert(slice(msg.data, 36, 32), bytes32) == self.paloma, "Unauthorized"
    self.compass_evm = new_compass
    log UpdateCompass(msg.sender, new_compass)

@external
def update_refund_wallet(new_refund_wallet: address):
    assert msg.sender == self.compass_evm and len(msg.data) == 68 and convert(slice(msg.data, 36, 32), bytes32) == self.paloma, "Unauthorized"
    old_refund_wallet: address = self.refund_wallet
    self.refund_wallet = new_refund_wallet
    log UpdateRefundWallet(old_refund_wallet, new_refund_wallet)

@external
def update_fee(new_fee: uint256):
    assert msg.sender == self.compass_evm and len(msg.data) == 68 and convert(slice(msg.data, 36, 32), bytes32) == self.paloma, "Unauthorized"
    old_fee: uint256 = self.fee
    self.fee = new_fee
    log UpdateFee(old_fee, new_fee)

@external
def set_paloma():
    assert msg.sender == self.compass_evm and self.paloma == empty(bytes32) and len(msg.data) == 36, "Invalid"
    _paloma: bytes32 = convert(slice(msg.data, 4, 32), bytes32)
    self.paloma = _paloma
    log SetPaloma(_paloma)