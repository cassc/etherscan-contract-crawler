/**
 *Submitted for verification at BscScan.com on 2023-02-23
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

/*
 * ...
 * The soldiers, like a fire consuming all the land,
 * moved on out. Earth groaned under them, just as it does
 * when Zeus, who loves thunder, in his anger lashes
 * the land around Typhoeus, among the Arimi,
 * where people say Typhoeus has his lair.
 * That’s how the earth groaned loudly under marching feet.
 * ...
 */

uint256 constant OrderReconciler_error_signature = (
    0x4e5230cd00000000000000000000000000000000000000000000000000000000
);
uint256 constant OrderReconciler_error_ptr = 0x00;
uint256 constant OrderReconciler_channel_ptr = 0x2;
uint256 constant OrderReconciler_error_length = 0x24;

uint256 constant ChannelClosed_error_signature = (
    0x93daadf200000000000000000000000000000000000000000000000000000000
);
uint256 constant ChannelClosed_error_ptr = 0x00;
uint256 constant ChannelClosed_channel_ptr = 0x4;
uint256 constant ChannelClosed_error_length = 0x24;

uint256 constant ChannelKey_channel_ptr = 0x00;
uint256 constant ChannelKey_slot_ptr = 0x20;
uint256 constant ChannelKey_length = 0x40;

uint256 constant ThirtyOneBytes = 0x1f;
uint256 constant OneWord = 0x20;
uint256 constant TwoWords = 0x40;
uint256 constant ThreeWords = 0x60;

uint256 constant OneWordShift = 0x5;
uint256 constant TwoWordsShift = 0x6;

uint256 constant FreeMemoryPointerSlot = 0x40;
uint256 constant ZeroSlot = 0x60;
uint256 constant DefaultFreeMemoryPointer = 0x80;

uint256 constant Slot0x80 = 0x80;
uint256 constant Slot0xA0 = 0xa0;
uint256 constant Slot0xC0 = 0xc0;

uint256 constant Generic_error_selector_offset = 0x1c;
uint256 constant ERC20_transferFrom_signature = (
    0x23b872dd00000000000000000000000000000000000000000000000000000000
);
uint256 constant ERC20_transferFrom_sig_ptr = 0x0;
uint256 constant ERC20_transferFrom_from_ptr = 0x04;
uint256 constant ERC20_transferFrom_to_ptr = 0x24;
uint256 constant ERC20_transferFrom_amount_ptr = 0x44;
uint256 constant ERC20_transferFrom_length = 0x64;
uint256 constant ERC1155_safeTransferFrom_signature = (
    0xf242432a00000000000000000000000000000000000000000000000000000000
);
uint256 constant ERC1155_safeTransferFrom_sig_ptr = 0x0;
uint256 constant ERC1155_safeTransferFrom_from_ptr = 0x04;
uint256 constant ERC1155_safeTransferFrom_to_ptr = 0x24;
uint256 constant ERC1155_safeTransferFrom_id_ptr = 0x44;
uint256 constant ERC1155_safeTransferFrom_amount_ptr = 0x64;
uint256 constant ERC1155_safeTransferFrom_data_offset_ptr = 0x84;
uint256 constant ERC1155_safeTransferFrom_data_length_ptr = 0xa4;
uint256 constant ERC1155_safeTransferFrom_length = 0xc4;
uint256 constant ERC1155_safeTransferFrom_data_length_offset = 0xa0;

uint256 constant ERC1155_safeBatchTransferFrom_signature = (
    0x2eb2c2d600000000000000000000000000000000000000000000000000000000
);
uint256 constant ERC721_transferFrom_signature = (
    0x23b872dd00000000000000000000000000000000000000000000000000000000
);
uint256 constant ERC721_transferFrom_sig_ptr = 0x0;
uint256 constant ERC721_transferFrom_from_ptr = 0x04;
uint256 constant ERC721_transferFrom_to_ptr = 0x24;
uint256 constant ERC721_transferFrom_id_ptr = 0x44;
uint256 constant ERC721_transferFrom_length = 0x64;
uint256 constant NoContract_error_selector = 0x5f15d672;
uint256 constant NoContract_error_account_ptr = 0x20;
uint256 constant NoContract_error_length = 0x24;
uint256 constant TokenTransferGenericFailure_error_selector = 0xf486bc87;
uint256 constant TokenTransferGenericFailure_error_token_ptr = 0x20;
uint256 constant TokenTransferGenericFailure_error_from_ptr = 0x40;
uint256 constant TokenTransferGenericFailure_error_to_ptr = 0x60;
uint256 constant TokenTransferGenericFailure_error_identifier_ptr = 0x80;
uint256 constant TokenTransferGenericFailure_err_identifier_ptr = 0x80;
uint256 constant TokenTransferGenericFailure_error_amount_ptr = 0xa0;
uint256 constant TokenTransferGenericFailure_error_length = 0xa4;

