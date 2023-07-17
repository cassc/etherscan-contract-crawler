# @version 0.2.8
"""
@title Curve SynthSwap
@author Curve.fi
@license MIT
@notice Allows cross-asset swaps via Curve and Synthetix
"""

from vyper.interfaces import ERC20
from vyper.interfaces import ERC721

implements: ERC721


interface AddressProvider:
    def get_registry() -> address: view
    def get_address(_id: uint256) -> address: view

interface Curve:
    def get_dy(i: int128, j: int128, dx: uint256) -> uint256: view

interface Registry:
    def get_coins(_pool: address) -> address[8]: view
    def get_coin_indices(pool: address, _from: address, _to: address) -> (int128, int128): view

interface RegistrySwap:
    def exchange(
        _pool: address,
        _from: address,
        _to: address,
        _amount: uint256,
        _expected: uint256,
        _receiver: address,
    ) -> uint256: payable

interface SNXAddressResolver:
    def getAddress(name: bytes32) -> address: view

interface Synth:
    def currencyKey() -> bytes32: nonpayable

interface Exchanger:
    def getAmountsForExchange(
        sourceAmount: uint256,
        sourceCurrencyKey: bytes32,
        destinationCurrencyKey: bytes32
    ) -> (uint256, uint256, uint256): view
    def maxSecsLeftInWaitingPeriod(account: address, currencyKey: bytes32) -> uint256: view
    def settlementOwing(account: address, currencyKey: bytes32) -> (uint256, uint256): view
    def settle(user: address, currencyKey: bytes32): nonpayable

interface Settler:
    def initialize(): nonpayable
    def synth() -> address: view
    def time_to_settle() -> uint256: view
    def convert_synth(
        _target: address,
        _amount: uint256,
        _source_key: bytes32,
        _dest_key: bytes32
    ) -> bool: nonpayable
    def exchange(
        _target: address,
        _pool: address,
        _amount: uint256,
        _expected: uint256,
        _receiver: address,
    ) -> uint256: nonpayable
    def withdraw(_receiver: address, _amount: uint256) -> uint256: nonpayable

interface ERC721Receiver:
    def onERC721Received(
            _operator: address,
            _from: address,
            _token_id: uint256,
            _data: Bytes[1024]
        ) -> bytes32: view


event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    token_id: indexed(uint256)

event Approval:
    owner: indexed(address)
    approved: indexed(address)
    token_id: indexed(uint256)

event ApprovalForAll:
    owner: indexed(address)
    operator: indexed(address)
    approved: bool

event NewSettler:
    addr: address

event NewSynth:
    synth: address
    pool: address

event TokenUpdate:
    token_id: indexed(uint256)
    owner: indexed(address)
    synth: indexed(address)
    underlying_balance: uint256


struct TokenInfo:
    owner: address
    synth: address
    underlying_balance: uint256
    time_to_settle: uint256


ADDRESS_PROVIDER: constant(address) = 0x0000000022D53366457F9d5E68Ec105046FC4383

SNX_ADDRESS_RESOLVER: constant(address) = 0x4E3b31eB0E5CB73641EE1E65E7dCEFe520bA3ef2
EXCHANGER_KEY: constant(bytes32) = 0x45786368616e6765720000000000000000000000000000000000000000000000

# token id -> owner
id_to_owner: HashMap[uint256, address]
# token id -> address approved to transfer this nft
id_to_approval: HashMap[uint256, address]
# owner -> number of nfts
owner_to_token_count: HashMap[address, uint256]
# owner -> operator -> is approved?
owner_to_operators: HashMap[address, HashMap[address, bool]]

# implementation contract used for `Settler` proxies
settler_implementation: address

# list of available token IDs
# each token ID has an associated `Settler` contract, and to reduce
# gas costs these contracts are reused. Each token ID is created from
# [12 byte nonce][20 byte settler address]. The nonce starts at 0 and is
# incremented each time the token ID is "freed" (added to `available_token_ids`)
available_token_ids: uint256[4294967296]
id_count: uint256

# synth -> curve pool where it can be traded
synth_pools: public(HashMap[address, address])
# coin -> synth that it can be swapped for
swappable_synth: public(HashMap[address, address])
# token id -> is synth settled?
is_settled: public(HashMap[uint256, bool])
# coin -> spender -> is approved to transfer from this contract?
is_approved: HashMap[address, HashMap[address, bool]]
# synth -> currency key
currency_keys: HashMap[address, bytes32]

