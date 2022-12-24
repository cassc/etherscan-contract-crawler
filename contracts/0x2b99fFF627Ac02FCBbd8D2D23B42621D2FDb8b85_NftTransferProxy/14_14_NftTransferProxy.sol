// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../interfaces/INftTransferProxy.sol";

contract NftTransferProxy is INftTransferProxy, Initializable, UUPSUpgradeable, OwnableUpgradeable {
    mapping(address => bool) operators;

    function initialize() external initializer {
        __UUPSUpgradeable_init();
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function erc721safeTransferFrom(
        IERC721Upgradeable token,
        address from,
        address to,
        uint256 tokenId
    ) external override onlyOperator {
        _performERC721Transfer(address(token), from, to, tokenId);
    }

    /**
     * @dev Internal function to transfer an ERC721 token from a given
     *      originator to a given recipient. Sufficient approvals must be set on
     *      the contract performing the transfer. Note that this function does
     *      not check whether the receiver can accept the ERC721 token (i.e. it
     *      does not use `safeTransferFrom`). From Seaport.
     *
     * @param token      The ERC721 token to transfer.
     * @param from       The originator of the transfer.
     * @param to         The recipient of the transfer.
     * @param identifier The tokenId to transfer.
     */
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
                mstore(
                    0x0,
                    0x5f15d67200000000000000000000000000000000000000000000000000000000
                ) // abi.encodeWithSignature("NoContract(address)")
                mstore(0x4, token)
                revert(0x0, 0x24) // 0x24 = 36 = 4 (function selector) + 32 (address)
            }

            // The free memory pointer memory slot will be used when populating
            // call data for the transfer; read the value and restore it later.
            let memPointer := mload(0x40)

            // Write call data to memory starting with function selector.
            mstore(0x0, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            // 0x23b872dd = bytes4(keccak256("transferFrom(address,address,uint256)"))
            mstore(0x04, from)
            mstore(0x24, to)
            mstore(0x44, identifier)

            // Perform the call, ignoring return data.
            let success := call(
                gas(),
                token,
                0,
                0x0,
                0x64, // 0x64 = 100 = 4 (function selector) + 32 (address) + 32 (address) + 32 (uint256)
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
                        add(returndatasize(), 0x1f), // 0x1f = 31 = 32 (word size) - 1 (rounding)
                        0x20 // 0x20 = 32 (word size)
                    )

                    // Note: use the free memory pointer in place of msize() to
                    // work around a Yul warning that prevents accessing msize
                    // directly when the IR pipeline is activated.
                    let msizeWords := div(memPointer, 0x20) // 0x20 = 32 (word size)

                    // Next, compute the cost of the returndatacopy.
                    let cost := mul(3, returnDataWords)

                    // Then, compute cost of new memory allocation.
                    if gt(returnDataWords, msizeWords) {
                        cost := add(
                            cost,
                            add(
                                mul(
                                    sub(returnDataWords, msizeWords),
                                    3
                                ),
                                div(
                                    sub(
                                        mul(returnDataWords, returnDataWords),
                                        mul(msizeWords, msizeWords)
                                    ),
                                    0x200 // 0x200 = 512 (word size squared)
                                )
                            )
                        )
                    }

                    // Finally, add a small constant and compare to gas
                    // remaining; bubble up the revert data if enough gas is
                    // still available.
                    if lt(add(cost, 0x20), gas()) {
                        // Copy returndata to memory; overwrite existing memory.
                        returndatacopy(0, 0, returndatasize())

                        // Revert, giving memory region with copied returndata.
                        revert(0, returndatasize())
                    }
                }

                // Otherwise revert with a generic error message.
                mstore(
                    0x0,
                    0xf486bc8700000000000000000000000000000000000000000000000000000000
                )
                // abi.encodeWithSignature(
                //     "TokenTransferGenericFailure(address,address,address,uint256,uint256)"
                // )
                mstore(0x4, token)
                mstore(0x24, from)
                mstore(0x44, to)
                mstore(0x64, identifier)
                mstore(0x84, 1)
                revert(
                    0x0,
                    0xa4 // 0xa4 = 164 = 4 (function selector) + 3 * 32 (address) + 2 * 32 (uint256)
                )
            }

            // Restore the original free memory pointer.
            mstore(0x40, memPointer)

            // Restore the zero slot to zero.
            mstore(0x60, 0)
        }
    }

    function erc1155safeTransferFrom(
        IERC1155Upgradeable token,
        address from,
        address to,
        uint256 id,
        uint256 value
    ) external override onlyOperator {
        // token.safeTransferFrom(from, to, id, value, data);
        _performERC1155Transfer(address(token), from, to, id, value);
    }

    /**
     * @dev Internal function to transfer ERC1155 tokens from a given
     *      originator to a given recipient. Sufficient approvals must be set on
     *      the contract performing the transfer and contract recipients must
     *      implement the ERC1155TokenReceiver interface to indicate that they
     *      are willing to accept the transfer.
     *
     * @param token      The ERC1155 token to transfer.
     * @param from       The originator of the transfer.
     * @param to         The recipient of the transfer.
     * @param identifier The id to transfer.
     * @param amount     The amount to transfer.
     */
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
                // abi.encodeWithSignature("NoContract(address)")
                mstore(0x0, 0x5f15d67200000000000000000000000000000000000000000000000000000000)
                mstore(0x4, token)
                revert(0x0, 0x24) // 0x24 = 36 = 4 (function selector) + 32 (address)
            }

            // The following memory slots will be used when populating call data
            // for the transfer; read the values and restore them later.
            let memPointer := mload(0x40)
            let slot0x80 := mload(0x80)
            let slot0xA0 := mload(0xa0)
            let slot0xC0 := mload(0xc0)

            // Write call data into memory, beginning with function selector.
            mstore(
                0x0,
                0xf242432a00000000000000000000000000000000000000000000000000000000
            )
            // abi.encodeWithSignature(
            //     "safeTransferFrom(address,address,uint256,uint256,bytes)"
            // )
            mstore(0x04, from)
            mstore(0x24, to)
            mstore(0x44, identifier)
            mstore(0x64, amount)
            mstore(
                0x84,
                0xa0
            )
            mstore(0xa4, 0)
            // 0xa4 = 164 = 4 (function selector) + 2 * 32 (address) + 2 * 32 (uint256) + 32 (bytes length)

            // Perform the call, ignoring return data.
            let success := call(
                gas(),
                token,
                0,
                0x0,
                0xc4, // 4 + 32 * 6 == 196
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
                        add(returndatasize(), 0x1f), // 0x1f = 31 = 32 (word size) - 1 (rounding)
                        0x20
                    )

                    // Note: use the free memory pointer in place of msize() to
                    // work around a Yul warning that prevents accessing msize
                    // directly when the IR pipeline is activated.
                    let msizeWords := div(memPointer, 0x20)

                    // Next, compute the cost of the returndatacopy.
                    let cost := mul(3, returnDataWords)

                    // Then, compute cost of new memory allocation.
                    if gt(returnDataWords, msizeWords) {
                        cost := add(
                            cost,
                            add(
                                mul(
                                    sub(returnDataWords, msizeWords),
                                    3
                                ),
                                div(
                                    sub(
                                        mul(returnDataWords, returnDataWords),
                                        mul(msizeWords, msizeWords)
                                    ),
                                    0x200 // 0x200 = 512 (word size squared)
                                )
                            )
                        )
                    }

                    // Finally, add a small constant and compare to gas
                    // remaining; bubble up the revert data if enough gas is
                    // still available.
                    if lt(add(cost, 0x20), gas()) {
                        // Copy returndata to memory; overwrite existing memory.
                        returndatacopy(0, 0, returndatasize())

                        // Revert, giving memory region with copied returndata.
                        revert(0, returndatasize())
                    }
                }

                // Otherwise revert with a generic error message.
                mstore(
                    0x0,
                    0xf486bc8700000000000000000000000000000000000000000000000000000000
                )
                // abi.encodeWithSignature(
                //     "TokenTransferGenericFailure(address,address,address,uint256,uint256)"
                // )
                mstore(0x4, token)
                mstore(0x24, from)
                mstore(0x44, to)
                mstore(0x64, identifier)
                mstore(0x84, amount)
                revert(
                    0x0,
                    0x84 // 0x84 = 132 = 4 (function selector) + 3 * 32 (address) + 2 * 32 (uint256)
                )
            }

            mstore(0x80, slot0x80) // Restore slot 0x80.
            mstore(0xa0, slot0xA0) // Restore slot 0xA0.
            mstore(0xc0, slot0xC0) // Restore slot 0xC0.

            // Restore the original free memory pointer.
            mstore(0x40, memPointer)

            // Restore the zero slot to zero.
            mstore(0x60, 0)
        }
    }

    function addOperator(address operator) external onlyOwner {
        operators[operator] = true;
        emit AddOperator(operator);
    }

    function removeOperator(address operator) external onlyOwner {
        operators[operator] = false;
        emit RemoveOperator(operator);
    }

    modifier onlyOperator() {
        require(operators[_msgSender()], "OperatorRole: caller is not the operator");
        _;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}