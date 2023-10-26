
#pragma version 0.3.10
#pragma optimize gas
#pragma evm-version shanghai
"""
@title Curve Lending Bot Factory
@license Apache 2.0
@author Volume.finance
"""
struct FeeData:
    refund_wallet: address
    gas_fee: uint256
    service_fee_collector: address
    service_fee: uint256

interface Bot:
    def add_collateral(collateral: address, collateral_amount: uint256, lend_amount: uint256): nonpayable
    def repay(collateral: address, repay_amount: uint256): nonpayable
    def health(collateral: address) -> int256: view
    def state(collateral: address) -> uint256[4]: view
    def loan_exists(collateral: address) -> bool: view

interface ERC20:
    def balanceOf(_from: address) -> uint256: view

interface ControllerFactory:
    def WETH() -> address: view
    def stablecoin() -> address: view

MAX_SIZE: constant(uint256) = 8
DENOMINATOR: constant(uint256) = 10000
WETH: immutable(address)
crvUSD: immutable(address)
CONTROLLER_FACTORY: immutable(address)
ROUTER: immutable(address)
blueprint: public(address)
compass: public(address)
bot_to_owner: public(HashMap[address, address])
owner_to_bot: public(HashMap[address, address])
paloma: public(bytes32)
fee_data: public(FeeData)

event UpdateBlueprint:
    old_blueprint: address
    new_blueprint: address

event UpdateCompass:
    old_compass: address
    new_compass: address

event DeployCurveLendingBot:
    bot: address
    owner: address

# Bot <-> Pool
event AddCollateral:
    bot: address
    collateral: address
    collateral_amount: uint256

event RemoveCollateral:
    bot: address
    collateral: address
    collateral_amount: uint256

event Borrow:
    bot: address
    collateral: address
    amount: uint256

event Repay:
    bot: address
    collateral: address
    amount: uint256

# User <-> Bot
event DepositCollateral:
    bot: address
    collateral: address
    collateral_amount: uint256

event WithdrawCollateral:
    bot: address
    collateral: address
    collateral_amount: uint256

event OutputStablecoin:
    bot: address
    amount: uint256

event InputStablecoin:
    bot: address
    amount: uint256

event FeePaid:
    bot: address
    collateral: address
    amount: uint256

event GasPaid:
    bot: address
    amount: uint256

event BotStarted:
    bot: address
    collateral: address
    health_threshold: int256
    expire: uint256
    repayable: bool

event BotCanceled:
    bot: address
    collateral: address

event UpdateRefundWallet:
    old_refund_wallet: address
    new_refund_wallet: address

event SetPaloma:
    paloma: bytes32

event UpdateGasFee:
    old_gas_fee: uint256
    new_gas_fee: uint256

event UpdateServiceFeeCollector:
    old_service_fee_collector: address
    new_service_fee_collector: address

event UpdateServiceFee:
    old_service_fee: uint256
    new_service_fee: uint256

@external
def __init__(_blueprint: address, _compass: address, controller_factory: address, _refund_wallet: address, _gas_fee: uint256, _service_fee_collector: address, _service_fee: uint256, router: address):
    self.blueprint = _blueprint
    self.compass = _compass
    self.fee_data = FeeData({
        refund_wallet: _refund_wallet,
        gas_fee: _gas_fee,
        service_fee_collector: _service_fee_collector,
        service_fee: _service_fee
    })
    CONTROLLER_FACTORY = controller_factory
    WETH = ControllerFactory(controller_factory).WETH()
    ROUTER = router
    crvUSD = ControllerFactory(controller_factory).stablecoin()
    log UpdateCompass(empty(address), _compass)
    log UpdateBlueprint(empty(address), _blueprint)
    log UpdateRefundWallet(empty(address), _refund_wallet)
    log UpdateGasFee(empty(uint256), _gas_fee)
    log UpdateServiceFeeCollector(empty(address), _service_fee_collector)
    log UpdateServiceFee(empty(uint256), _service_fee)

@external
def deploy_curve_lending_bot():
    assert self.owner_to_bot[msg.sender] == empty(address), "Already user has bot"
    bot: address = create_from_blueprint(self.blueprint, CONTROLLER_FACTORY, WETH, crvUSD, msg.sender, ROUTER, code_offset=3)
    self.bot_to_owner[bot] = msg.sender
    self.owner_to_bot[msg.sender] = bot
    log DeployCurveLendingBot(bot, msg.sender)