uint256 constant ExtraGasBuffer = 0x20;
uint256 constant CostPerWord = 0x3;
uint256 constant MemoryExpansionCoefficientShift = 0x9;

uint256 constant BatchTransfer1155Params_ptr = 0x24;
uint256 constant BatchTransfer1155Params_ids_head_ptr = 0x64;
uint256 constant BatchTransfer1155Params_amounts_head_ptr = 0x84;
uint256 constant BatchTransfer1155Params_data_head_ptr = 0xa4;
uint256 constant BatchTransfer1155Params_data_length_basePtr = 0xc4;
uint256 constant BatchTransfer1155Params_calldata_baseSize = 0xc4;
uint256 constant BatchTransfer1155Params_ids_length_ptr = 0xc4;
uint256 constant BatchTransfer1155Params_ids_length_offset = 0xa0;
uint256 constant ConduitBatch1155Transfer_usable_head_size = 0x80;
uint256 constant ConduitBatch1155Transfer_from_offset = 0x20;
uint256 constant ConduitBatch1155Transfer_ids_head_offset = 0x60;
uint256 constant ConduitBatch1155Transfer_ids_length_offset = 0xa0;
uint256 constant ConduitBatch1155Transfer_amounts_length_baseOffset = 0xc0;
uint256 constant ConduitBatchTransfer_amounts_head_offset = 0x80;
uint256 constant Invalid1155BatchTransferEncoding_ptr = 0x00;
uint256 constant Invalid1155BatchTransferEncoding_length = 0x04;
uint256 constant Invalid1155BatchTransferEncoding_selector = (
    0xeba2084c00000000000000000000000000000000000000000000000000000000
);

uint256 constant ERC1155BatchTransferGenericFailure_error_signature = (
    0xafc445e200000000000000000000000000000000000000000000000000000000
);
uint256 constant ERC1155BatchTransferGenericFailure_token_ptr = 0x04;
uint256 constant ERC1155BatchTransferGenericFailure_ids_offset = 0xc0;

uint256 constant BadReturnValueFromERC20OnTransfer_error_selector = 0x98891923;
uint256 constant BadReturnValueFromERC20OnTransfer_error_token_ptr = 0x20;
uint256 constant BadReturnValueFromERC20OnTransfer_error_from_ptr = 0x40;
uint256 constant BadReturnValueFromERC20OnTransfer_error_to_ptr = 0x60;
uint256 constant BadReturnValueFromERC20OnTransfer_error_amount_ptr = 0x80;
uint256 constant BadReturnValueFromERC20OnTransfer_error_length = 0x84;

enum ConduitItemType {
    NATIVE,
    ERC20,
    ERC721,
    ERC1155
}

struct ConduitTransfer {
    ConduitItemType itemType;
    address token;
    address from;
    address to;
    uint256 identifier;
    uint256 amount;
}

struct ConduitBatch1155Transfer {
    address token;
    address from;
    address to;
    uint256[] ids;
    uint256[] amounts;
}

interface ConduitInterface {
    error ChannelClosed(address channel);

    error ChannelStatusAlreadySet(address channel, bool isOpen);

    error InvalidItemType();

    error InvalidController();

    event ChannelUpdated(address indexed channel, bool open);

    function execute(
        ConduitTransfer[] calldata transfers
    ) external returns (bytes4 magicValue);

    function executeBatch1155(
        ConduitBatch1155Transfer[] calldata batch1155Transfers
    ) external returns (bytes4 magicValue);

    function executeWithBatch1155(
        ConduitTransfer[] calldata standardTransfers,
        ConduitBatch1155Transfer[] calldata batch1155Transfers
    ) external returns (bytes4 magicValue);

    function updateChannel(address channel, bool isOpen) external;
}

interface ConduitControllerInterface {
    struct ConduitProperties {
        bytes32 key;
        address owner;
        address potentialOwner;
        address[] channels;
        mapping(address => uint256) channelIndexesPlusOne;
    }

    event NewConduit(address conduit, bytes32 conduitKey);

    event OwnershipTransferred(
        address indexed conduit,
        address indexed previousOwner,
        address indexed newOwner
    );

