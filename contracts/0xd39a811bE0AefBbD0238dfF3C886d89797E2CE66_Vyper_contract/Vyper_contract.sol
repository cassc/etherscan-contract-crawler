# @version ^0.3.7

from vyper.interfaces import ERC20

CURRENCY: immutable(ERC20)
API_VERSION: immutable(String[8])
MAX_DISCOUNTS: constant(int8) = 10

struct Plan:
    name: String[255]
    price: uint256
    rate_limit_per_day: uint256
    rate_limit_per_minute: uint256
    time_interval: uint256
    is_active: bool

struct Discount:
    duration: uint256
    discount: uint256

is_active: bool
owner: address
num_plans: uint8
plans: HashMap[uint8, Plan]
max_duration: uint256
subscriptions: HashMap[uint8, HashMap[address, uint256]]
discounts: Discount[MAX_DISCOUNTS]
discount_scale: constant(uint256) = 10000
count: int8

event NewSubscriber:
    plan_id: uint8
    subscriber: address
    duration: uint256

event PlanCreated:
    plan_id: uint8
    name: String[255]
    price: uint256
    rate_limit_per_day: uint256
    rate_limit_per_minute: uint256
    time_interval: uint256

event PlanActivated:
    plan_id: uint8
    
event PlanRetired:
    plan_id: uint8

event SubscriberRetired:
    pass

@external
def __init__(currency: address, max_duration: uint256):
    self.owner = msg.sender
    self.max_duration = max_duration
    self.is_active = True
    CURRENCY = ERC20(currency)
    API_VERSION = "0.0.1"

##################
# View functions #
##################

@view
@external
def get_plan(plan_id: uint8) -> Plan:
    return self.plans[plan_id]

@view
@external
def plan_count() -> uint8:
    return self.num_plans

@view
@external
def subscription_end(plan_id: uint8, subscriber: address) -> uint256:
    return self.subscriptions[plan_id][subscriber]

########################
# Subscriber functions #
########################

@external
def subscribe(plan_id: uint8, amount: uint256) -> uint256:
    return self._subscribe(plan_id, amount, msg.sender)

@external
def subscribe_for(plan_id: uint8, amount: uint256, wallet: address) -> uint256:
    return self._subscribe(plan_id, amount, wallet)

######################
# Internal functions #
######################

@internal
def _check_owner_and_active():
    assert msg.sender == self.owner, "Only contract owner can call this function."
    assert self.is_active, "Subscription contract has been retired"

@internal
def _subscribe(plan_id: uint8, amount: uint256, subscriber: address) -> uint256:
    assert self.is_active, "Subscription contract has been retired"
    plan: Plan = self.plans[plan_id]
    assert plan.is_active, "Plan does not exist or has been retired."
    CURRENCY.transferFrom(subscriber, self, amount)
    duration: uint256 = amount / plan.price
    assert duration <= self.max_duration, "Subscription length exceeds maximum."

    for i in range(MAX_DISCOUNTS):
        if i >= self.count:
            break
        d: Discount = self.discounts[i]
        if duration > d.duration:
            duration *= d.discount / discount_scale

    log NewSubscriber(plan_id, subscriber, duration)
    end_timestamp: uint256 = block.timestamp + duration
    self.subscriptions[plan_id][subscriber] = end_timestamp
    return end_timestamp

###################
# Owner functions #
###################

@external
def create_plan(name: String[255], price: uint256, rate_limit_per_day: uint256, rate_limit_per_minute: uint256, time_interval: uint256) -> Plan:
    '''
    'price' the price per second for your plan, denominated in CURRENCY.
    '''
    self._check_owner_and_active()
    assert len(name) <= 255, "Plan name is too long."
    plan: Plan = Plan({name: name, price: price, rate_limit_per_day: rate_limit_per_day, rate_limit_per_minute: rate_limit_per_minute, time_interval: time_interval, is_active: False})
    plan_id: uint8 = self.num_plans + 1
    self.plans[plan_id] = plan
    self.num_plans = plan_id
    log PlanCreated(plan_id, name, price, rate_limit_per_day, rate_limit_per_minute, time_interval)
    return plan

@external
def create_discount(duration: uint256, discount: uint256) -> Discount:
    """Add your highest duration discount first or it will break things"""
    assert duration <= self.max_duration, "duration must be <= max_duration."
    assert discount <= discount_scale, "discount must be less than 100%."
    assert self.count < 10, "You cannot create any more discounts."
    
    index: int8 = self.count
    for i in range(MAX_DISCOUNTS):
        if i >= index:
            break
        if self.discounts[i].duration < duration:
            index = i
            break
    
    for i in range(MAX_DISCOUNTS):
        if i < index:
            continue
        if i > self.count:
            break
        self.discounts[i] = self.discounts[i - convert(1, int8)]
    
    new_discount: Discount = Discount({duration: duration, discount: discount_scale - discount})
    self.discounts[index] = new_discount
    self.count += 1
    return new_discount

@external
def activate_plan(plan_id: uint8):
    self._check_owner_and_active()
    plan: Plan = self.plans[plan_id]
    assert plan.price > 0, "Plan does not exist."
    assert not plan.is_active, "Plan is already active."
    self.plans[plan_id].is_active = True
    log PlanActivated(plan_id)

@external
def set_max_duration(max_duration: uint256):
    self._check_owner_and_active()
    self.max_duration = max_duration

@external
def retire_plan(plan_id: uint8):
    """
    'plan_id': the plan id of the Plan you wish to retire.
    """
    self._check_owner_and_active()
    plan: Plan = self.plans[plan_id]
    assert plan.is_active, "Plan is not active."
    plan.is_active = False
    log PlanRetired(plan_id)

@external
def retire_contract():
    self._check_owner_and_active()
    self.is_active = False
    log SubscriberRetired()