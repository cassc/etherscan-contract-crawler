// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "../tokenTransferLib/TokenTransferrerConstants.sol";
import "../tokenTransferLib/TokenTransferrerErrors.sol";
import "./LibOrder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface IZeroEx {
    function buyERC721(
        LibOrder.ERC721Order memory sellOrder,
        LibOrder.Signature memory signature,
        bytes memory callbackData
    ) external payable;

    function buyERC1155(
        LibOrder.ERC1155Order memory sellOrder,
        LibOrder.Signature memory signature,
        uint128 erc1155BuyAmount,
        bytes memory callbackData
    ) external payable;

    function batchBuyERC721s(
        LibOrder.ERC721Order[] memory sellOrders,
        LibOrder.Signature[] memory signatures,
        bytes[] memory callbackData,
        bool revertIfIncomplete
    ) external payable;

    function batchBuyERC1155s(
        LibOrder.ERC1155Order[] memory sellOrders,
        LibOrder.Signature[] memory signatures,
        uint128[] calldata erc1155FillAmounts,
        bytes[] memory callbackData,
        bool revertIfIncomplete
    ) external payable;
}

library ZeroExMarket {
    address public constant ZEROEX_EXCHANGE =
        0xDef1C0ded9bec7F1a1670819833240f027b25EfF;

    function buyERC721(
        LibOrder.ERC721Order memory sellOrder,
        LibOrder.Signature memory signature,
        address to
    ) external {
        bytes memory _data = abi.encodeWithSelector(
            IZeroEx.buyERC721.selector,
            sellOrder,
            signature,
            ""
        );

        uint256 orderValue = sellOrder.erc20TokenAmount;

        (bool success, ) = ZEROEX_EXCHANGE.call{value: orderValue}(_data);

        if (!success) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        IERC721Token token = sellOrder.erc721Token;

        _performERC721Transfer(
            address(token),
            address(this),
            to,
            sellOrder.erc721TokenId
        );
    }

    function buyERC1155(
        LibOrder.ERC1155Order memory sellOrder,
        LibOrder.Signature memory signature,
        address to
    ) external {
        bytes memory _data = abi.encodeWithSelector(
            IZeroEx.buyERC1155.selector,
            sellOrder,
            signature,
            sellOrder.erc1155TokenAmount,
            ""
        );

        uint256 orderValue = sellOrder.erc20TokenAmount;

        (bool success, ) = ZEROEX_EXCHANGE.call{value: orderValue}(_data);

        if (!success) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        IERC1155Token token = sellOrder.erc1155Token;

        _performERC1155Transfer(
            address(token),
            address(this),
            to,
            sellOrder.erc1155TokenId,
            sellOrder.erc1155TokenAmount
        );
    }

    function batchBuyERC721s(
        LibOrder.ERC721Order[] memory sellOrders,
        LibOrder.Signature[] memory signatures,
        bytes[] memory callbackData,
        bool revertIfIncomplete,
        address to
    ) external {
        bytes memory _data = abi.encodeWithSelector(
            IZeroEx.batchBuyERC721s.selector,
            sellOrders,
            signatures,
            callbackData,
            revertIfIncomplete
        );

        uint256 orderValue = 0;
        for (uint256 i = 0; i < sellOrders.length; i++) {
            orderValue += sellOrders[i].erc20TokenAmount;
        }

        (bool success, ) = ZEROEX_EXCHANGE.call{value: orderValue}(_data);

        if (!success) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        for (uint256 i = 0; i < sellOrders.length; i++) {
            IERC721Token token = sellOrders[i].erc721Token;

            _performERC721Transfer(
                address(token),
                address(this),
                to,
                sellOrders[i].erc721TokenId
            );
        }
    }

    function batchBuyERC1155s(
        LibOrder.ERC1155Order[] memory sellOrders,
        LibOrder.Signature[] memory signatures,
        uint128[] calldata erc1155FillAmounts,
        bytes[] memory callbackData,
        bool revertIfIncomplete,
        address to
    ) external {
        bytes memory _data = abi.encodeWithSelector(
            IZeroEx.batchBuyERC1155s.selector,
            sellOrders,
            signatures,
            erc1155FillAmounts,
            callbackData,
            revertIfIncomplete
        );

        uint256 orderValue = 0;
        for (uint256 i = 0; i < sellOrders.length; i++) {
            orderValue += sellOrders[i].erc20TokenAmount;
        }

        (bool success, ) = ZEROEX_EXCHANGE.call{value: orderValue}(_data);

        if (!success) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        transfer1155(sellOrders, erc1155FillAmounts, to);
    }

    function transfer1155(
        LibOrder.ERC1155Order[] memory sellOrders,
        uint128[] calldata erc1155FillAmounts,
        address to
    ) internal {
        for (uint256 i = 0; i < sellOrders.length; i++) {
            IERC1155Token token = sellOrders[i].erc1155Token;

            _performERC1155Transfer(
                address(token),
                address(this),
                to,
                sellOrders[i].erc1155TokenId,
                erc1155FillAmounts[i]
            );
        }
    }

    function _performERC721Transfer(
        address token,
        address from,
        address to,
        uint256 identifier
    ) internal {
        // Utilize assembly to perform an optimized ERC721 token transfer.
        assembly {
            // If the token has no code, revert.
            if iszero(extcodesize(token)) {
                mstore(NoContract_error_sig_ptr, NoContract_error_signature)
                mstore(NoContract_error_token_ptr, token)
                revert(NoContract_error_sig_ptr, NoContract_error_length)
            }

            // The free memory pointer memory slot will be used when populating
            // call data for the transfer; read the value and restore it later.
            let memPointer := mload(FreeMemoryPointerSlot)

            // Write call data to memory starting with function selector.
            mstore(ERC721_transferFrom_sig_ptr, ERC721_transferFrom_signature)
            mstore(ERC721_transferFrom_from_ptr, from)
            mstore(ERC721_transferFrom_to_ptr, to)
            mstore(ERC721_transferFrom_id_ptr, identifier)

            // Perform the call, ignoring return data.
            let success := call(
                gas(),
                token,
                0,
                ERC721_transferFrom_sig_ptr,
                ERC721_transferFrom_length,
                0,
                0
            )

            // If the transfer reverted:
            if iszero(success) {
                // If it returned a message, bubble it up as long as sufficient
                // gas remains to do so:
                if returndatasize() {
                    // Ensure that sufficient gas is available to copy
                    // returndata while expanding memory where necessary. Start
                    // by computing word size of returndata & allocated memory.
                    // Round up to the nearest full word.
                    let returnDataWords := div(
                        add(returndatasize(), AlmostOneWord),
                        OneWord
                    )

                    // Note: use the free memory pointer in place of msize() to
                    // work around a Yul warning that prevents accessing msize
                    // directly when the IR pipeline is activated.
                    let msizeWords := div(memPointer, OneWord)

                    // Next, compute the cost of the returndatacopy.
                    let cost := mul(CostPerWord, returnDataWords)

                    // Then, compute cost of new memory allocation.
                    if gt(returnDataWords, msizeWords) {
                        cost := add(
                            cost,
                            add(
                                mul(
                                    sub(returnDataWords, msizeWords),
                                    CostPerWord
                                ),
                                div(
                                    sub(
                                        mul(returnDataWords, returnDataWords),
                                        mul(msizeWords, msizeWords)
                                    ),
                                    MemoryExpansionCoefficient
                                )
                            )
                        )
                    }

                    // Finally, add a small constant and compare to gas
                    // remaining; bubble up the revert data if enough gas is
                    // still available.
                    if lt(add(cost, ExtraGasBuffer), gas()) {
                        // Copy returndata to memory; overwrite existing memory.
                        returndatacopy(0, 0, returndatasize())

                        // Revert, giving memory region with copied returndata.
                        revert(0, returndatasize())
                    }
                }

                // Otherwise revert with a generic error message.
                mstore(
                    TokenTransferGenericFailure_error_sig_ptr,
                    TokenTransferGenericFailure_error_signature
                )
                mstore(TokenTransferGenericFailure_error_token_ptr, token)
                mstore(TokenTransferGenericFailure_error_from_ptr, from)
                mstore(TokenTransferGenericFailure_error_to_ptr, to)
                mstore(TokenTransferGenericFailure_error_id_ptr, identifier)
                mstore(TokenTransferGenericFailure_error_amount_ptr, 1)
                revert(
                    TokenTransferGenericFailure_error_sig_ptr,
                    TokenTransferGenericFailure_error_length
                )
            }

            // Restore the original free memory pointer.
            mstore(FreeMemoryPointerSlot, memPointer)

            // Restore the zero slot to zero.
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
        // Utilize assembly to perform an optimized ERC1155 token transfer.
        assembly {
            // If the token has no code, revert.
            if iszero(extcodesize(token)) {
                mstore(NoContract_error_sig_ptr, NoContract_error_signature)
                mstore(NoContract_error_token_ptr, token)
                revert(NoContract_error_sig_ptr, NoContract_error_length)
            }

            // The following memory slots will be used when populating call data
            // for the transfer; read the values and restore them later.
            let memPointer := mload(FreeMemoryPointerSlot)
            let slot0x80 := mload(Slot0x80)
            let slot0xA0 := mload(Slot0xA0)
            let slot0xC0 := mload(Slot0xC0)

            // Write call data into memory, beginning with function selector.
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

            // Perform the call, ignoring return data.
            let success := call(
                gas(),
                token,
                0,
                ERC1155_safeTransferFrom_sig_ptr,
                ERC1155_safeTransferFrom_length,
                0,
                0
            )

            // If the transfer reverted:
            if iszero(success) {
                // If it returned a message, bubble it up as long as sufficient
                // gas remains to do so:
                if returndatasize() {
                    // Ensure that sufficient gas is available to copy
                    // returndata while expanding memory where necessary. Start
                    // by computing word size of returndata & allocated memory.
                    // Round up to the nearest full word.
                    let returnDataWords := div(
                        add(returndatasize(), AlmostOneWord),
                        OneWord
                    )

                    // Note: use the free memory pointer in place of msize() to
                    // work around a Yul warning that prevents accessing msize
                    // directly when the IR pipeline is activated.
                    let msizeWords := div(memPointer, OneWord)

                    // Next, compute the cost of the returndatacopy.
                    let cost := mul(CostPerWord, returnDataWords)

                    // Then, compute cost of new memory allocation.
                    if gt(returnDataWords, msizeWords) {
                        cost := add(
                            cost,
                            add(
                                mul(
                                    sub(returnDataWords, msizeWords),
                                    CostPerWord
                                ),
                                div(
                                    sub(
                                        mul(returnDataWords, returnDataWords),
                                        mul(msizeWords, msizeWords)
                                    ),
                                    MemoryExpansionCoefficient
                                )
                            )
                        )
                    }

                    // Finally, add a small constant and compare to gas
                    // remaining; bubble up the revert data if enough gas is
                    // still available.
                    if lt(add(cost, ExtraGasBuffer), gas()) {
                        // Copy returndata to memory; overwrite existing memory.
                        returndatacopy(0, 0, returndatasize())

                        // Revert, giving memory region with copied returndata.
                        revert(0, returndatasize())
                    }
                }

                // Otherwise revert with a generic error message.
                mstore(
                    TokenTransferGenericFailure_error_sig_ptr,
                    TokenTransferGenericFailure_error_signature
                )
                mstore(TokenTransferGenericFailure_error_token_ptr, token)
                mstore(TokenTransferGenericFailure_error_from_ptr, from)
                mstore(TokenTransferGenericFailure_error_to_ptr, to)
                mstore(TokenTransferGenericFailure_error_id_ptr, identifier)
                mstore(TokenTransferGenericFailure_error_amount_ptr, amount)
                revert(
                    TokenTransferGenericFailure_error_sig_ptr,
                    TokenTransferGenericFailure_error_length
                )
            }

            mstore(Slot0x80, slot0x80) // Restore slot 0x80.
            mstore(Slot0xA0, slot0xA0) // Restore slot 0xA0.
            mstore(Slot0xC0, slot0xC0) // Restore slot 0xC0.

            // Restore the original free memory pointer.
            mstore(FreeMemoryPointerSlot, memPointer)

            // Restore the zero slot to zero.
            mstore(ZeroSlot, 0)
        }
    }
}