    event PotentialOwnerUpdated(address indexed newPotentialOwner);

    error InvalidCreator();

    error InvalidInitialOwner();

    error NewPotentialOwnerAlreadySet(
        address conduit,
        address newPotentialOwner
    );

    error NoPotentialOwnerCurrentlySet(address conduit);

    error NoConduit();

    error ConduitAlreadyExists(address conduit);

    error CallerIsNotOwner(address conduit);

    error NewPotentialOwnerIsZeroAddress(address conduit);

    error CallerIsNotNewPotentialOwner(address conduit);

    error ChannelOutOfRange(address conduit);

    function createConduit(
        bytes32 conduitKey,
        address initialOwner
    ) external returns (address conduit);

    function updateChannel(
        address conduit,
        address channel,
        bool isOpen
    ) external;

    function transferOwnership(
        address conduit,
        address newPotentialOwner
    ) external;

    function cancelOwnershipTransfer(address conduit) external;

    function acceptOwnership(address conduit) external;

    function ownerOf(address conduit) external view returns (address owner);

    function getKey(address conduit) external view returns (bytes32 conduitKey);

    function getConduit(
        bytes32 conduitKey
    ) external view returns (address conduit, bool exists);

    function getPotentialOwner(
        address conduit
    ) external view returns (address potentialOwner);

    function getChannelStatus(
        address conduit,
        address channel
    ) external view returns (bool isOpen);

    function getTotalChannels(
        address conduit
    ) external view returns (uint256 totalChannels);

    function getChannel(
        address conduit,
        uint256 channelIndex
    ) external view returns (address channel);

    function getChannels(
        address conduit
    ) external view returns (address[] memory channels);

    function getConduitCodeHashes()
        external
        view
        returns (bytes32 creationCodeHash, bytes32 runtimeCodeHash);
}

interface TokenTransferrerErrors {
    error InvalidERC721TransferAmount(uint256 amount);

    error MissingItemAmount();

    error UnusedItemParameters();

    error TokenTransferGenericFailure(
        address token,
        address from,
        address to,
        uint256 identifier,
        uint256 amount
    );

    error ERC1155BatchTransferGenericFailure(
        address token,
        address from,
        address to,
        uint256[] identifiers,
        uint256[] amounts
    );

    error BadReturnValueFromERC20OnTransfer(
        address token,
        address from,
        address to,
        uint256 amount
    );

    error NoContract(address account);

    error Invalid1155BatchTransferEncoding();
}