# Synthetix exchanger contract
exchanger: Exchanger


@external
def __init__(_settler_implementation: address, _settler_count: uint256):
    """
    @notice Contract constructor
    @param _settler_implementation `Settler` implementation deployment
    """
    self.settler_implementation = _settler_implementation
    self.exchanger = Exchanger(SNXAddressResolver(SNX_ADDRESS_RESOLVER).getAddress(EXCHANGER_KEY))

    # deploy settler contracts immediately
    self.id_count = _settler_count
    for i in range(100):
        if i == _settler_count:
            break
        settler: address = create_forwarder_to(_settler_implementation)
        Settler(settler).initialize()
        self.available_token_ids[i] = convert(settler, uint256)
        log NewSettler(settler)


@view
@external
def name() -> String[15]:
    return "Curve SynthSwap"


@view
@external
def symbol() -> String[6]:
    return "CRV/SS"


@view
@external
def supportsInterface(_interface_id: bytes32) -> bool:
    """
    @dev Interface identification is specified in ERC-165
    @param _interface_id Id of the interface
    @return bool Is interface supported?
    """
    return _interface_id in [
        0x0000000000000000000000000000000000000000000000000000000001ffc9a7,  # ERC165
        0x0000000000000000000000000000000000000000000000000000000080ac58cd,  # ERC721
    ]


@view
@external
def balanceOf(_owner: address) -> uint256:
    """
    @notice Return the number of NFTs owned by `_owner`
    @dev Reverts if `_owner` is the zero address. NFTs assigned
         to the zero address are considered invalid
    @param _owner Address for whom to query the balance
    @return uint256 Number of NFTs owned by `_owner`
    """
    assert _owner != ZERO_ADDRESS
    return self.owner_to_token_count[_owner]


@view
@external
def ownerOf(_token_id: uint256) -> address:
    """
    @notice Return the address of the owner of the NFT
    @dev Reverts if `_token_id` is not a valid NFT
    @param _token_id The identifier for an NFT
    @return address NFT owner
    """
    owner: address = self.id_to_owner[_token_id]
    assert owner != ZERO_ADDRESS
    return owner


@view
@external
def getApproved(_token_id: uint256) -> address:
    """
    @notice Get the approved address for a single NFT
    @dev Reverts if `_token_id` is not a valid NFT
    @param _token_id ID of the NFT to query the approval of
    @return address Address approved to transfer this NFT
    """
    assert self.id_to_owner[_token_id] != ZERO_ADDRESS
    return self.id_to_approval[_token_id]


@view
@external
def isApprovedForAll(_owner: address, _operator: address) -> bool:
    """
    @notice Check if `_operator` is an approved operator for `_owner`
    @param _owner The address that owns the NFTs
    @param _operator The address that acts on behalf of the owner
    @return bool Is operator approved?
    """
    return self.owner_to_operators[_owner][_operator]


@internal
def _transfer(_from: address, _to: address, _token_id: uint256, _caller: address):
    assert _from != ZERO_ADDRESS, "Cannot send from zero address"
    assert _to != ZERO_ADDRESS, "Cannot send to zero address"
    owner: address = self.id_to_owner[_token_id]
    assert owner == _from, "Incorrect owner for Token ID"

    approved_for: address = self.id_to_approval[_token_id]
    if _caller != _from:
        assert approved_for == _caller or self.owner_to_operators[owner][_caller], "Caller is not owner or operator"

    if approved_for != ZERO_ADDRESS:
        self.id_to_approval[_token_id] = ZERO_ADDRESS

    self.id_to_owner[_token_id] = _to
    self.owner_to_token_count[_from] -= 1
    self.owner_to_token_count[_to] += 1

    log Transfer(_from, _to, _token_id)


@external
def transferFrom(_from: address, _to: address, _token_id: uint256):
    """
    @notice Transfer ownership of `_token_id` from `_from` to `_to`
    @dev Reverts unless `msg.sender` is the current owner, an
         authorized operator, or the approved address for `_token_id`
         Reverts if `_to` is the zero address
    @param _from The current owner of `_token_id`
    @param _to Address to transfer the NFT to
    @param _token_id ID of the NFT to transfer
    """
    self._transfer(_from, _to, _token_id, msg.sender)


