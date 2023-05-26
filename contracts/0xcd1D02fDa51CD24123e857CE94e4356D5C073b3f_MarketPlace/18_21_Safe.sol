// SPDX-License-Identifier: UNLICENSED
// Adapted from: https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol

pragma solidity ^0.8.13;

import 'src/interfaces/IERC20.sol';

/**
  @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
  @author Modified from Gnosis (https://github.com/gnosis/gp-v2-contracts/blob/main/src/contracts/libraries/GPv2SafeERC20.sol)
  @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
*/

library Safe {
    /// @param e Erc20 token to execute the call with
    /// @param t To address
    /// @param a Amount being transferred
    function transfer(
        IERC20 e,
        address t,
        uint256 a
    ) internal {
        bool result;

        assembly {
            // Get a pointer to some free memory.
            let pointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(
                pointer,
                0xa9059cbb00000000000000000000000000000000000000000000000000000000
            ) // Begin with the function selector.
            mstore(
                add(pointer, 4),
                and(t, 0xffffffffffffffffffffffffffffffffffffffff)
            ) // Mask and append the "to" argument.
            mstore(add(pointer, 36), a) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            result := call(gas(), e, 0, pointer, 68, 0, 0)
        }

        require(success(result), 'transfer failed');
    }

    /// @param e Erc20 token to execute the call with
    /// @param f From address
    /// @param t To address
    /// @param a Amount being transferred
    function transferFrom(
        IERC20 e,
        address f,
        address t,
        uint256 a
    ) internal {
        bool result;

        assembly {
            // Get a pointer to some free memory.
            let pointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(
                pointer,
                0x23b872dd00000000000000000000000000000000000000000000000000000000
            ) // Begin with the function selector.
            mstore(
                add(pointer, 4),
                and(f, 0xffffffffffffffffffffffffffffffffffffffff)
            ) // Mask and append the "from" argument.
            mstore(
                add(pointer, 36),
                and(t, 0xffffffffffffffffffffffffffffffffffffffff)
            ) // Mask and append the "to" argument.
            mstore(add(pointer, 68), a) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 100 because the calldata length is 4 + 32 * 3.
            result := call(gas(), e, 0, pointer, 100, 0, 0)
        }

        require(success(result), 'transfer from failed');
    }

    /// @notice normalize the acceptable values of true or null vs the unacceptable value of false (or something malformed)
    /// @param r Return value from the assembly `call()` to Erc20['selector']
    function success(bool r) private pure returns (bool) {
        bool result;

        assembly {
            // Get how many bytes the call returned.
            let returnDataSize := returndatasize()

            // If the call reverted:
            if iszero(r) {
                // Copy the revert message into memory.
                returndatacopy(0, 0, returnDataSize)

                // Revert with the same message.
                revert(0, returnDataSize)
            }

            switch returnDataSize
            case 32 {
                // Copy the return data into memory.
                returndatacopy(0, 0, returnDataSize)

                // Set success to whether it returned true.
                result := iszero(iszero(mload(0)))
            }
            case 0 {
                // There was no return data.
                result := 1
            }
            default {
                // It returned some malformed input.
                result := 0
            }
        }

        return result;
    }

    function approve(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(
                freeMemoryPointer,
                0x095ea7b300000000000000000000000000000000000000000000000000000000
            ) // Begin with the function selector.
            mstore(
                add(freeMemoryPointer, 4),
                and(to, 0xffffffffffffffffffffffffffffffffffffffff)
            ) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), 'APPROVE_FAILED');
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function didLastOptionalReturnCallSucceed(bool callStatus)
        private
        pure
        returns (bool)
    {
        bool result;
        assembly {
            // Get how many bytes the call returned.
            let returnDataSize := returndatasize()

            // If the call reverted:
            if iszero(callStatus) {
                // Copy the revert message into memory.
                returndatacopy(0, 0, returnDataSize)

                // Revert with the same message.
                revert(0, returnDataSize)
            }

            switch returnDataSize
            case 32 {
                // Copy the return data into memory.
                returndatacopy(0, 0, returnDataSize)

                // Set success to whether it returned true.
                result := iszero(iszero(mload(0)))
            }
            case 0 {
                // There was no return data.
                result := 1
            }
            default {
                // It returned some malformed input.
                result := 0
            }
        }

        return result;
    }
}