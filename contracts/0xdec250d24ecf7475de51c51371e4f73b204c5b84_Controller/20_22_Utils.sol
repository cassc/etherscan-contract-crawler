// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// 5k is plenty for an EXTCODESIZE call (2600) + warm CALL (100)
// and some arithmetic operations.
uint256 constant GAS_FOR_CALL_EXACT_CHECK = 5_000;

function containElement(uint256[] memory arr, uint256 element) pure returns (bool) {
    for (uint256 i = 0; i < arr.length; i++) {
        if (arr[i] == element) {
            return true;
        }
    }
    return false;
}

function containElement(address[] memory arr, address element) pure returns (bool) {
    for (uint256 i = 0; i < arr.length; i++) {
        if (arr[i] == element) {
            return true;
        }
    }
    return false;
}

/**
 * @dev returns the minimum threshold for a group of size groupSize
 */
function minimumThreshold(uint256 groupSize) pure returns (uint256) {
    return groupSize / 2 + 1;
}

/**
 * @dev choose one random index from an array.
 */
function pickRandomIndex(uint256 seed, uint256 length) pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(seed))) % length;
}

/**
 * @dev choose "count" random indices from "indices" array.
 */
function pickRandomIndex(uint256 seed, uint256[] memory indices, uint256 count) pure returns (uint256[] memory) {
    uint256[] memory chosenIndices = new uint256[](count);

    // Create copy of indices to avoid modifying original array.
    uint256[] memory remainingIndices = new uint256[](indices.length);
    for (uint256 i = 0; i < indices.length; i++) {
        remainingIndices[i] = indices[i];
    }

    uint256 remainingCount = remainingIndices.length;
    for (uint256 i = 0; i < count; i++) {
        uint256 index = uint256(keccak256(abi.encodePacked(seed, i))) % remainingCount;
        chosenIndices[i] = remainingIndices[index];
        remainingIndices[index] = remainingIndices[remainingCount - 1];
        remainingCount--;
    }
    return chosenIndices;
}

/**
 * @dev iterates through list of members and remove disqualified nodes.
 */
function getNonDisqualifiedMajorityMembers(address[] memory nodeAddresses, address[] memory disqualifiedNodes)
    pure
    returns (address[] memory)
{
    address[] memory majorityMembers = new address[](nodeAddresses.length);
    uint256 majorityMembersLength = 0;
    for (uint256 i = 0; i < nodeAddresses.length; i++) {
        if (!containElement(disqualifiedNodes, nodeAddresses[i])) {
            majorityMembers[majorityMembersLength] = nodeAddresses[i];
            majorityMembersLength++;
        }
    }

    // remove trailing zero addresses
    return trimTrailingElements(majorityMembers, majorityMembersLength);
}

function trimTrailingElements(uint256[] memory arr, uint256 newLength) pure returns (uint256[] memory) {
    uint256[] memory output = new uint256[](newLength);
    for (uint256 i = 0; i < newLength; i++) {
        output[i] = arr[i];
    }
    return output;
}

function trimTrailingElements(address[] memory arr, uint256 newLength) pure returns (address[] memory) {
    address[] memory output = new address[](newLength);
    for (uint256 i = 0; i < newLength; i++) {
        output[i] = arr[i];
    }
    return output;
}

/**
 * @dev calls target address with exactly gasAmount gas and data as calldata
 * or reverts if at least gasAmount gas is not available.
 */
function callWithExactGas(uint256 gasAmount, address target, bytes memory data) returns (bool success) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
        let g := gas()
        // Compute g -= GAS_FOR_CALL_EXACT_CHECK and check for underflow
        // The gas actually passed to the callee is min(gasAmount, 63//64*gas available).
        // We want to ensure that we revert if gasAmount >  63//64*gas available
        // as we do not want to provide them with less, however that check itself costs
        // gas.  GAS_FOR_CALL_EXACT_CHECK ensures we have at least enough gas to be able
        // to revert if gasAmount >  63//64*gas available.
        if lt(g, GAS_FOR_CALL_EXACT_CHECK) { revert(0, 0) }
        g := sub(g, GAS_FOR_CALL_EXACT_CHECK)
        // if g - g//64 <= gasAmount, revert
        // (we subtract g//64 because of EIP-150)
        if iszero(gt(sub(g, div(g, 64)), gasAmount)) { revert(0, 0) }
        // solidity calls check that a contract actually exists at the destination, so we do the same
        if iszero(extcodesize(target)) { revert(0, 0) }
        // call and return whether we succeeded. ignore return data
        // call(gas,addr,value,argsOffset,argsLength,retOffset,retLength)
        success := call(gasAmount, target, 0, add(data, 0x20), mload(data), 0, 0)
    }
    return success;
}