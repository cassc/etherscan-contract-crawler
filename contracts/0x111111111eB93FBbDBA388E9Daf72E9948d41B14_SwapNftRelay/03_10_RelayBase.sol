// SPDX-License-Identifier: LicenseRef-Blockwell-Smart-License
pragma solidity ^0.8.9;

import "./ContractGroups.sol";
import "common/Type.sol";

/**
 * @dev Relay contract for verifying crosschain swaps.
 *
 * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
 */
contract RelayBase is ContractGroups, Type {
    struct SwapData {
        bool swapped;
        address[] swappers;
    }

    string public name = "SwapRelay";

    uint256 public swappersNeeded;

    mapping(bytes32 => bool) public swapDone;

    mapping(bytes32 => address[]) internal swaps;

    event Swap(bytes32 indexed swapId, address indexed swapper, uint256 indexed count);
    event SwappersNeededUpdate(uint256 indexed count);

    constructor(uint256 _swappersNeeded) {
        swappersNeeded = _swappersNeeded;
        _addAdmin(msg.sender);

        bwtype = SWAP_RELAY;
        bwver = 85;
    }

    function setSwappersNeeded(uint256 count) public onlyAdmin {
        expect(count > 0, ERROR_BAD_PARAMETER_1);
        swappersNeeded = count;
        emit SwappersNeededUpdate(count);
    }

    function swapsDone(bytes32[] calldata swapIds) public view returns (bool[] memory) {
        bool[] memory done = new bool[](swapIds.length);

        for (uint256 i = 0; i < swapIds.length; i++) {
            done[i] = swapDone[swapIds[i]];
        }

        return done;
    }

    function swapRelayers(bytes32 swapId) public view returns (address[] memory) {
        return swaps[swapId];
    }

    function shouldSwap(bytes32 swapId, address swapper) internal returns (bool) {
        if (swapDone[swapId]) {
            return false;
        }
        address[] storage swappers = swaps[swapId];

        for (uint256 i = 0; i < swappers.length; i++) {
            if (swappers[i] == swapper) {
                return false;
            }
        }

        emit Swap(swapId, swapper, swappers.length + 1);
        if (swappers.length + 1 >= swappersNeeded) {
            swapDone[swapId] = true;
            if (swappers.length > 0) {
                delete swaps[swapId];
            }
            return true;
        }

        swappers.push(swapper);

        return false;
    }
}