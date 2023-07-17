# @version 0.3.7


event NewPaymentAddress:
    account: address
    payment_address: address

event PaymentReceived:
    account: indexed(address)
    token: address
    amount: uint256

event NewOwnerCommitted:
    owner: address
    new_owner: address
    finalize_time: uint256

event NewOwnerAccepted:
    old_owner: address
    owner: address

event NewSweeperCommitted:
    sweeper: address
    new_sweeper: address
    finalize_time: uint256

event NewSweeperSet:
    old_sweeper: address
    sweeper: address

event NewReceiverCommitted:
    receiver: address
    new_receiver: address
    finalize_time: uint256

event NewReceiverSet:
    old_receiver: address
    receiver: address


ADMIN_ACTIONS_DELAY: constant(uint256) = 86400 * 3
PROXY_IMPLEMENTATION: public(immutable(address))

sweeper_implementation: public(address)
future_sweeper_implementation: public(address)

owner: public(address)
future_owner: public(address)

receiver: public(address)
future_receiver: public(address)

transfer_ownership_timestamp: public(uint256)
new_sweeper_timestamp: public(uint256)
new_receiver_timestamp: public(uint256)

is_approved_token: public(HashMap[address, bool])
approved_tokens: DynArray[address, 10]

account_to_payment_address: public(HashMap[address, address])
payment_address_to_account: public(HashMap[address, address])


@external
def __init__(_owner: address, _receiver: address, _sweeper: address, _proxy: address):
    self.owner = _owner
    self.receiver = _receiver
    self.sweeper_implementation = _sweeper
    PROXY_IMPLEMENTATION = _proxy


@view
@external
def get_approved_tokens() -> DynArray[address, 10]:
    return self.approved_tokens


@external
def payment_received(_token: address, _amount: uint256) -> bool:
    account: address = self.payment_address_to_account[msg.sender]
    assert account != empty(address), "Unknown caller"
    assert self.is_approved_token[_token], "Invalid payment token"

    log PaymentReceived(account, _token, _amount)
    return True


@external
def create_payment_address(_account: address = msg.sender):
    sweeper: address = create_copy_of(PROXY_IMPLEMENTATION, salt=convert(_account, bytes32))
    self.account_to_payment_address[_account] = sweeper
    self.payment_address_to_account[sweeper] = _account

    log NewPaymentAddress(_account, sweeper)


@external
def set_token_approvals(_tokens: DynArray[address, 10], _approved: bool):
    assert msg.sender == self.owner

    approved_tokens: DynArray[address, 10] = []
    if not _approved:
        approved_tokens = self.approved_tokens

    for token in _tokens:
        if self.is_approved_token[token] != _approved:
            self.is_approved_token[token] = _approved

            if _approved:
                self.approved_tokens.append(token)
            else:
                for i in range(10):
                    if approved_tokens[i] == token:
                        if i + 1 == len(approved_tokens):
                            approved_tokens.pop()
                        else:
                            approved_tokens[i] = approved_tokens.pop()
                        break

    if not _approved:
        self.approved_tokens = approved_tokens



@external
def commit_new_sweeper_implementation(_sweeper: address):
    assert msg.sender == self.owner

    finalize_time: uint256 = block.timestamp + ADMIN_ACTIONS_DELAY
    self.future_sweeper_implementation = _sweeper
    self.new_sweeper_timestamp = finalize_time
    log NewSweeperCommitted(self.sweeper_implementation, _sweeper, finalize_time)


@external
def finalize_new_sweeper_implementation():
    assert msg.sender == self.owner
    assert self.new_sweeper_timestamp < block.timestamp

    log NewSweeperSet(self.sweeper_implementation, self.future_sweeper_implementation)
    self.sweeper_implementation = self.future_sweeper_implementation


@external
def commit_new_receiver(_receiver: address):
    assert msg.sender == self.owner

    finalize_time: uint256 = block.timestamp + ADMIN_ACTIONS_DELAY
    self.future_receiver = _receiver
    self.new_receiver_timestamp = finalize_time

    log NewReceiverCommitted(self.receiver, _receiver, finalize_time)


@external
def finalize_new_receiver():
    assert msg.sender == self.owner
    assert self.new_receiver_timestamp < block.timestamp

    log NewReceiverSet(self.receiver, self.future_receiver)
    self.receiver = self.future_receiver


@external
def commit_transfer_ownership(_new_owner: address):
    """
    @notice Set a new contract owner
    """
    assert msg.sender == self.owner

    finalize_time: uint256 = block.timestamp + ADMIN_ACTIONS_DELAY
    self.future_owner = _new_owner
    self.transfer_ownership_timestamp = finalize_time
    log NewOwnerCommitted(msg.sender, _new_owner, finalize_time)


@external
def accept_transfer_ownership():
    """
    @notice Accept transfer of contract ownership
    """
    assert msg.sender == self.future_owner
    assert self.transfer_ownership_timestamp < block.timestamp

    log NewOwnerAccepted(self.owner, msg.sender)
    self.owner = msg.sender