@external
def create_loan_event(collateral: address, collateral_amount: uint256, lend_amount: uint256, debt: uint256, withdraw_amount: uint256, health_threshold: int256, expire: uint256, repayable: bool):
    assert self.bot_to_owner[msg.sender] != empty(address), "Not bot"
    log DepositCollateral(msg.sender, collateral, collateral_amount)
    log AddCollateral(msg.sender, collateral, lend_amount)
    log Borrow(msg.sender, collateral, debt)
    log OutputStablecoin(msg.sender, withdraw_amount)
    log BotStarted(msg.sender, collateral, health_threshold, expire, repayable)

@external
def cancel_event(collateral: address, collateral_amount: uint256, withdraw_amount: uint256, input_amount: uint256, repay_amount: uint256):
    assert self.bot_to_owner[msg.sender] != empty(address), "Not bot"
    log InputStablecoin(msg.sender, input_amount)
    log Repay(msg.sender, collateral, repay_amount)
    log RemoveCollateral(msg.sender, collateral, collateral_amount)
    log WithdrawCollateral(msg.sender, collateral, withdraw_amount)
    log BotCanceled(msg.sender, collateral)

@external
@nonreentrant('lock')
def add_collateral(bots: DynArray[address, MAX_SIZE], collateral: DynArray[address, MAX_SIZE], lend_amount: DynArray[uint256, MAX_SIZE]):
    assert msg.sender == self.compass, "Not compass"
    _len: uint256 = len(bots)
    assert _len == len(collateral) and _len == len(lend_amount), "Validation error"
    payload_len: uint256 = unsafe_add(unsafe_mul(unsafe_add(_len, 2), 96), 36)
    assert len(msg.data) == payload_len, "Invalid payload"
    assert self.paloma == convert(slice(msg.data, unsafe_sub(payload_len, 32), 32), bytes32), "Invalid paloma"
    for i in range(MAX_SIZE):
        if i >= _len:
            break
        assert self.bot_to_owner[bots[i]] != empty(address), "Bot not exist"
        Bot(bots[i]).add_collateral(collateral[i], 0, lend_amount[i])
        log AddCollateral(bots[i], collateral[i], lend_amount[i])
        log GasPaid(bots[i], self.fee_data.gas_fee)

@external
def add_collateral_event(collateral: address, collateral_amount: uint256, lend_amount: uint256):
    assert self.bot_to_owner[msg.sender] != empty(address), "Not bot"
    log DepositCollateral(msg.sender, collateral, collateral_amount)
    log AddCollateral(msg.sender, collateral, lend_amount)

@external
def borrow_more_event(collateral: address, lend_amount: uint256, withdraw_amount: uint256):
    assert self.bot_to_owner[msg.sender] != empty(address), "Not bot"
    log AddCollateral(msg.sender, collateral, lend_amount)
    log Borrow(msg.sender, collateral, withdraw_amount)

@external
@nonreentrant('lock')
def repay(bots: DynArray[address, MAX_SIZE], collateral: DynArray[address, MAX_SIZE], repay_amount: DynArray[uint256, MAX_SIZE]):
    assert msg.sender == self.compass, "Not compass"
    _len: uint256 = len(bots)
    assert _len == len(collateral) and _len == len(repay_amount), "Validation error"
    payload_len: uint256 = unsafe_add(unsafe_mul(unsafe_add(_len, 2), 96), 36)
    assert len(msg.data) == payload_len, "Invalid payload"
    assert self.paloma == convert(slice(msg.data, unsafe_sub(payload_len, 32), 32), bytes32), "Invalid paloma"
    for i in range(MAX_SIZE):
        if i >= _len:
            break
        assert self.bot_to_owner[bots[i]] != empty(address), "Bot not exist"
        Bot(bots[i]).repay(collateral[i], repay_amount[i])
        log Repay(bots[i], collateral[i], repay_amount[i])
        log GasPaid(bots[i], self.fee_data.gas_fee)

@external
def repay_event(collateral: address, input_amount: uint256, repay_amount: uint256):
    assert self.bot_to_owner[msg.sender] != empty(address), "Not bot"
    log InputStablecoin(msg.sender, input_amount)
    log Repay(msg.sender, collateral, repay_amount)

