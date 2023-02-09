// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library utils {
    function getOwnedIds(
        mapping(uint256 => address) storage ownerMapping,
        address user,
        uint256 collectionSize
    ) internal view returns (uint256[] memory ids) {
        uint256 memPtr;
        uint256 idsLength;

        assembly {
            ids := mload(0x40)
            memPtr := add(ids, 32)
        }

        unchecked {
            uint256 end = collectionSize + 1;
            for (uint256 id = 0; id < end; ++id) {
                if (ownerMapping[id] == user) {
                    assembly {
                        mstore(memPtr, id)
                        memPtr := add(memPtr, 32)
                        idsLength := add(idsLength, 1)
                    }
                }
            }
        }

        assembly {
            mstore(ids, idsLength)
            mstore(0x40, memPtr)
        }
    }

    function balanceOf(
        mapping(uint256 => address) storage ownerMapping,
        address user,
        uint256 collectionSize
    ) internal view returns (uint256 numOwned) {
        unchecked {
            uint256 end = collectionSize + 1;
            address owner;
            for (uint256 id = 0; id < end; ++id) {
                owner = ownerMapping[id];
                assembly {
                    numOwned := add(numOwned, eq(owner, user))
                }
            }
        }
    }

    function indexOf(address[] calldata arr, address addr) internal pure returns (bool found, uint256 index) {
        unchecked {
            for (uint256 i; i < arr.length; ++i) if (arr[i] == addr) return (true, i);
        }
        return (false, 0);
    }
}