@external
def safeTransferFrom(
    _from: address,
    _to: address,
    _token_id: uint256,
    _data: Bytes[1024]=b""
):
    """
    @notice Transfer ownership of `_token_id` from `_from` to `_to`
    @dev If `_to` is a smart contract, it must implement the `onERC721Received` function
         and return the value `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    @param _from The current owner of `_token_id`
    @param _to Address to transfer the NFT to
    @param _token_id ID of the NFT to transfer
    @param _data Additional data with no specified format, sent in call to `_to`
    """
    self._transfer(_from, _to, _token_id, msg.sender)

    if _to.is_contract:
        response: bytes32 = ERC721Receiver(_to).onERC721Received(msg.sender, _from, _token_id, _data)
        assert response == 0x150b7a0200000000000000000000000000000000000000000000000000000000


@external
def approve(_approved: address, _token_id: uint256):
    """
    @notice Set or reaffirm the approved address for an NFT.
            The zero address indicates there is no approved address.
    @dev Reverts unless `msg.sender` is the current NFT owner, or an authorized
         operator of the current owner. Reverts if `_token_id` is not a valid NFT.
    @param _approved Address to be approved for the given NFT ID
    @param _token_id ID of the token to be approved
    """
    owner: address = self.id_to_owner[_token_id]

    if msg.sender != self.id_to_owner[_token_id]:
        assert owner != ZERO_ADDRESS, "Unknown Token ID"
        assert self.owner_to_operators[owner][msg.sender], "Caller is not owner or operator"

    self.id_to_approval[_token_id] = _approved
    log Approval(owner, _approved, _token_id)


@external
def setApprovalForAll(_operator: address, _approved: bool):
    """
    @notice Enable or disable approval for a third party ("operator") to manage all
         NFTs owned by `msg.sender`.
    @param _operator Address to set operator authorization for.
    @param _approved True if the operators is approved, False to revoke approval.
    """
    self.owner_to_operators[msg.sender][_operator] = _approved
    log ApprovalForAll(msg.sender, _operator, _approved)


@view
@internal
def _get_swap_into(_from: address, _synth: address, _amount: uint256) -> uint256:
    registry: address = AddressProvider(ADDRESS_PROVIDER).get_registry()

    intermediate_synth: address = self.swappable_synth[_from]
    pool: address = self.synth_pools[intermediate_synth]

    synth_amount: uint256 = _amount
    if _from != intermediate_synth:
        i: int128 = 0
        j: int128 = 0
        i, j = Registry(registry).get_coin_indices(pool, _from, intermediate_synth)

        synth_amount = Curve(pool).get_dy(i, j, _amount)

    return self.exchanger.getAmountsForExchange(
        synth_amount,
        self.currency_keys[intermediate_synth],
        self.currency_keys[_synth],
    )[0]


@view
@external
def get_swap_into_synth_amount(_from: address, _synth: address, _amount: uint256) -> uint256:
    """
    @notice Return the amount received when performing a cross-asset swap
    @dev Used to calculate `_expected` when calling `swap_into_synth`. Be sure to
         reduce the value slightly to account for market movement prior to the
         transaction confirmation.
    @param _from Address of the initial asset being exchanged
    @param _synth Address of the synth being swapped into
    @param _amount Amount of `_from` to swap
    @return uint256 Expected amount of `_synth` received
    """
    return self._get_swap_into(_from, _synth, _amount)


@view
@internal
def _get_swap_from(_synth: address, _to: address, _amount: uint256) -> uint256:
    registry: address = AddressProvider(ADDRESS_PROVIDER).get_registry()
    pool: address = self.synth_pools[_synth]

    i: int128 = 0
    j: int128 = 0
    i, j = Registry(registry).get_coin_indices(pool, _synth, _to)

    return Curve(pool).get_dy(i, j, _amount)


@view
@external
def get_swap_from_synth_amount(_synth: address, _to: address, _amount: uint256) -> uint256:
    """
    @notice Return the amount received when swapping out of a settled synth
    @dev Used to calculate `_expected` when calling `swap_from_synth`. Be sure to
         reduce the value slightly to account for market movement prior to the
         transaction confirmation.
    @param _synth Address of the synth being swapped out of
    @param _to Address of the asset to swap into
    @param _amount Amount of `_synth` being exchanged
    @return uint256 Expected amount of `_to` received
    """
    return self._get_swap_from(_synth, _to, _amount)


