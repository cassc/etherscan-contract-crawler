# @version 0.3.7
"""
@title Root Liquidity Gauge Factory
@license MIT
@author Curve Finance
"""


interface Bridger:
    def check(_addr: address) -> bool: view
    def cost() -> uint256: view

interface RootGauge:
    def bridger() -> address: view
    def initialize(_bridger: address, _chain_id: uint256, _relative_weight_cap: uint256): nonpayable
    def transmit_emissions(): payable


event BridgerUpdated:
    _chain_id: indexed(uint256)
    _old_bridger: address
    _new_bridger: address

event DeployedGauge:
    _implementation: indexed(address)
    _chain_id: indexed(uint256)
    _key: (address, int24, int24)
    _gauge: address

event TransferOwnership:
    _old_owner: address
    _new_owner: address

event UpdateImplementation:
    _old_implementation: address
    _new_implementation: address


get_bridger: public(HashMap[uint256, address])
get_implementation: public(address)

get_gauge: public(HashMap[uint256, address[max_value(uint256)]])
get_gauge_count: public(HashMap[uint256, uint256])
is_valid_gauge: public(HashMap[address, bool])

owner: public(address)
future_owner: public(address)


@external
def __init__(_owner: address, _implementation: address):
    self.owner = _owner
    log TransferOwnership(empty(address), _owner)

    self.get_implementation = _implementation
    log UpdateImplementation(empty(address), _implementation)


@payable
@external
def transmit_emissions(_gauge: address):
    """
    @notice Call `transmit_emissions` on a root gauge
    @dev Entrypoint to request emissions for a child gauge.
    """
    # in most cases this will return True
    # for special bridges *cough cough Multichain, we can only do
    # one bridge per tx, therefore this will verify msg.sender in [tx.origin, self.call_proxy]
    bridger: Bridger = Bridger(RootGauge(_gauge).bridger())
    assert bridger.check(msg.sender)
    cost: uint256 = bridger.cost()
    RootGauge(_gauge).transmit_emissions(value=cost)

    # refund leftover ETH
    if self.balance != 0:
        raw_call(msg.sender, b"", value=self.balance)


@payable
@external
def transmit_emissions_multiple(_gauge_list: DynArray[address, 64]):
    """
    @notice Call `transmit_emissions` on a list of root gauges
    @dev Entrypoint to request emissions for a child gauge.
    """
    for _gauge in _gauge_list:
        # in most cases this will return True
        # for special bridges *cough cough Multichain, we can only do
        # one bridge per tx, therefore this will verify msg.sender in [tx.origin, self.call_proxy]
        bridger: Bridger = Bridger(RootGauge(_gauge).bridger())
        assert bridger.check(msg.sender)
        cost: uint256 = bridger.cost()
        RootGauge(_gauge).transmit_emissions(value=cost)

    # refund leftover ETH
    if self.balance != 0:
        raw_call(msg.sender, b"", value=self.balance)


@payable
@external
def deploy_gauge(_chain_id: uint256, _key: (address, int24, int24), _relative_weight_cap: uint256) -> address:
    """
    @notice Deploy a root liquidity gauge
    @param _chain_id The chain identifier of the counterpart child gauge
    @param key The BunniKey of the gauge's LP token
    @param _relative_weight_cap The initial relative weight cap
    """
    bridger: address = self.get_bridger[_chain_id]
    assert bridger != empty(address)  # dev: chain id not supported

    implementation: address = self.get_implementation
    gauge: address = create_minimal_proxy_to(
        implementation,
        value=msg.value,
        salt=keccak256(_abi_encode(_chain_id, _key))
    )

    idx: uint256 = self.get_gauge_count[_chain_id]
    self.get_gauge[_chain_id][idx] = gauge
    self.get_gauge_count[_chain_id] = idx + 1
    self.is_valid_gauge[gauge] = True

    RootGauge(gauge).initialize(bridger, _chain_id, _relative_weight_cap)

    log DeployedGauge(implementation, _chain_id, _key, gauge)
    return gauge


@external
def set_bridger(_chain_id: uint256, _bridger: address):
    """
    @notice Set the bridger for `_chain_id`
    @param _chain_id The chain identifier to set the bridger for
    @param _bridger The bridger contract to use
    """
    assert msg.sender == self.owner  # dev: only owner

    log BridgerUpdated(_chain_id, self.get_bridger[_chain_id], _bridger)
    self.get_bridger[_chain_id] = _bridger


@external
def set_implementation(_implementation: address):
    """
    @notice Set the implementation
    @param _implementation The address of the implementation to use
    """
    assert msg.sender == self.owner  # dev: only owner

    log UpdateImplementation(self.get_implementation, _implementation)
    self.get_implementation = _implementation


@external
def commit_transfer_ownership(_future_owner: address):
    """
    @notice Transfer ownership to `_future_owner`
    @param _future_owner The account to commit as the future owner
    """
    assert msg.sender == self.owner  # dev: only owner

    self.future_owner = _future_owner


@external
def accept_transfer_ownership():
    """
    @notice Accept the transfer of ownership
    @dev Only the committed future owner can call this function
    """
    assert msg.sender == self.future_owner  # dev: only future owner

    log TransferOwnership(self.owner, msg.sender)
    self.owner = msg.sender