contract TokenTransferrer is TokenTransferrerErrors {
    function _performERC20Transfer(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        assembly {
            let memPointer := mload(FreeMemoryPointerSlot)
            mstore(ERC20_transferFrom_sig_ptr, ERC20_transferFrom_signature)
            mstore(ERC20_transferFrom_from_ptr, from)
            mstore(ERC20_transferFrom_to_ptr, to)
            mstore(ERC20_transferFrom_amount_ptr, amount)
            let callStatus := call(
                gas(),
                token,
                0,
                ERC20_transferFrom_sig_ptr,
                ERC20_transferFrom_length,
                0,
                OneWord
            )
            let success := and(
                or(
                    and(eq(mload(0), 1), gt(returndatasize(), 31)),
                    iszero(returndatasize())
                ),
                callStatus
            )
            if iszero(and(success, iszero(iszero(returndatasize())))) {
                if iszero(and(iszero(iszero(extcodesize(token))), success)) {
                    if iszero(success) {
                        if iszero(callStatus) {
                            if returndatasize() {
                                let returnDataWords := shr(
                                    OneWordShift,
                                    add(returndatasize(), ThirtyOneBytes)
                                )
                                let msizeWords := shr(OneWordShift, memPointer)
                                let cost := mul(CostPerWord, returnDataWords)
                                if gt(returnDataWords, msizeWords) {
                                    cost := add(
                                        cost,
                                        add(
                                            mul(
                                                sub(
                                                    returnDataWords,
                                                    msizeWords
                                                ),
                                                CostPerWord
                                            ),
                                            shr(
                                                MemoryExpansionCoefficientShift,
                                                sub(
                                                    mul(
                                                        returnDataWords,
                                                        returnDataWords
                                                    ),
                                                    mul(msizeWords, msizeWords)
                                                )
                                            )
                                        )
                                    )
                                }
                                if lt(add(cost, ExtraGasBuffer), gas()) {
                                    returndatacopy(0, 0, returndatasize())
                                    revert(0, returndatasize())
                                }
                            }
                            mstore(
                                0,
                                TokenTransferGenericFailure_error_selector
                            )
                            mstore(
                                TokenTransferGenericFailure_error_token_ptr,
                                token
                            )
                            mstore(
                                TokenTransferGenericFailure_error_from_ptr,
                                from
                            )
                            mstore(TokenTransferGenericFailure_error_to_ptr, to)
                            mstore(
                                TokenTransferGenericFailure_err_identifier_ptr,
                                0
                            )
                            mstore(
                                TokenTransferGenericFailure_error_amount_ptr,
                                amount
                            )
                            revert(
                                Generic_error_selector_offset,
                                TokenTransferGenericFailure_error_length
                            )
                        }
                        mstore(
                            0,
                            BadReturnValueFromERC20OnTransfer_error_selector
                        )
                        mstore(
                            BadReturnValueFromERC20OnTransfer_error_token_ptr,
                            token
                        )
                        mstore(
                            BadReturnValueFromERC20OnTransfer_error_from_ptr,
                            from
                        )
                        mstore(
                            BadReturnValueFromERC20OnTransfer_error_to_ptr,
                            to
                        )
                        mstore(
                            BadReturnValueFromERC20OnTransfer_error_amount_ptr,
                            amount
                        )
                        revert(
                            Generic_error_selector_offset,
                            BadReturnValueFromERC20OnTransfer_error_length
                        )
                    }
                    mstore(0, NoContract_error_selector)
                    mstore(NoContract_error_account_ptr, token)
                    revert(
                        Generic_error_selector_offset,
                        NoContract_error_length
                    )
                }
            }
            mstore(FreeMemoryPointerSlot, memPointer)
            mstore(ZeroSlot, 0)
        }
    }

    function _performERC721Transfer(
        address token,
        address from,
        address to,
        uint256 identifier
    ) internal {
        assembly {
            if iszero(extcodesize(token)) {
                mstore(0, NoContract_error_selector)
                mstore(NoContract_error_account_ptr, token)
                revert(Generic_error_selector_offset, NoContract_error_length)
            }
            let memPointer := mload(FreeMemoryPointerSlot)
            mstore(ERC721_transferFrom_sig_ptr, ERC721_transferFrom_signature)
            mstore(ERC721_transferFrom_from_ptr, from)
            mstore(ERC721_transferFrom_to_ptr, to)
            mstore(ERC721_transferFrom_id_ptr, identifier)

            let success := call(
                gas(),
                token,
                0,
                ERC721_transferFrom_sig_ptr,
                ERC721_transferFrom_length,
                0,
                0
            )

            if iszero(success) {
                if returndatasize() {
                    let returnDataWords := shr(
                        OneWordShift,
                        add(returndatasize(), ThirtyOneBytes)
                    )

                    let msizeWords := shr(OneWordShift, memPointer)
                    let cost := mul(CostPerWord, returnDataWords)
                    if gt(returnDataWords, msizeWords) {
                        cost := add(
                            cost,
                            add(
                                mul(
                                    sub(returnDataWords, msizeWords),
                                    CostPerWord
                                ),
                                shr(
                                    MemoryExpansionCoefficientShift,
                                    sub(
                                        mul(returnDataWords, returnDataWords),
                                        mul(msizeWords, msizeWords)
                                    )
                                )
                            )
                        )
                    }

                    if lt(add(cost, ExtraGasBuffer), gas()) {
                        returndatacopy(0, 0, returndatasize())

                        revert(0, returndatasize())
                    }
                }
                mstore(0, TokenTransferGenericFailure_error_selector)
                mstore(TokenTransferGenericFailure_error_token_ptr, token)
                mstore(TokenTransferGenericFailure_error_from_ptr, from)
                mstore(TokenTransferGenericFailure_error_to_ptr, to)
                mstore(
                    TokenTransferGenericFailure_error_identifier_ptr,
                    identifier
                )
                mstore(TokenTransferGenericFailure_error_amount_ptr, 1)
                revert(
                    Generic_error_selector_offset,
                    TokenTransferGenericFailure_error_length
                )
            }
            mstore(FreeMemoryPointerSlot, memPointer)
            mstore(ZeroSlot, 0)
        }
    }

    function _performERC1155Transfer(
        address token,
        address from,
        address to,
        uint256 identifier,
        uint256 amount
    ) internal {
        assembly {
            if iszero(extcodesize(token)) {
                mstore(0, NoContract_error_selector)
                mstore(NoContract_error_account_ptr, token)
                revert(Generic_error_selector_offset, NoContract_error_length)
            }
            let memPointer := mload(FreeMemoryPointerSlot)
            let slot0x80 := mload(Slot0x80)
            let slot0xA0 := mload(Slot0xA0)
            let slot0xC0 := mload(Slot0xC0)
            mstore(
                ERC1155_safeTransferFrom_sig_ptr,
                ERC1155_safeTransferFrom_signature
            )
            mstore(ERC1155_safeTransferFrom_from_ptr, from)
            mstore(ERC1155_safeTransferFrom_to_ptr, to)
            mstore(ERC1155_safeTransferFrom_id_ptr, identifier)
            mstore(ERC1155_safeTransferFrom_amount_ptr, amount)
            mstore(
                ERC1155_safeTransferFrom_data_offset_ptr,
                ERC1155_safeTransferFrom_data_length_offset
            )
            mstore(ERC1155_safeTransferFrom_data_length_ptr, 0)

            let success := call(
                gas(),
                token,
                0,
                ERC1155_safeTransferFrom_sig_ptr,
                ERC1155_safeTransferFrom_length,
                0,
                0
            )

            if iszero(success) {
                if returndatasize() {
                    let returnDataWords := shr(
                        OneWordShift,
                        add(returndatasize(), ThirtyOneBytes)
                    )
                    let msizeWords := shr(OneWordShift, memPointer)
                    let cost := mul(CostPerWord, returnDataWords)

                    if gt(returnDataWords, msizeWords) {
                        cost := add(
                            cost,
                            add(
                                mul(
                                    sub(returnDataWords, msizeWords),
                                    CostPerWord
                                ),
                                shr(
                                    MemoryExpansionCoefficientShift,
                                    sub(
                                        mul(returnDataWords, returnDataWords),
                                        mul(msizeWords, msizeWords)
                                    )
                                )
                            )
                        )
                    }

                    if lt(add(cost, ExtraGasBuffer), gas()) {
                        returndatacopy(0, 0, returndatasize())
                        revert(0, returndatasize())
                    }
                }
                mstore(0, TokenTransferGenericFailure_error_selector)
                mstore(TokenTransferGenericFailure_error_token_ptr, token)
                mstore(TokenTransferGenericFailure_error_from_ptr, from)
                mstore(TokenTransferGenericFailure_error_to_ptr, to)
                mstore(
                    TokenTransferGenericFailure_error_identifier_ptr,
                    identifier
                )
                mstore(TokenTransferGenericFailure_error_amount_ptr, amount)
                revert(
                    Generic_error_selector_offset,
                    TokenTransferGenericFailure_error_length
                )
            }

            mstore(Slot0x80, slot0x80)
            mstore(Slot0xA0, slot0xA0)
            mstore(Slot0xC0, slot0xC0)

            mstore(FreeMemoryPointerSlot, memPointer)

            mstore(ZeroSlot, 0)
        }
    }

    function _performERC1155BatchTransfers(
        ConduitBatch1155Transfer[] calldata batchTransfers
    ) internal {
        assembly {
            let len := batchTransfers.length
            let nextElementHeadPtr := batchTransfers.offset

            let arrayHeadPtr := nextElementHeadPtr

            mstore(
                ConduitBatch1155Transfer_from_offset,
                ERC1155_safeBatchTransferFrom_signature
            )

            for {
                let i := 0
            } lt(i, len) {
                i := add(i, 1)
            } {
                let elementPtr := add(
                    arrayHeadPtr,
                    calldataload(nextElementHeadPtr)
                )
                let token := calldataload(elementPtr)

                if iszero(extcodesize(token)) {
                    mstore(0, NoContract_error_selector)
                    mstore(NoContract_error_account_ptr, token)

                    revert(
                        Generic_error_selector_offset,
                        NoContract_error_length
                    )
                }

                let idsLength := calldataload(
                    add(elementPtr, ConduitBatch1155Transfer_ids_length_offset)
                )

                let expectedAmountsOffset := add(
                    ConduitBatch1155Transfer_amounts_length_baseOffset,
                    shl(OneWordShift, idsLength)
                )

                let invalidEncoding := iszero(
                    and(
                        eq(
                            idsLength,
                            calldataload(add(elementPtr, expectedAmountsOffset))
                        ),
                        and(
                            eq(
                                calldataload(
                                    add(
                                        elementPtr,
                                        ConduitBatch1155Transfer_ids_head_offset
                                    )
                                ),
                                ConduitBatch1155Transfer_ids_length_offset
                            ),
                            eq(
                                calldataload(
                                    add(
                                        elementPtr,
                                        ConduitBatchTransfer_amounts_head_offset
                                    )
                                ),
                                expectedAmountsOffset
                            )
                        )
                    )
                )

                if invalidEncoding {
                    mstore(
                        Invalid1155BatchTransferEncoding_ptr,
                        Invalid1155BatchTransferEncoding_selector
                    )
                    revert(
                        Invalid1155BatchTransferEncoding_ptr,
                        Invalid1155BatchTransferEncoding_length
                    )
                }
                nextElementHeadPtr := add(nextElementHeadPtr, OneWord)
                calldatacopy(
                    BatchTransfer1155Params_ptr,
                    add(elementPtr, ConduitBatch1155Transfer_from_offset),
                    ConduitBatch1155Transfer_usable_head_size
                )
                let idsAndAmountsSize := add(
                    TwoWords,
                    shl(TwoWordsShift, idsLength)
                )
                mstore(
                    BatchTransfer1155Params_data_head_ptr,
                    add(
                        BatchTransfer1155Params_ids_length_offset,
                        idsAndAmountsSize
                    )
                )
                mstore(
                    add(
                        BatchTransfer1155Params_data_length_basePtr,
                        idsAndAmountsSize
                    ),
                    0
                )

                let transferDataSize := add(
                    BatchTransfer1155Params_calldata_baseSize,
                    idsAndAmountsSize
                )

                calldatacopy(
                    BatchTransfer1155Params_ids_length_ptr,
                    add(elementPtr, ConduitBatch1155Transfer_ids_length_offset),
                    idsAndAmountsSize
                )

                let success := call(
                    gas(),
                    token,
                    0,
                    ConduitBatch1155Transfer_from_offset,
                    transferDataSize,
                    0,
                    0
                )

                if iszero(success) {
                    if returndatasize() {
                        let returnDataWords := shr(
                            OneWordShift,
                            add(returndatasize(), ThirtyOneBytes)
                        )
                        let msizeWords := shr(OneWordShift, transferDataSize)

                        let cost := mul(CostPerWord, returnDataWords)

                        if gt(returnDataWords, msizeWords) {
                            cost := add(
                                cost,
                                add(
                                    mul(
                                        sub(returnDataWords, msizeWords),
                                        CostPerWord
                                    ),
                                    shr(
                                        MemoryExpansionCoefficientShift,
                                        sub(
                                            mul(
                                                returnDataWords,
                                                returnDataWords
                                            ),
                                            mul(msizeWords, msizeWords)
                                        )
                                    )
                                )
                            )
                        }
                        if lt(add(cost, ExtraGasBuffer), gas()) {
                            returndatacopy(0, 0, returndatasize())
                            revert(0, returndatasize())
                        }
                    }

                    mstore(
                        0,
                        ERC1155BatchTransferGenericFailure_error_signature
                    )

                    mstore(ERC1155BatchTransferGenericFailure_token_ptr, token)

                    mstore(
                        BatchTransfer1155Params_ids_head_ptr,
                        ERC1155BatchTransferGenericFailure_ids_offset
                    )

                    mstore(
                        BatchTransfer1155Params_amounts_head_ptr,
                        add(
                            OneWord,
                            mload(BatchTransfer1155Params_amounts_head_ptr)
                        )
                    )

                    revert(0, transferDataSize)
                }
            }
            mstore(FreeMemoryPointerSlot, DefaultFreeMemoryPointer)
        }
    }
}
contract Conduit is ConduitInterface, TokenTransferrer {
    address private immutable _controller;
    mapping(address => bool) private _channels;
    modifier onlyOpenChannel() {
        assembly {
            mstore(ChannelKey_channel_ptr, caller())
            mstore(ChannelKey_slot_ptr, _channels.slot)
            if iszero(
                sload(keccak256(ChannelKey_channel_ptr, ChannelKey_length))
            ) {
                mstore(ChannelClosed_error_ptr, ChannelClosed_error_signature)
                mstore(ChannelClosed_channel_ptr, caller())
                revert(ChannelClosed_error_ptr, ChannelClosed_error_length)
            }
        }
        _;
    }
    constructor() {
        _controller = msg.sender;
    }
    function execute(
        ConduitTransfer[] calldata transfers
    ) external override onlyOpenChannel returns (bytes4 magicValue) {
        uint256 totalStandardTransfers = transfers.length;
        for (uint256 i = 0; i < totalStandardTransfers; ) {
            _transfer(transfers[i]);
            unchecked {
                ++i;
            }
        }
        magicValue = this.execute.selector;
    }

    function executeBatch1155(
        ConduitBatch1155Transfer[] calldata batchTransfers
    ) external override onlyOpenChannel returns (bytes4 magicValue) {
        _performERC1155BatchTransfers(batchTransfers);
        magicValue = this.executeBatch1155.selector;
    }
    function executeWithBatch1155(
        ConduitTransfer[] calldata standardTransfers,
        ConduitBatch1155Transfer[] calldata batchTransfers
    ) external override onlyOpenChannel returns (bytes4 magicValue) {
        uint256 totalStandardTransfers = standardTransfers.length;
        for (uint256 i = 0; i < totalStandardTransfers; ) {
            _transfer(standardTransfers[i]);
            unchecked {
                ++i;
            }
        }
        _performERC1155BatchTransfers(batchTransfers);
        magicValue = this.executeWithBatch1155.selector;
    }
    function updateChannel(address channel, bool isOpen) external override {
        if (msg.sender != _controller) {
            revert InvalidController();
        }
        if (_channels[channel] == isOpen) {
            revert ChannelStatusAlreadySet(channel, isOpen);
        }
        _channels[channel] = isOpen;
        emit ChannelUpdated(channel, isOpen);
    }
    function _transfer(ConduitTransfer calldata item) internal {
        if (item.itemType == ConduitItemType.ERC20) {
            _performERC20Transfer(item.token, item.from, item.to, item.amount);
        } else if (item.itemType == ConduitItemType.ERC721) {
            if (item.amount != 1) {
                revert InvalidERC721TransferAmount(item.amount);
            }
            _performERC721Transfer(
                item.token,
                item.from,
                item.to,
                item.identifier
            );
        } else if (item.itemType == ConduitItemType.ERC1155) {
            _performERC1155Transfer(
                item.token,
                item.from,
                item.to,
                item.identifier,
                item.amount
            );
        } else {
            revert InvalidItemType();
        }
    }
}