@view
@external
def get_estimated_swap_amount(_from: address, _to: address, _amount: uint256) -> uint256:
    """
    @notice Estimate the final amount received when swapping between `_from` and `_to`
    @dev Actual received amount may be different if synth rates change during settlement
    @param _from Address of the initial asset being exchanged
    @param _to Address of the asset to swap into
    @param _amount Amount of `_from` being exchanged
    @return uint256 Estimated amount of `_to` received
    """
    synth: address = self.swappable_synth[_to]
    synth_amount: uint256 = self._get_swap_into(_from, synth, _amount)
    return self._get_swap_from(synth, _to, synth_amount)


@view
@external
def token_info(_token_id: uint256) -> TokenInfo:
    """
    @notice Get information about the synth represented by an NFT
    @param _token_id NFT token ID to query info about
    @return NFT owner
            Address of synth within the NFT
            Balance of the synth
            Max settlement time in seconds
    """
    info: TokenInfo = empty(TokenInfo)
    info.owner = self.id_to_owner[_token_id]
    assert info.owner != ZERO_ADDRESS

    settler: address = convert(_token_id % (2**160), address)
    info.synth = Settler(settler).synth()
    info.underlying_balance = ERC20(info.synth).balanceOf(settler)

    if not self.is_settled[_token_id]:
        currency_key: bytes32 = self.currency_keys[info.synth]
        reclaim: uint256 = 0
        rebate: uint256 = 0
        reclaim, rebate = self.exchanger.settlementOwing(settler, currency_key)
        info.underlying_balance = info.underlying_balance - reclaim + rebate
        info.time_to_settle = self.exchanger.maxSecsLeftInWaitingPeriod(settler, currency_key)

    return info


@payable
@external
def swap_into_synth(
    _from: address,
    _synth: address,
    _amount: uint256,
    _expected: uint256,
    _receiver: address = msg.sender,
    _existing_token_id: uint256 = 0,
) -> uint256:
    """
    @notice Perform a cross-asset swap between `_from` and `_synth`
    @dev Synth swaps require a settlement time to complete and so the newly
         generated synth cannot immediately be transferred onward. Calling
         this function mints an NFT which represents ownership of the generated
         synth. Once the settlement time has passed, the owner may claim the
         synth by calling to `swap_from_synth` or `withdraw`.
    @param _from Address of the initial asset being exchanged
    @param _synth Address of the synth being swapped into
    @param _amount Amount of `_from` to swap
    @param _expected Minimum amount of `_synth` to receive
    @param _receiver Address of the recipient of `_synth`, if not given
                       defaults to `msg.sender`
    @param _existing_token_id Token ID to deposit `_synth` into. If left as 0, a new NFT
                       is minted for the generated synth. If non-zero, the token ID
                       must be owned by `msg.sender` and must represent the same
                       synth as is being swapped into.
    @return uint256 NFT token ID
    """
    settler: address = ZERO_ADDRESS
    token_id: uint256 = 0

    if _existing_token_id == 0:
        # if no token ID is given we are initiating a new swap
        count: uint256 = self.id_count
        if count == 0:
            # if there are no availale settler contracts we must deploy a new one
            settler = create_forwarder_to(self.settler_implementation)
            Settler(settler).initialize()
            token_id = convert(settler, uint256)
            log NewSettler(settler)
        else:
            count -= 1
            token_id = self.available_token_ids[count]
            settler = convert(token_id % (2**160), address)
            self.id_count = count
    else:
        # if a token ID is given we are adding to the balance of an existing swap
        # so must check to make sure this is a permitted action
        settler = convert(_existing_token_id % (2**160), address)
        token_id = _existing_token_id
        owner: address = self.id_to_owner[_existing_token_id]
        if msg.sender != owner:
            assert owner != ZERO_ADDRESS, "Unknown Token ID"
            assert (
                self.owner_to_operators[owner][msg.sender] or
                msg.sender == self.id_to_approval[_existing_token_id]
            ), "Caller is not owner or operator"
        assert owner == _receiver, "Receiver is not owner"
        assert Settler(settler).synth() == _synth, "Incorrect synth for Token ID"

    registry_swap: address = AddressProvider(ADDRESS_PROVIDER).get_address(2)
    intermediate_synth: address = self.swappable_synth[_from]
    synth_amount: uint256 = 0

    if intermediate_synth == _from:
        # if `_from` is already a synth, no initial curve exchange is required
        assert ERC20(_from).transferFrom(msg.sender, settler, _amount)
        synth_amount = _amount
    else:
        if _from != 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE:
            # Vyper equivalent of SafeERC20Transfer, handles most ERC20 return values
            response: Bytes[32] = raw_call(
                _from,
                concat(
                    method_id("transferFrom(address,address,uint256)"),
                    convert(msg.sender, bytes32),
                    convert(self, bytes32),
                    convert(_amount, bytes32),
                ),
                max_outsize=32,
            )
            if len(response) != 0:
                assert convert(response, bool)
            if not self.is_approved[_from][registry_swap]:
                response = raw_call(
                    _from,
                    concat(
                        method_id("approve(address,uint256)"),
                        convert(registry_swap, bytes32),
                        convert(MAX_UINT256, bytes32),
                    ),
                    max_outsize=32,
                )
                if len(response) != 0:
                    assert convert(response, bool)
                self.is_approved[_from][registry_swap] = True

        # use Curve to exchange for initial synth, which is sent to the settler
        synth_amount = RegistrySwap(registry_swap).exchange(
            self.synth_pools[intermediate_synth],
            _from,
            intermediate_synth,
            _amount,
            0,
            settler,
            value=msg.value
        )

    # use Synthetix to convert initial synth into the target synth
    initial_balance: uint256 = ERC20(_synth).balanceOf(settler)
    Settler(settler).convert_synth(
        _synth,
        synth_amount,
        self.currency_keys[intermediate_synth],
        self.currency_keys[_synth]
    )
    final_balance: uint256 = ERC20(_synth).balanceOf(settler)
    assert final_balance - initial_balance >= _expected, "Rekt by slippage"

    # if this is a new swap, mint an NFT to represent the unsettled conversion
    if _existing_token_id == 0:
        self.id_to_owner[token_id] = _receiver
        self.owner_to_token_count[_receiver] += 1
        log Transfer(ZERO_ADDRESS, _receiver, token_id)

    log TokenUpdate(token_id, _receiver, _synth, final_balance)

    return token_id


