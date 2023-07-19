# @version 0.3.7
"""
@title yETH bootstrap
@author 0xkorin, Yearn Finance
@license Copyright (c) Yearn Finance, 2023 - all rights reserved
@notice 
    Implements the bootstrap phase as outlined in YIP-72, summarized:
    Contract defines multiple periods
        - Whitelist period: LSD protocols apply to be whitelisted by depositing 1 ETH
        - Deposit period: anyone can deposit ETH, which mints st-yETH 1:1 locked into the contract
        - Incentive period: anyone is able to incentivize voting for a whitelisted protocol by depositing tokens
        - Vote period: depositors are able to vote on their preferred whitelisted protocol
    After the vote period up to 5 protocols are declared as winner.
    Incentives for winning protocols will be distributed over all voters according to their overall vote weight, 
    regardless whether they voted for that specific protocol or not.
    Protocols that do not win will have their incentives refunded.
    10% of deposited ETH is sent to the POL.
    90% of deposited ETH is used to buy LSDs and deposit into the newly deployed yETH pool.
    The minted yETH is used to pay off 90% of the debt in the bootstrap contract.
    Depositor's st-yETH become withdrawable after a specific time.
"""

from vyper.interfaces import ERC20

interface Token:
    def mint(_account: address, _amount: uint256): nonpayable
    def burn(_account: address, _amount: uint256): nonpayable

interface Staking:
    def deposit(_assets: uint256) -> uint256: nonpayable

token: public(immutable(address))
staking: public(immutable(address))
treasury: public(immutable(address))
pol: public(immutable(address))
management: public(address)
pending_management: public(address)
repay_allowed: public(HashMap[address, bool])

applications: HashMap[address, uint256]
debt: public(uint256)
deposited: public(uint256)
deposits: public(HashMap[address, uint256]) # user => amount deposited
incentives: public(HashMap[address, HashMap[address, uint256]]) # protocol => incentive => amount
incentive_depositors: public(HashMap[address, HashMap[address, HashMap[address, uint256]]]) # protocol => incentive => depositor => amount
voted: public(uint256)
votes_used: public(HashMap[address, uint256]) # user => votes used
votes_used_protocol: public(HashMap[address, HashMap[address, uint256]]) # user => protocol => votes
votes: public(HashMap[address, uint256]) # protocol => votes
winners_list: public(DynArray[address, MAX_WINNERS])
winners: public(HashMap[address, bool]) # protocol => winner?
incentive_claimed: public(HashMap[address, HashMap[address, HashMap[address, bool]]]) # winner => incentive => user => claimed?

whitelist_begin: public(uint256)
whitelist_end: public(uint256)
incentive_begin: public(uint256)
incentive_end: public(uint256)
deposit_begin: public(uint256)
deposit_end: public(uint256)
vote_begin: public(uint256)
vote_end: public(uint256)
lock_end: public(uint256)

event Apply:
    protocol: indexed(address)

event Whitelist:
    protocol: indexed(address)

event Incentivize:
    protocol: indexed(address)
    incentive: indexed(address)
    depositor: indexed(address)
    amount: uint256

event Deposit:
    depositor: indexed(address)
    receiver: indexed(address)
    amount: uint256

event Claim:
    claimer: indexed(address)
    receiver: indexed(address)
    amount: uint256

event Vote:
    voter: indexed(address)
    protocol: indexed(address)
    amount: uint256

event Repay:
    payer: indexed(address)
    amount: uint256

event Split:
    amount: uint256

event ClaimIncentive:
    protocol: indexed(address)
    incentive: indexed(address)
    claimer: indexed(address)
    amount: uint256

event RefundIncentive:
    protocol: indexed(address)
    incentive: indexed(address)
    depositor: indexed(address)
    amount: uint256

event SetPeriod:
    period: indexed(uint256)
    begin: uint256
    end: uint256

event Winners:
    winners: DynArray[address, MAX_WINNERS]

event PendingManagement:
    management: indexed(address)

event SetManagement:
    management: indexed(address)

NOTHING: constant(uint256) = 0
APPLIED: constant(uint256) = 1
WHITELISTED: constant(uint256) = 2
MAX_WINNERS: constant(uint256) = 5

@external
def __init__(_token: address, _staking: address, _treasury: address, _pol: address):
    """
    @notice Constructor
    @param _token yETH token address
    @param _staking st-yETH token address
    @param _treasury Treasury address
    @param _pol POL address
    """
    token = _token
    staking = _staking
    treasury = _treasury
    pol = _pol
    self.management = msg.sender
    assert ERC20(token).approve(_staking, max_value(uint256), default_return_value=True)

