// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "../tokenTransferLib/TokenTransferrerConstants.sol";
import "../tokenTransferLib/TokenTransferrerErrors.sol";
import "./OrderType.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "hardhat/console.sol";

interface IX2Y2Run {
    function run(OrderType.RunInput memory input) external payable;
}

library X2Y21155Market {
    address public constant X2Y2_EXCHANGE =
        0x74312363e45DCaBA76c59ec49a7Aa8A65a67EeD3;

    struct Pair {
        IERC1155 token;
        uint256 tokenId;
        uint256 amount;
    }

    function run(bytes memory _entryData) external {
        console.log("Calling the function");

        OrderType.RunInput memory input;
        address to;
        (input, to) = abi.decode(_entryData, (OrderType.RunInput, address));

        console.logAddress(to);

        bytes memory _data = abi.encodeWithSelector(
            IX2Y2Run.run.selector,
            input
        );

        uint256 totalPrice;

        for (uint256 i = 0; i < input.details.length; i++) {
            totalPrice += input.details[i].price;
        }

        (bool success, ) = X2Y2_EXCHANGE.call{value: totalPrice}(_data);
        console.log("Success => ", success);
        if (!success) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        } else {
            for (uint256 i = 0; i < input.details.length; i++) {
                bytes memory tokenInfo = input
                    .orders[input.details[i].orderIdx]
                    .items[input.details[i].itemIdx]
                    .data;
                Pair[] memory pairs = abi.decode(tokenInfo, (Pair[]));

                for (uint256 k = 0; k < pairs.length; k++) {
                    Pair memory p = pairs[k];

                    _performERC1155Transfer(
                        address(p.token),
                        address(this),
                        to,
                        p.tokenId,
                        p.amount
                    );
                }
            }
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

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) external pure returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }
}

//0xFF57E60128Fd7cE671055Af6810B46Ed193C3852
//https://etherscan.io/address/0x038361923BED5473F148A2B6D4ff4858c5A92ad6#code  // trabalhando com esse