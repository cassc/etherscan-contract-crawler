# @version 0.3.7

interface Bot:
    def vote(_gauge_addr: DynArray[address, MAX_SIZE], _user_weight: DynArray[uint256, MAX_SIZE]): nonpayable

MAX_SIZE: constant(uint256) = 8

blueprint: public(address)
compass: public(address)
bot_to_owner: public(HashMap[address, address])
owner_to_bot: public(HashMap[address, address])
paloma: public(bytes32)

event UpdateBlueprint:
    old_blueprint: address
    new_blueprint: address

event UpdateCompass:
    old_compass: address
    new_compass: address

event DeployVoteDistributionBot:
    bot: address
    router: address
    owner: address

event Deposited:
    owner: address
    token0: address
    amount0: uint256
    amount1: uint256
    unlock_time: uint256

event Claimed:
    owner: address
    out_token: address
    out_amount: uint256

event Withdrawn:
    owner: address
    sdt_amount: uint256
    out_token: address
    out_amount: uint256

event Voted:
    owner: address
    bot: address
    gauge_addr: DynArray[address, MAX_SIZE]
    user_weight: DynArray[uint256, MAX_SIZE]

event SetPaloma:
    paloma: bytes32

@external
def __init__(_blueprint: address, _compass: address):
    self.blueprint = _blueprint
    self.compass = _compass
    log UpdateCompass(empty(address), _compass)
    log UpdateBlueprint(empty(address), _blueprint)

@external
def deploy_vote_distribution_bot(router: address):
    assert self.owner_to_bot[msg.sender] == empty(address), "Already user has bot"
    bot: address = create_from_blueprint(self.blueprint, self.compass, router, msg.sender, code_offset=3)
    self.bot_to_owner[bot] = msg.sender
    self.owner_to_bot[msg.sender] = bot
    log DeployVoteDistributionBot(bot, router, msg.sender)

@external
def vote(bots: DynArray[address, MAX_SIZE], _gauge_addr: DynArray[address, MAX_SIZE], _user_weight: DynArray[uint256, MAX_SIZE]):
    assert msg.sender == self.compass, "Not compass"
    _len: uint256 = len(_gauge_addr)
    assert _len == len(_user_weight), "Validation error"
    _len = unsafe_add(unsafe_add(unsafe_mul(unsafe_add(len(bots), 2), 32), unsafe_mul(unsafe_add(_len, 2), 64)), 36)
    assert len(msg.data) == _len, "Invalid payload"
    assert self.paloma == convert(slice(msg.data, unsafe_sub(_len, 32), 32), bytes32), "Invalid paloma"
    for i in range(MAX_SIZE):
        if i >= len(bots):
            break
        Bot(bots[i]).vote(_gauge_addr, _user_weight)
        log Voted(self.bot_to_owner[bots[i]], bots[i], _gauge_addr, _user_weight)

@external
def deposited(token0: address, amount0: uint256, amount1: uint256, unlock_time: uint256):
    owner: address = self.bot_to_owner[msg.sender]
    assert owner != empty(address)
    log Deposited(owner, token0, amount0, amount1, unlock_time)

@external
def claimed(out_token: address, amount0: uint256):
    owner: address = self.bot_to_owner[msg.sender]
    assert owner != empty(address)
    log Claimed(owner, out_token, amount0)

@external
def withdrawn(sdt_amount: uint256, out_token: address, amount0: uint256):
    owner: address = self.bot_to_owner[msg.sender]
    assert owner != empty(address)
    log Withdrawn(owner, sdt_amount, out_token, amount0)

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