@external
@payable
def __default__():
    """
    @notice Send ETH in exchange for 1:1 locked st-yETH
    """
    self._deposit(msg.sender)

@external
@payable
def apply(_protocol: address):
    """
    @notice
        As a LSD protocol apply to be whitelisted for potential inclusion into the yETH pool.
        Requires an application fee of 1 ETH to be sent along with the call
    @param _protocol The LSD protocol token address
    """
    assert msg.value == 1_000_000_000_000_000_000 # dev: application fee
    assert block.timestamp >= self.whitelist_begin and block.timestamp < self.whitelist_end # dev: outside application period
    assert self.applications[_protocol] == NOTHING # dev: already applied
    self.applications[_protocol] = APPLIED
    log Apply(_protocol)

@external
def incentivize(_protocol: address, _incentive: address, _amount: uint256):
    """
    @notice
        Incentivize depositors to vote on a specific protocol.
        Deposited incentives are refunded if the protocol does not receive sufficient votes to be included in the yETH pool
    @param _protocol The LSD protocol address
    @param _incentive The incentive token address
    @param _amount The amount of tokens to deposit as incentive
    """
    assert _amount > 0
    assert block.timestamp >= self.incentive_begin and block.timestamp < self.incentive_end # dev: outside incentive period
    assert self.applications[_protocol] == WHITELISTED # dev: not whitelisted
    self.incentives[_protocol][_incentive] += _amount
    self.incentive_depositors[_protocol][_incentive][msg.sender] += _amount
    assert ERC20(_incentive).transferFrom(msg.sender, self, _amount, default_return_value=True)
    log Incentivize(_protocol, _incentive, msg.sender, _amount)

@external
@payable
def deposit(_account: address = msg.sender):
    """
    @notice Deposit ETH in exchange for 1:1 locked st-yETH
    @param _account Deposit on behalf of this account
    """
    self._deposit(_account)

@internal
@payable
def _deposit(_account: address):
    """
    @notice Deposit ETH in exchange for 1:1 locked st-yETH
    @param _account Deposit on behalf of this account
    """
    assert msg.value > 0
    assert block.timestamp >= self.deposit_begin and block.timestamp < self.deposit_end # dev: outside deposit period
    assert self.lock_end > 0
    self.debt += msg.value
    self.deposited += msg.value
    self.deposits[_account] += msg.value
    Token(token).mint(self, msg.value)
    Staking(staking).deposit(msg.value)
    log Deposit(msg.sender, _account, msg.value)

@external
def claim(_amount: uint256, _receiver: address = msg.sender):
    """
    @notice Claim st-yETH once the lock has expired
    @param _amount Amount of tokens to claim
    @param _receiver Account to transfer the tokens to
    """
    assert _amount > 0
    assert block.timestamp >= self.lock_end
    self.deposited -= _amount
    self.deposits[msg.sender] -= _amount
    assert ERC20(staking).transfer(_receiver, _amount, default_return_value=True)
    log Claim(msg.sender, _receiver, _amount)

@external
@view
def votes_available(_account: address) -> uint256:
    """
    @notice Get the amount of available votes for a specific account
    @param _account The account to query for
    @return Amount of available votes
    """
    if block.timestamp < self.vote_begin or block.timestamp >= self.vote_end:
        return 0

    return self.deposits[_account] - self.votes_used[_account]

@external
def vote(_protocols: DynArray[address, 32], _votes: DynArray[uint256, 32]):
    """
    @notice Vote for whitelisted protocols to be included into the pool
    @param _protocols Protocols to vote for
    @param _votes Amount of votes to allocate for each protocol
    """
    assert len(_protocols) == len(_votes)
    assert block.timestamp >= self.vote_begin and block.timestamp < self.vote_end # dev: outside vote period
    used: uint256 = 0
    for i in range(32):
        if i == len(_protocols):
            break
        protocol: address = _protocols[i]
        votes: uint256 = _votes[i]
        assert self.applications[protocol] == WHITELISTED # dev: protocol not whitelisted
        used += votes
        self.votes[protocol] += votes
        self.votes_used_protocol[msg.sender][protocol] += votes
        log Vote(msg.sender, protocol, votes)
    self.voted += used
    used += self.votes_used[msg.sender]
    assert used <= self.deposits[msg.sender] # dev: too many votes
    self.votes_used[msg.sender] = used

