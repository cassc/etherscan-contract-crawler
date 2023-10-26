
# @version ^0.3.9

# ██╗  ██╗██╗██╗     ███╗   ██╗
# ██║ ██╔╝██║██║     ████╗  ██║
# █████╔╝ ██║██║     ██╔██╗ ██║
# ██╔═██╗ ██║██║     ██║╚██╗██║
# ██║  ██╗██║███████╗██║ ╚████║
# ╚═╝  ╚═╝╚═╝╚══════╝╚═╝  ╚═══╝

"""
@title Batch deposit contract
@notice Allows for batched deposits to the the Ethereum beacon chain deposit contract
@license MIT
@author 0xvv <https://github.com/0xvv>
@author Axxe <https://github.com/maximebrugel>
"""

MAX_LEN: constant(uint256) = 64  # lower is more gas efficient, but less flexible
BIG_MAX_LEN: constant(uint256) = 512
PUBLIC_KEY_LEN: constant(uint256) = 48
WITHDRAWAL_CRED_LEN: constant(uint256) = 32
SIGNATURE_LEN: constant(uint256) = 96

depositAddress: immutable(address)


@external
def __init__(depositAdd: address):
    depositAddress = depositAdd


@payable
@external
def batchDeposit(
    publicKeys: Bytes[MAX_LEN * PUBLIC_KEY_LEN],
    withdrawalCreds: Bytes[MAX_LEN * WITHDRAWAL_CRED_LEN],
    signatures: Bytes[MAX_LEN * SIGNATURE_LEN],
    dataRoots: DynArray[bytes32, MAX_LEN],
):
    """
    @notice Deposit up to 64 validators to the offical staking contract
    @dev Max of 64 validators to limit the gas overhead of bigger limits for smaller deposits
    @param publicKeys The public keys of the validators to deposit
    @param withdrawalCreds The withdrawal credentials of the validators to deposit
    @param signatures The signatures of the validators to deposit
    @param dataRoots The data roots of the validators to deposit
    """
    assert len(publicKeys) == len(dataRoots) * PUBLIC_KEY_LEN
    assert len(withdrawalCreds) == len(dataRoots) * WITHDRAWAL_CRED_LEN
    assert len(signatures) == len(dataRoots) * SIGNATURE_LEN
    if as_wei_value(32, "ether") * len(dataRoots) != msg.value:
        raise "Incorrect amount sent"
    pk: uint256 = 0
    wc: uint256 = 0
    sig: uint256 = 0
    for dataRoot in dataRoots:
        raw_call(
            depositAddress,
            _abi_encode(
                slice(publicKeys, pk, PUBLIC_KEY_LEN),
                slice(withdrawalCreds, wc, WITHDRAWAL_CRED_LEN),
                slice(signatures, sig, SIGNATURE_LEN),
                dataRoot,
                method_id=method_id("deposit(bytes,bytes,bytes,bytes32)"),
            ),
            value=as_wei_value(32, "ether"),
            revert_on_failure=True,
        )
        pk += PUBLIC_KEY_LEN
        wc += WITHDRAWAL_CRED_LEN
        sig += SIGNATURE_LEN


@payable
@external
def batchDepositCustom(
    publicKeys: Bytes[MAX_LEN * PUBLIC_KEY_LEN],
    withdrawalCreds: Bytes[MAX_LEN * WITHDRAWAL_CRED_LEN],
    signatures: Bytes[MAX_LEN * SIGNATURE_LEN],
    dataRoots: DynArray[bytes32, MAX_LEN],
    amountPerValidator: uint256,
):
    """
    @notice Deposit up to 64 validators to the offical staking contract with a custom amount per validator
    @dev Max of 64 validators to limit the gas overhead of bigger limits for smaller deposits
    @dev This function is here for future proofing, but at deployment time 32 ETH is the max effective balance for a validator
    @param publicKeys The public keys of the validators to deposit
    @param withdrawalCreds The withdrawal credentials of the validators to deposit
    @param signatures The signatures of the validators to deposit
    @param dataRoots The data roots of the validators to deposit
    @param amountPerValidator The amount of ETH to stake per validator
    """
    assert len(publicKeys) == len(dataRoots) * PUBLIC_KEY_LEN
    assert len(withdrawalCreds) == len(dataRoots) * WITHDRAWAL_CRED_LEN
    assert len(signatures) == len(dataRoots) * SIGNATURE_LEN
    if amountPerValidator * len(dataRoots) != msg.value:
        raise "Incorrect amount sent"
    pk: uint256 = 0
    wc: uint256 = 0
    sig: uint256 = 0
    for dataRoot in dataRoots:
        raw_call(
            depositAddress,
            _abi_encode(
                slice(publicKeys, pk, PUBLIC_KEY_LEN),
                slice(withdrawalCreds, wc, WITHDRAWAL_CRED_LEN),
                slice(signatures, sig, SIGNATURE_LEN),
                dataRoot,
                method_id=method_id("deposit(bytes,bytes,bytes,bytes32)"),
            ),
            value=amountPerValidator,
            revert_on_failure=True,
        )
        pk += PUBLIC_KEY_LEN
        wc += WITHDRAWAL_CRED_LEN
        sig += SIGNATURE_LEN