@external
def remove_collateral_event(collateral: address, collateral_amount: uint256, withdraw_amount: uint256):
    assert self.bot_to_owner[msg.sender] != empty(address), "Not bot"
    log RemoveCollateral(msg.sender, collateral, collateral_amount)
    log WithdrawCollateral(msg.sender, collateral, withdraw_amount)

@external
def withdraw_event(collateral: address, withdraw_amount: uint256):
    assert self.bot_to_owner[msg.sender] != empty(address), "Not bot"
    if collateral == crvUSD:
        log OutputStablecoin(msg.sender, withdraw_amount)
    else:
        log WithdrawCollateral(msg.sender, collateral, withdraw_amount)

@external
def bot_start_event(collateral: address, health_threshold: int256, expire: uint256, repayable: bool):
    assert self.bot_to_owner[msg.sender] != empty(address), "Not bot"
    log BotStarted(msg.sender, collateral, health_threshold, expire, repayable)

@external
@view
def health(collateral: address, bot: address) -> int256:
    return Bot(bot).health(collateral)

@external
@view
def loan_exists(collateral: address, bot: address) -> bool:
    return Bot(bot).loan_exists(collateral)

@external
@view
def collateral_reserves(collateral: address, bot: address) -> uint256:
    if collateral == WETH:
        return bot.balance
    else:
        return ERC20(collateral).balanceOf(bot)

@external
@view
def state(collateral: address, bot: address) -> uint256[4]:
    return Bot(bot).state(collateral)

@external
def update_compass(new_compass: address):
    assert msg.sender == self.compass and len(msg.data) == 68 and convert(slice(msg.data, 36, 32), bytes32) == self.paloma, "Unauthorized"
    self.compass = new_compass
    log UpdateCompass(msg.sender, new_compass)

@external
def update_blueprint(new_blueprint: address):
    assert msg.sender == self.compass and len(msg.data) == 68 and convert(slice(msg.data, 36, 32), bytes32) == self.paloma, "Unauthorized"
    old_blueprint:address = self.blueprint
    self.blueprint = new_blueprint
    log UpdateCompass(old_blueprint, new_blueprint)

@external
def set_paloma():
    assert msg.sender == self.compass and self.paloma == empty(bytes32) and len(msg.data) == 36, "Invalid"
    _paloma: bytes32 = convert(slice(msg.data, 4, 32), bytes32)
    self.paloma = _paloma
    log SetPaloma(_paloma)

@external
def update_refund_wallet(new_refund_wallet: address):
    assert msg.sender == self.compass and len(msg.data) == 68 and convert(slice(msg.data, 36, 32), bytes32) == self.paloma, "Unauthorized"
    old_refund_wallet: address = self.fee_data.refund_wallet
    self.fee_data.refund_wallet = new_refund_wallet
    log UpdateRefundWallet(old_refund_wallet, new_refund_wallet)

@external
def update_gas_fee(new_gas_fee: uint256):
    assert msg.sender == self.compass and len(msg.data) == 68 and convert(slice(msg.data, 36, 32), bytes32) == self.paloma, "Unauthorized"
    old_gas_fee: uint256 = self.fee_data.gas_fee
    self.fee_data.gas_fee = new_gas_fee
    log UpdateGasFee(old_gas_fee, new_gas_fee)

@external
def update_service_fee_collector(new_service_fee_collector: address):
    assert msg.sender == self.compass and len(msg.data) == 68 and convert(slice(msg.data, 36, 32), bytes32) == self.paloma, "Unauthorized"
    old_service_fee_collector: address = self.fee_data.service_fee_collector
    self.fee_data.service_fee_collector = new_service_fee_collector
    log UpdateServiceFeeCollector(old_service_fee_collector, new_service_fee_collector)

@external
def update_service_fee(new_service_fee: uint256):
    assert msg.sender == self.compass and len(msg.data) == 68 and convert(slice(msg.data, 36, 32), bytes32) == self.paloma, "Unauthorized"
    old_service_fee: uint256 = self.fee_data.service_fee
    self.fee_data.service_fee = new_service_fee
    log UpdateServiceFee(old_service_fee, new_service_fee)