@external
def undo_vote(_protocol: address, _account: address = msg.sender) -> uint256:
    """
    @notice Undo vote for a protocol that had their whitelist retracted
    @param _protocol Protocol to undo votes for
    @param _account Account to undo votes for
    @return Amount of freed up votes
    """
    assert block.timestamp >= self.vote_begin and block.timestamp < self.vote_end # dev: outside vote period
    assert self.applications[_protocol] != WHITELISTED
    assert _account == msg.sender or msg.sender == self.management
    votes: uint256 = self.votes_used_protocol[_account][_protocol]
    assert votes > 0
    self.voted -= votes
    self.votes[_protocol] -= votes
    self.votes_used[_account] -= votes
    self.votes_used_protocol[_account][_protocol] = 0
    return votes

@external
def repay(_amount: uint256):
    """
    @notice Repay yETH debt by burning it
    @param _amount Amount of debt to repay
    @dev Requires prior permission by management
    """
    assert self.repay_allowed[msg.sender]
    self.debt -= _amount
    assert ERC20(token).transferFrom(msg.sender, self, _amount, default_return_value=True)
    Token(token).burn(self, _amount)
    log Repay(msg.sender, _amount)

@external
def split():
    """
    @notice Split deposited ETH 9:1 between treasury and POL
    """
    assert msg.sender == self.management or msg.sender == treasury
    amount: uint256 = self.balance
    assert amount > 0
    log Split(amount)
    raw_call(pol, b"", value=amount/10)
    amount -= amount/10
    raw_call(treasury, b"", value=amount)

@external
@view
def claimable_incentive(_protocol: address, _incentive: address, _claimer: address) -> uint256:
    """
    @notice Get the amount of claimable incentives
    @param _protocol Address of the LSD protocol to claim incentives for
    @param _incentive Incentive token to claim
    @param _claimer Account to query for
    @return Amount of claimable incentive tokens
    """
    if not self.winners[_protocol] or self.incentive_claimed[_protocol][_incentive][_claimer]:
        return 0
    return self.incentives[_protocol][_incentive] * self.votes_used[_claimer] / self.voted

@external
def claim_incentive(_protocol: address, _incentive: address, _claimer: address = msg.sender) -> uint256:
    """
    @notice Claim a specific incentive
    @param _protocol Address of the LSD protocol to claim incentives for
    @param _incentive Incentive token to claim
    @param _claimer Account to claim for
    @return Amount of incentive tokens claimed
    """
    assert self.winners[_protocol] # dev: protocol is not winner
    assert not self.incentive_claimed[_protocol][_incentive][_claimer] # dev: incentive already claimed
    
    incentive: uint256 = self.incentives[_protocol][_incentive] * self.votes_used[_claimer] / self.voted
    assert incentive > 0 # dev: nothing to claim

    self.incentive_claimed[_protocol][_incentive][_claimer] = True
    assert ERC20(_incentive).transfer(_claimer, incentive, default_return_value=True)
    log ClaimIncentive(_protocol, _incentive, _claimer, incentive)
    return incentive

@external
def refund_incentive(_protocol: address, _incentive: address, _depositor: address = msg.sender) -> uint256:
    """
    @notice Refund incentive for protocols that did not win
    @param _protocol Address of the LSD protocol to refund incentives for
    @param _incentive Incentive token to refund
    @param _depositor Account that deposited the incentive
    @return Amount of incentive tokens refunded
    """
    assert len(self.winners_list) > 0 # dev: no winners declared
    assert not self.winners[_protocol] # dev: protocol is winner

    amount: uint256 = self.incentive_depositors[_protocol][_incentive][_depositor]
    assert amount > 0 # dev: nothing to refund

    self.incentive_depositors[_protocol][_incentive][_depositor] = 0
    assert ERC20(_incentive).transfer(_depositor, amount, default_return_value=True)
    log RefundIncentive(_protocol, _incentive, _depositor, amount)
    return amount

@external
@view
def has_applied(_protocol: address) -> bool:
    """
    @notice Check whether the LSD protocol has applied to be whitelisted
    @param _protocol Address of the LSD protocol to query for
    @return True if the protocol has applied, False if it has not yet applied
    """
    return self.applications[_protocol] > NOTHING

@external
@view
def is_whitelisted(_protocol: address) -> bool:
    """
    @notice Check whether the LSD protocol is whitelisted
    @param _protocol Address of the LSD protocol to query for
    @return True if the protocol is whitelisted, False if it has not been whitelisted
    """
    return self.applications[_protocol] == WHITELISTED