@payable
@external
def bigBatchDeposit(
    publicKeys: Bytes[BIG_MAX_LEN * PUBLIC_KEY_LEN],
    withdrawalCreds: Bytes[BIG_MAX_LEN * WITHDRAWAL_CRED_LEN],
    signatures: Bytes[BIG_MAX_LEN * SIGNATURE_LEN],
    dataRoots: DynArray[bytes32, BIG_MAX_LEN],
):
    """
    @notice Deposit up to 512 validators to the offical staking contract
    @notice This function should only be used for large deposits (>64 validators)
    @param publicKeys The public keys of the validators to deposit
    @param withdrawalCreds The withdrawal credentials of the validators to deposit
    @param signatures The signatures of the validators to deposit
    @param dataRoots The data roots of the validators to deposit
    """
    assert len(publicKeys) == len(dataRoots) * PUBLIC_KEY_LEN
    assert len(withdrawalCreds) == len(dataRoots) * WITHDRAWAL_CRED_LEN
    assert len(signatures) == len(dataRoots) * SIGNATURE_LEN
    if as_wei_value(32, "ether") * len(dataRoots) != msg.value:
        raise "Incorrect amount sent"
    pk: uint256 = 0
    wc: uint256 = 0
    sig: uint256 = 0
    for dataRoot in dataRoots:
        raw_call(
            depositAddress,
            _abi_encode(
                slice(publicKeys, pk, PUBLIC_KEY_LEN),
                slice(withdrawalCreds, wc, WITHDRAWAL_CRED_LEN),
                slice(signatures, sig, SIGNATURE_LEN),
                dataRoot,
                method_id=method_id("deposit(bytes,bytes,bytes,bytes32)"),
            ),
            value=as_wei_value(32, "ether"),
            revert_on_failure=True,
        )
        pk += PUBLIC_KEY_LEN
        wc += WITHDRAWAL_CRED_LEN
        sig += SIGNATURE_LEN


@payable
@external
def bigBatchDepositCustom(
    publicKeys: Bytes[BIG_MAX_LEN * PUBLIC_KEY_LEN],
    withdrawalCreds: Bytes[BIG_MAX_LEN * WITHDRAWAL_CRED_LEN],
    signatures: Bytes[BIG_MAX_LEN * SIGNATURE_LEN],
    dataRoots: DynArray[bytes32, BIG_MAX_LEN],
    amountPerValidator: uint256,
):
    """
    @notice Deposit up to 512 validators to the offical staking contract
    @notice This function should only be used for large deposits (>64 validators)
    @dev This function is here for future proofing, but at deployment time 32 ETH is the max effective balance for a validator
    @param publicKeys The public keys of the validators to deposit
    @param withdrawalCreds The withdrawal credentials of the validators to deposit
    @param signatures The signatures of the validators to deposit
    @param dataRoots The data roots of the validators to deposit
    @param amountPerValidator The amount of ETH to stake per validator
    """
    assert len(publicKeys) == len(dataRoots) * PUBLIC_KEY_LEN
    assert len(withdrawalCreds) == len(dataRoots) * WITHDRAWAL_CRED_LEN
    assert len(signatures) == len(dataRoots) * SIGNATURE_LEN
    if amountPerValidator * len(dataRoots) != msg.value:
        raise "Incorrect amount sent"
    pk: uint256 = 0
    wc: uint256 = 0
    sig: uint256 = 0
    for dataRoot in dataRoots:
        raw_call(
            depositAddress,
            _abi_encode(
                slice(publicKeys, pk, PUBLIC_KEY_LEN),
                slice(withdrawalCreds, wc, WITHDRAWAL_CRED_LEN),
                slice(signatures, sig, SIGNATURE_LEN),
                dataRoot,
                method_id=method_id("deposit(bytes,bytes,bytes,bytes32)"),
            ),
            value=amountPerValidator,
            revert_on_failure=True,
        )
        pk += PUBLIC_KEY_LEN
        wc += WITHDRAWAL_CRED_LEN
        sig += SIGNATURE_LEN