@external
def swap_from_synth(
    _token_id: uint256,
    _to: address,
    _amount: uint256,
    _expected: uint256,
    _receiver: address = msg.sender,
) -> uint256:
    """
    @notice Swap the synth represented by an NFT into another asset.
    @dev Callable by the owner or operator of `_token_id` after the synth settlement
         period has passed. If `_amount` is equal to the entire balance within
         the NFT, the NFT is burned.
    @param _token_id The identifier for an NFT
    @param _to Address of the asset to swap into
    @param _amount Amount of the synth to swap
    @param _expected Minimum amount of `_to` to receive
    @param _receiver Address of the recipient of the synth,
                     if not given defaults to `msg.sender`
    @return uint256 Synth balance remaining in `_token_id`
    """
    owner: address = self.id_to_owner[_token_id]
    if msg.sender != self.id_to_owner[_token_id]:
        assert owner != ZERO_ADDRESS, "Unknown Token ID"
        assert (
            self.owner_to_operators[owner][msg.sender] or
            msg.sender == self.id_to_approval[_token_id]
        ), "Caller is not owner or operator"

    settler: address = convert(_token_id % (2**160), address)
    synth: address = self.swappable_synth[_to]
    pool: address = self.synth_pools[synth]

    # ensure the synth is settled prior to swapping
    if not self.is_settled[_token_id]:
        currency_key: bytes32 = self.currency_keys[synth]
        self.exchanger.settle(settler, currency_key)
        self.is_settled[_token_id] = True

    # use Curve to exchange the synth for another asset which is sent to the receiver
    remaining: uint256 = Settler(settler).exchange(_to, pool, _amount, _expected, _receiver)

    # if the balance of the synth within the NFT is now zero, burn the NFT
    if remaining == 0:
        self.id_to_owner[_token_id] = ZERO_ADDRESS
        self.id_to_approval[_token_id] = ZERO_ADDRESS
        self.is_settled[_token_id] = False
        self.owner_to_token_count[msg.sender] -= 1

        count: uint256 = self.id_count
        # add 2**160 to increment the nonce for next time this settler is used
        self.available_token_ids[count] = _token_id + 2**160
        self.id_count = count + 1

        owner = ZERO_ADDRESS
        synth = ZERO_ADDRESS
        log Transfer(msg.sender, ZERO_ADDRESS, _token_id)

    log TokenUpdate(_token_id, owner, synth, remaining)

    return remaining


