// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ERC721MLibrary.sol";
import {ERC721M, s} from "../ERC721M.sol";

/// @title ERC721M Query Extension
/// @author phaze (https://github.com/0xPhaze/ERC721M)
abstract contract ERC721MQuery is ERC721M {
    using UserDataOps for uint256;
    using TokenDataOps for uint256;

    /* ------------- O(n) read-only ------------- */

    function getOwnedIds(address user) external view returns (uint256[] memory) {
        return utils.getOwnedIds(s().tokenData, user, startingIndex, totalSupply());
    }

    function getLockedIds(address user) external view returns (uint256[] memory) {
        return utils.getLockedIds(s().tokenData, user, startingIndex, totalSupply());
    }

    function getUnlockedIds(address user) external view returns (uint256[] memory) {
        return utils.getUnlockedIds(s().tokenData, user, startingIndex, totalSupply());
    }

    function totalNumLocked() external view returns (uint256) {
        uint256 data;
        uint256 count;
        uint256 endIndex = _nextTokenId();
        uint256 currentData;

        unchecked {
            for (uint256 i = startingIndex; i < endIndex; ++i) {
                data = s().tokenData[i];
                if (data != 0) currentData = data;
                if (currentData.locked()) ++count;
            }
        }

        return count;
    }
}

/// @title ERC721M Query Utils
/// @author phaze (https://github.com/0xPhaze/ERC721M)
library utils {
    using TokenDataOps for uint256;

    function getOwnedIds(
        mapping(uint256 => uint256) storage tokenDataOf,
        address user,
        uint256 start,
        uint256 collectionSize
    ) internal view returns (uint256[] memory ids) {
        uint256 memPtr;

        assembly {
            ids := mload(0x40)
            memPtr := add(ids, 0x20)
        }

        unchecked {
            uint256 data;
            uint256 currentData;
            uint256 end = collectionSize + start;
            for (uint256 id = start; id < end; ++id) {
                data = tokenDataOf[id];
                if (data != 0) currentData = data;
                if (user == address(uint160(currentData))) {
                    assembly {
                        mstore(memPtr, id)
                        memPtr := add(memPtr, 0x20)
                    }
                }
            }
        }

        assembly {
            mstore(ids, shr(5, sub(sub(memPtr, ids), 0x20)))
            mstore(0x40, memPtr)
        }
    }

    function getLockedIds(
        mapping(uint256 => uint256) storage tokenDataOf,
        address user,
        uint256 start,
        uint256 collectionSize
    ) internal view returns (uint256[] memory ids) {
        uint256 memPtr;

        assembly {
            ids := mload(0x40)
            memPtr := add(ids, 0x20)
        }

        unchecked {
            uint256 data;
            uint256 currentData;
            uint256 end = collectionSize + start;
            for (uint256 id = start; id < end; ++id) {
                data = tokenDataOf[id];
                if (data != 0) currentData = data;
                if (user == address(uint160(currentData)) && currentData.locked()) {
                    assembly {
                        mstore(memPtr, id)
                        memPtr := add(memPtr, 0x20)
                    }
                }
            }
        }

        assembly {
            mstore(ids, shr(5, sub(sub(memPtr, ids), 0x20)))
            mstore(0x40, memPtr)
        }
    }

    function getUnlockedIds(
        mapping(uint256 => uint256) storage tokenDataOf,
        address user,
        uint256 start,
        uint256 collectionSize
    ) internal view returns (uint256[] memory ids) {
        uint256 memPtr;

        assembly {
            ids := mload(0x40)
            memPtr := add(ids, 0x20)
        }

        unchecked {
            uint256 data;
            uint256 currentData;
            uint256 end = collectionSize + start;
            for (uint256 id = start; id < end; ++id) {
                data = tokenDataOf[id];
                if (data != 0) currentData = data;
                if (user == address(uint160(currentData)) && !currentData.locked()) {
                    assembly {
                        mstore(memPtr, id)
                        memPtr := add(memPtr, 0x20)
                    }
                }
            }
        }

        assembly {
            mstore(ids, shr(5, sub(sub(memPtr, ids), 0x20)))
            mstore(0x40, memPtr)
        }
    }
}