@external
@view
def num_winners() -> uint256:
    """
    @notice Get the number of declared winners
    @return Number of declared winners
    """
    return len(self.winners_list)

# MANAGEMENT FUNCTIONS

@external
def set_whitelist_period(_begin: uint256, _end: uint256):
    """
    @notice Set the period during which protocols can apply to be whitelisted
    @param _begin Timestamp of the beginning of the period
    @param _end Timestamp of the end of the period
    """
    assert msg.sender == self.management
    assert _end > _begin
    self.whitelist_begin = _begin
    self.whitelist_end = _end
    log SetPeriod(0, _begin,  _end)

@external
def set_incentive_period(_begin: uint256, _end: uint256):
    """
    @notice Set the period during which incentives can be deposited
    @dev Not allowed to start before the whitelist period
    @param _begin Timestamp of the beginning of the period
    @param _end Timestamp of the end of the period
    """
    assert msg.sender == self.management
    assert _begin >= self.whitelist_begin
    assert _end > _begin
    self.incentive_begin = _begin
    self.incentive_end = _end
    log SetPeriod(1, _begin,  _end)

@external
def set_deposit_period(_begin: uint256, _end: uint256):
    """
    @notice Set the period during which users can deposit ETH for st-yETH
    @dev Not allowed to start before the whitelist period
    @param _begin Timestamp of the beginning of the period
    @param _end Timestamp of the end of the period
    """
    assert msg.sender == self.management
    assert _begin >= self.whitelist_begin
    assert _end > _begin
    self.deposit_begin = _begin
    self.deposit_end = _end
    log SetPeriod(2, _begin,  _end)

@external
def set_vote_period(_begin: uint256, _end: uint256):
    """
    @notice Set the period during which depositors can vote for protocols
    @dev Not allowed to start before the deposit period
    @param _begin Timestamp of the beginning of the period
    @param _end Timestamp of the end of the period
    """
    assert msg.sender == self.management
    assert _begin >= self.deposit_begin
    assert _end > _begin
    assert _end <= self.lock_end
    self.vote_begin = _begin
    self.vote_end = _end
    log SetPeriod(3, _begin, _end)

@external
def set_lock_end(_end: uint256):
    """
    @notice Set the time the st-yETH lock ends
    @dev Not allowed to be before the end of the vote period
    @param _end Timestamp of the end of the lock
    """
    assert msg.sender == self.management
    assert _end >= self.vote_end
    self.lock_end = _end
    log SetPeriod(4, 0, _end)

@external
def whitelist(_protocol: address):
    """
    @notice Whitelist a protocol 
    @param _protocol Address of the LSD protocol
    """
    assert msg.sender == self.management
    assert self.applications[_protocol] == APPLIED # dev: has not applied
    self.applications[_protocol] = WHITELISTED
    log Whitelist(_protocol)

@external
def undo_whitelist(_protocol: address):
    """
    @notice Undo a protocol whitelist. Should only be used in emergencies
    @param _protocol Address of the LSD protocol
    """
    assert msg.sender == self.management
    assert self.applications[_protocol] == WHITELISTED # dev: not whitelisted
    self.applications[_protocol] = APPLIED

@external
def declare_winners(_winners: DynArray[address, MAX_WINNERS]):
    """
    @notice Declare the winners of the vote
    @param _winners Addresses of the LSD protocols
    """
    assert msg.sender == self.management
    assert block.timestamp >= self.incentive_end
    assert block.timestamp >= self.deposit_end
    assert block.timestamp >= self.vote_end
    assert len(self.winners_list) == 0
    for winner in _winners:
        assert self.applications[winner] == WHITELISTED
        assert not self.winners[winner]
        self.winners_list.append(winner)
        self.winners[winner] = True
    log Winners(_winners)

@external
def allow_repay(_account: address, _allow: bool):
    """
    @notice Allow specific account to repay debt
    @param _account Account to set permission for
    @param _allow Flag whether to allow repayment or not
    """
    assert msg.sender == self.management
    self.repay_allowed[_account] = _allow

@external
def set_management(_management: address):
    """
    @notice 
        Set the pending management address.
        Needs to be accepted by that account separately to transfer management over
    @param _management New pending management address
    """
    assert msg.sender == self.management
    self.pending_management = _management
    log PendingManagement(_management)

@external
def accept_management():
    """
    @notice 
        Accept management role.
        Can only be called by account previously marked as pending management by current management
    """
    assert msg.sender == self.pending_management
    self.pending_management = empty(address)
    self.management = msg.sender
    log SetManagement(msg.sender)