@external
def withdraw(_token_id: uint256, _amount: uint256, _receiver: address = msg.sender) -> uint256:
    """
    @notice Withdraw the synth represented by an NFT.
    @dev Callable by the owner or operator of `_token_id` after the synth settlement
         period has passed. If `_amount` is equal to the entire balance within
         the NFT, the NFT is burned.
    @param _token_id The identifier for an NFT
    @param _amount Amount of the synth to withdraw
    @param _receiver Address of the recipient of the synth,
                     if not given defaults to `msg.sender`
    @return uint256 Synth balance remaining in `_token_id`
    """
    owner: address = self.id_to_owner[_token_id]
    if msg.sender != self.id_to_owner[_token_id]:
        assert owner != ZERO_ADDRESS, "Unknown Token ID"
        assert (
            self.owner_to_operators[owner][msg.sender] or
            msg.sender == self.id_to_approval[_token_id]
        ), "Caller is not owner or operator"

    settler: address = convert(_token_id % (2**160), address)
    synth: address = Settler(settler).synth()

    # ensure the synth is settled prior to withdrawal
    if not self.is_settled[_token_id]:
        currency_key: bytes32 = self.currency_keys[synth]
        self.exchanger.settle(settler, currency_key)
        self.is_settled[_token_id] = True

    remaining: uint256 = Settler(settler).withdraw(_receiver, _amount)

    # if the balance of the synth within the NFT is now zero, burn the NFT
    if remaining == 0:
        self.id_to_owner[_token_id] = ZERO_ADDRESS
        self.id_to_approval[_token_id] = ZERO_ADDRESS
        self.is_settled[_token_id] = False
        self.owner_to_token_count[msg.sender] -= 1

        count: uint256 = self.id_count
        # add 2**160 to increment the nonce for next time this settler is used
        self.available_token_ids[count] = _token_id + 2**160
        self.id_count = count + 1

        owner = ZERO_ADDRESS
        synth = ZERO_ADDRESS
        log Transfer(msg.sender, ZERO_ADDRESS, _token_id)


    log TokenUpdate(_token_id, owner, synth, remaining)

    return remaining


@external
def settle(_token_id: uint256) -> bool:
    """
    @notice Settle the synth represented in an NFT.
    @dev Settlement is performed when swapping or withdrawing, there
         is no requirement to call this function separately.
    @param _token_id The identifier for an NFT
    @return bool Success
    """
    if not self.is_settled[_token_id]:
        assert self.id_to_owner[_token_id] != ZERO_ADDRESS, "Unknown Token ID"

        settler: address = convert(_token_id % (2**160), address)
        synth: address = Settler(settler).synth()
        currency_key: bytes32 = self.currency_keys[synth]
        self.exchanger.settle(settler, currency_key)  # dev: settlement failed
        self.is_settled[_token_id] = True

    return True


@external
def add_synth(_synth: address, _pool: address):
    """
    @notice Add a new swappable synth
    @dev Callable by anyone, however `_pool` must exist within the Curve
         pool registry and `_synth` must be a valid synth that is swappable
         within the pool
    @param _synth Address of the synth to add
    @param _pool Address of the Curve pool where `_synth` is swappable
    """
    assert self.synth_pools[_synth] == ZERO_ADDRESS  # dev: already added

    # this will revert if `_synth` is not actually a synth
    self.currency_keys[_synth] = Synth(_synth).currencyKey()

    registry: address = AddressProvider(ADDRESS_PROVIDER).get_registry()
    pool_coins: address[8] = Registry(registry).get_coins(_pool)

    has_synth: bool = False
    for coin in pool_coins:
        if coin == ZERO_ADDRESS:
            assert has_synth  # dev: synth not in pool
            break
        if coin == _synth:
            self.synth_pools[_synth] = _pool
            has_synth = True
        self.swappable_synth[coin] = _synth

    log NewSynth(_synth, _pool)


@external
def rebuildCache():
    """
    @notice Update the current address of the SNX Exchanger contract
    @dev The SNX exchanger address is kept in the local contract storage to reduce gas costs.
         If this address changes, contract will stop working until the local address is updated.
         Synthetix automates this process within their own architecture by exposing a `rebuildCache`
         method in their own contracts, and calling them all to update via `AddressResolver.rebuildCaches`,
         so we use the same API in order to be able to receive updates from them as well.
         https://docs.synthetix.io/contracts/source/contracts/AddressResolver/#rebuildcaches
    """
    self.exchanger = Exchanger(SNXAddressResolver(SNX_ADDRESS_RESOLVER).getAddress(EXCHANGER_KEY))