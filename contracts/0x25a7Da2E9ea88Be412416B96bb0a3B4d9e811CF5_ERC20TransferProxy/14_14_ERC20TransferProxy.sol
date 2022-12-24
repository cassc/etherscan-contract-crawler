// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../interfaces/IERC20TransferProxy.sol";

contract ERC20TransferProxy is IERC20TransferProxy, Initializable, UUPSUpgradeable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    mapping(address => bool) operators;

    function initialize() external initializer {
        __UUPSUpgradeable_init();
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function erc20safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) external override onlyOperator {
        _performERC20Transfer(address(token), from, to, value);
    }

    /**
     * @dev Internal function to transfer ERC20 tokens from a given originator
     *      to a given recipient. Sufficient approvals must be set on the
     *      contract performing the transfer. From Seaport codebase.
     *
     * @param token      The ERC20 token to transfer.
     * @param from       The originator of the transfer.
     * @param to         The recipient of the transfer.
     * @param amount     The amount to transfer.
     */
    function _performERC20Transfer(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        // Utilize assembly to perform an optimized ERC20 token transfer.
        assembly {
            // The free memory pointer memory slot will be used when populating
            // call data for the transfer; read the value and restore it later.
            let memPointer := mload(0x40) // 0x40 is the "free memory pointer"

            // Write call data into memory, starting with function selector.
            mstore(
                0x0, 
                0x23b872dd00000000000000000000000000000000000000000000000000000000
            ) // 0x23b872dd = keccak256("transfer(address,uint256)")
            mstore(0x04, from) // Write the originator address.
            mstore(0x24, to) // Write the recipient address.
            mstore(0x44, amount) // Write the amount to transfer.

            // Make call & copy up to 32 bytes of return data to scratch space.
            // Scratch space does not need to be cleared ahead of time, as the
            // subsequent check will ensure that either at least a full word of
            // return data is received (in which case it will be overwritten) or
            // that no data is received (in which case scratch space will be
            // ignored) on a successful call to the given token.
            let callStatus := call(
                gas(),
                token,
                0,
                0x0,
                0x64, // 0x64 = 100 = 4 (function selector) + 32 * 2 (addresses) + 32 (amount)
                0,
                0x20 // 0x20 = 32 = 32 bytes of return data
            )

            // Determine whether transfer was successful using status & result.
            let success := and(
                // Set success to whether the call reverted, if not check it
                // either returned exactly 1 (can't just be non-zero data), or
                // had no return data.
                or(
                    and(eq(mload(0), 1), gt(returndatasize(), 31)),
                    iszero(returndatasize())
                ),
                callStatus
            )

            // Handle cases where either the transfer failed or no data was
            // returned. Group these, as most transfers will succeed with data.
            // Equivalent to `or(iszero(success), iszero(returndatasize()))`
            // but after it's inverted for JUMPI this expression is cheaper.
            if iszero(and(success, iszero(iszero(returndatasize())))) {
                // If the token has no code or the transfer failed: Equivalent
                // to `or(iszero(success), iszero(extcodesize(token)))` but
                // after it's inverted for JUMPI this expression is cheaper.
                if iszero(and(iszero(iszero(extcodesize(token))), success)) {
                    // If the transfer failed:
                    if iszero(success) {
                        // If it was due to a revert:
                        if iszero(callStatus) {
                            // If it returned a message, bubble it up as long as
                            // sufficient gas remains to do so:
                            if returndatasize() {
                                // Ensure that sufficient gas is available to
                                // copy returndata while expanding memory where
                                // necessary. Start by computing the word size
                                // of returndata and allocated memory. Round up
                                // to the nearest full word.
                                let returnDataWords := div(
                                    add(returndatasize(), 0x1f), // 0x1f = 31
                                    0x20 // 0x20 = 32
                                )

                                // Note: use the free memory pointer in place of
                                // msize() to work around a Yul warning that
                                // prevents accessing msize directly when the IR
                                // pipeline is activated.
                                let msizeWords := div(memPointer, 0x20) // 0x20 = 32

                                // Next, compute the cost of the returndatacopy.
                                let cost := mul(3, returnDataWords) // 3 = 3 words of gas

                                // Then, compute cost of new memory allocation.
                                if gt(returnDataWords, msizeWords) {
                                    cost := add(
                                        cost,
                                        add(
                                            mul(
                                                sub(
                                                    returnDataWords,
                                                    msizeWords
                                                ),
                                                3 // 3 = 3 words of gas
                                            ),
                                            div(
                                                sub(
                                                    mul(
                                                        returnDataWords,
                                                        returnDataWords
                                                    ),
                                                    mul(msizeWords, msizeWords)
                                                ),
                                                0x200 // 0x200 = 512
                                            )
                                        )
                                    )
                                }

                                // Finally, add a small constant and compare to
                                // gas remaining; bubble up the revert data if
                                // enough gas is still available.
                                if lt(add(cost, 0x20), gas()) { // 0x20 = 32
                                    // Copy returndata to memory; overwrite
                                    // existing memory.
                                    returndatacopy(0, 0, returndatasize())

                                    // Revert, specifying memory region with
                                    // copied returndata.
                                    revert(0, returndatasize())
                                }
                            }

                            // Otherwise revert with a generic error message.
                            mstore(
                                0x0, // TokenTransferGenericFailure_error_sig_ptr
                                0xf486bc8700000000000000000000000000000000000000000000000000000000
                                // abi.encodeWithSignature(
                                //     "TokenTransferGenericFailure(address,address,address,uint256,uint256)"
                                // )
                            )
                            mstore(
                                0x4,
                                token
                            )
                            mstore(
                                0x24,
                                from
                            )
                            mstore(0x44, to)
                            mstore(0x64, 0)
                            mstore(
                                0x84,
                                amount
                            )
                            revert(
                                0x0,
                                0xa4 // 0xa4 = 164 = 4 (function selector) + 32 * 3 (addresses) + 32 * 2 (amounts)
                            )
                        }

                        // Otherwise revert with a message about the token
                        // returning false or non-compliant return values.
                        mstore(
                            0x0,
                            0x9889192300000000000000000000000000000000000000000000000000000000
                            // abi.encodeWithSignature(
                            //     "BadReturnValueFromERC20OnTransfer(address,address,address,uint256)"
                            // )
                        )
                        mstore(
                            0x4,
                            token
                        )
                        mstore(
                            0x24,
                            from
                        )
                        mstore(
                            0x44,
                            to
                        )
                        mstore(
                            0x64,
                            amount
                        )
                        revert(
                            0x0,
                            0x84 // 0x84 = 132 = 4 (function selector) + 32 * 3 (addresses) + 32 (amount)
                        )
                    }

                    // Otherwise, revert with error about token not having code:
                    mstore(0x0, 0x5f15d67200000000000000000000000000000000000000000000000000000000)
                    // abi.encodeWithSignature("NoContract(address)")
                    mstore(0x4, token)
                    revert(0x0, 0x24) // 0x24 = 36 = 4 (function selector) + 32 (address)
                }

                // Otherwise, the token just returned no data despite the call
                // having succeeded; no need to optimize for this as it's not
                // technically ERC20 compliant.
            }

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