contract ConduitController is ConduitControllerInterface {
    uint256 internal immutable _CC_DEPLOYMENY_REVISION = 1;
    mapping(address => ConduitProperties) internal _conduits;
    bytes32 internal immutable _CONDUIT_CREATION_CODE_HASH;
    bytes32 internal immutable _CONDUIT_RUNTIME_CODE_HASH;
    constructor() {
        _CONDUIT_CREATION_CODE_HASH = keccak256(type(Conduit).creationCode);

        Conduit zeroConduit = new Conduit{ salt: bytes32(0) }();

        _CONDUIT_RUNTIME_CODE_HASH = address(zeroConduit).codehash;
    }

    function createConduit(
        bytes32 conduitKey,
        address initialOwner
    ) external override returns (address conduit) {
        if (initialOwner == address(0)) {
            revert InvalidInitialOwner();
        }
        if (address(uint160(bytes20(conduitKey))) != msg.sender) {
            revert InvalidCreator();
        }
        conduit = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            address(this),
                            conduitKey,
                            _CONDUIT_CREATION_CODE_HASH
                        )
                    )
                )
            )
        );

        if (conduit.codehash == _CONDUIT_RUNTIME_CODE_HASH) {
            revert ConduitAlreadyExists(conduit);
        }
        new Conduit{ salt: conduitKey }();
        ConduitProperties storage conduitProperties = _conduits[conduit];
        conduitProperties.owner = initialOwner;

        conduitProperties.key = conduitKey;
        emit NewConduit(conduit, conduitKey);
        emit OwnershipTransferred(conduit, address(0), initialOwner);
    }

    function updateChannel(
        address conduit,
        address channel,
        bool isOpen
    ) external override {
        _assertCallerIsConduitOwner(conduit);

        ConduitInterface(conduit).updateChannel(channel, isOpen);

        ConduitProperties storage conduitProperties = _conduits[conduit];

        uint256 channelIndexPlusOne = (
            conduitProperties.channelIndexesPlusOne[channel]
        );
        bool channelPreviouslyOpen = channelIndexPlusOne != 0;

        if (isOpen && !channelPreviouslyOpen) {
            conduitProperties.channels.push(channel);

            conduitProperties.channelIndexesPlusOne[channel] = (
                conduitProperties.channels.length
            );
        } else if (!isOpen && channelPreviouslyOpen) {
            uint256 removedChannelIndex;

            unchecked {
                removedChannelIndex = channelIndexPlusOne - 1;
            }
            uint256 finalChannelIndex = conduitProperties.channels.length - 1;

            if (finalChannelIndex != removedChannelIndex) {
                address finalChannel = (
                    conduitProperties.channels[finalChannelIndex]
                );
                conduitProperties.channels[removedChannelIndex] = finalChannel;
                conduitProperties.channelIndexesPlusOne[finalChannel] = (
                    channelIndexPlusOne
                );
            }
            conduitProperties.channels.pop();
            delete conduitProperties.channelIndexesPlusOne[channel];
        }
    }
    function transferOwnership(
        address conduit,
        address newPotentialOwner
    ) external override {
        _assertCallerIsConduitOwner(conduit);
        if (newPotentialOwner == address(0)) {
            revert NewPotentialOwnerIsZeroAddress(conduit);
        }
        if (newPotentialOwner == _conduits[conduit].potentialOwner) {
            revert NewPotentialOwnerAlreadySet(conduit, newPotentialOwner);
        }
        emit PotentialOwnerUpdated(newPotentialOwner);

        _conduits[conduit].potentialOwner = newPotentialOwner;
    }
    function cancelOwnershipTransfer(address conduit) external override {
        _assertCallerIsConduitOwner(conduit);
        if (_conduits[conduit].potentialOwner == address(0)) {
            revert NoPotentialOwnerCurrentlySet(conduit);
        }
        emit PotentialOwnerUpdated(address(0));
        _conduits[conduit].potentialOwner = address(0);
    }

    function acceptOwnership(address conduit) external override {
        _assertConduitExists(conduit);
        if (msg.sender != _conduits[conduit].potentialOwner) {
            revert CallerIsNotNewPotentialOwner(conduit);
        }
        emit PotentialOwnerUpdated(address(0));
        _conduits[conduit].potentialOwner = address(0);
        emit OwnershipTransferred(
            conduit,
            _conduits[conduit].owner,
            msg.sender
        );
        _conduits[conduit].owner = msg.sender;
    }

    function ownerOf(
        address conduit
    ) external view override returns (address owner) {
        _assertConduitExists(conduit);
        owner = _conduits[conduit].owner;
    }

    function getKey(
        address conduit
    ) external view override returns (bytes32 conduitKey) {
        conduitKey = _conduits[conduit].key;
        if (conduitKey == bytes32(0)) {
            revert NoConduit();
        }
    }
    function _NS_CONTRACT_ROLE() external pure returns (string memory) {
        return "ConduitController";
    }
    function getConduit(
        bytes32 conduitKey
    ) external view override returns (address conduit, bool exists) {
        conduit = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            address(this),
                            conduitKey,
                            _CONDUIT_CREATION_CODE_HASH
                        )
                    )
                )
            )
        );
        exists = (conduit.codehash == _CONDUIT_RUNTIME_CODE_HASH);
    }
    function getPotentialOwner(
        address conduit
    ) external view override returns (address potentialOwner) {
        _assertConduitExists(conduit);
        potentialOwner = _conduits[conduit].potentialOwner;
    }
    function getChannelStatus(
        address conduit,
        address channel
    ) external view override returns (bool isOpen) {
        _assertConduitExists(conduit);
        isOpen = _conduits[conduit].channelIndexesPlusOne[channel] != 0;
    }
    function getTotalChannels(
        address conduit
    ) external view override returns (uint256 totalChannels) {
        _assertConduitExists(conduit);
        totalChannels = _conduits[conduit].channels.length;
    }
    function getChannel(
        address conduit,
        uint256 channelIndex
    ) external view override returns (address channel) {
        _assertConduitExists(conduit);
        uint256 totalChannels = _conduits[conduit].channels.length;
        if (channelIndex >= totalChannels) {
            revert ChannelOutOfRange(conduit);
        }
        channel = _conduits[conduit].channels[channelIndex];
    }
    function getChannels(
        address conduit
    ) external view override returns (address[] memory channels) {
        _assertConduitExists(conduit);
        channels = _conduits[conduit].channels;
    }

    function getConduitCodeHashes()
        external
        view
        override
        returns (bytes32 creationCodeHash, bytes32 runtimeCodeHash)
    {
        creationCodeHash = _CONDUIT_CREATION_CODE_HASH;
        runtimeCodeHash = _CONDUIT_RUNTIME_CODE_HASH;
    }
    function _assertCallerIsConduitOwner(address conduit) private view {
        _assertConduitExists(conduit);
        if (msg.sender != _conduits[conduit].owner) {
            revert CallerIsNotOwner(conduit);
        }
    }
    function _assertConduitExists(address conduit) private view {
        if (_conduits[conduit].key == bytes32(0)) {
            revert NoConduit();
        }
    }
}