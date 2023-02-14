// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

import "./PackedUint256.sol";
import "./SignificantBit.sol";

/**
🐙🐙🐙🐙🐙🐙🐙🐙🐙🐙🐙🐙🐙🐙🐙🐙

            Octopus Heap
               by Clober

      ⢀⣀⣠⣀⣀⡀
    ⣠⣾⣿⣿⣿⣿⣿⣿⣷⣦⡀
   ⢠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⡀   ⣠⣶⣾⣷⣶⣄
   ⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧  ⢰⣿⠟⠉⠻⣿⣿⣷
   ⠈⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⢷⣄⠘⠿   ⢸⣿⣿⡆
    ⠈⠿⣿⣿⣿⣿⣿⣀⣸⣿⣷⣤⣴⠟    ⢀⣼⣿⣿⠁
      ⠈⠙⣛⣿⣿⣿⣿⣿⣿⣿⣿⣦⣀⣀⣀⣴⣾⣿⣿⡟
   ⢀⣠⣴⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠟⠋⣠⣤⣀
  ⣴⣿⣿⣿⠿⠟⠛⠛⢛⣿⣿⣿⣿⣿⣿⣧⡈⠉⠁   ⠈⠉⢻⣿⣧
 ⣼⣿⣿⠋    ⢠⣾⣿⣿⠟⠉⠻⣿⣿⣿⣦⣄     ⣸⣿⣿⠃
 ⣿⣿⡇     ⣿⣿⡿⠃   ⠈⠛⢿⣿⣿⣿⣿⣶⣿⣿⣿⡿⠋
 ⢿⣿⣧⡀ ⣶⣄⠘⣿⣿⡇  ⠠⠶⣿⣶⡄⠈⠙⠛⠻⠟⠛⠛⠁
 ⠈⠻⣿⣿⣿⣿⠏ ⢻⣿⣿⣄    ⣸⣿⡇
           ⠻⣿⣿⣿⣶⣾⣿⣿⠃
            ⠈⠙⠛⠛⠛⠋

🐙🐙🐙🐙🐙🐙🐙🐙🐙🐙🐙🐙🐙🐙🐙🐙
*/

library OctopusHeap {
    using PackedUint256 for uint256;
    using SignificantBit for uint256;

    error OctopusHeapError(uint256 errorCode);
    uint256 private constant _ALREADY_INITIALIZED_ERROR = 0;
    uint256 private constant _HEAP_EMPTY_ERROR = 1;
    uint256 private constant _ALREADY_EXISTS_ERROR = 2;

    uint8 private constant _BODY_PARTS = 9; // 1 head and 8 arms
    uint256 private constant _INIT_VALUE = 0xed2eb01c00;
    uint16 private constant _HEAD_SIZE = 31; // number of nodes in head
    uint16 private constant _HEAD_SIZE_P = 5;
    uint16 private constant _ROOT_HEAP_INDEX = 1; // root node index

    struct Core {
        uint256[_BODY_PARTS] heap;
        mapping(uint8 => uint256) bitmap;
    }

    function init(Core storage core) internal {
        if (core.heap[0] > 0) {
            revert OctopusHeapError(_ALREADY_INITIALIZED_ERROR);
        }
        for (uint256 i = 0; i < _BODY_PARTS; ++i) {
            core.heap[i] = _INIT_VALUE;
        }
    }

    function has(Core storage core, uint16 value) internal view returns (bool) {
        (uint8 wordIndex, uint8 bitIndex) = _split(value);
        uint256 mask = 1 << bitIndex;
        return core.bitmap[wordIndex] & mask == mask;
    }

    function isEmpty(Core storage core) internal view returns (bool) {
        return core.heap[0] == _INIT_VALUE;
    }

    function getRootWordAndHeap(Core storage core) internal view returns (uint256 word, uint256[] memory heap) {
        heap = new uint256[](9);
        for (uint256 i = 0; i < 9; ++i) {
            heap[i] = core.heap[i];
        }
        word = core.bitmap[uint8(heap[0] >> 8)];
    }

    function _split(uint16 value) private pure returns (uint8 wordIndex, uint8 bitIndex) {
        assembly {
            bitIndex := value
            wordIndex := shr(8, value)
        }
    }

    function _getWordIndex(Core storage core, uint16 heapIndex) private view returns (uint8) {
        if (heapIndex <= _HEAD_SIZE) {
            return core.heap[0].get8Unsafe(heapIndex);
        }
        return core.heap[heapIndex >> _HEAD_SIZE_P].get8Unsafe(heapIndex & _HEAD_SIZE);
    }

    function _getWordIndex(
        uint256 head,
        uint256 arm,
        uint16 heapIndex
    ) private pure returns (uint8) {
        if (heapIndex <= _HEAD_SIZE) {
            return head.get8Unsafe(heapIndex);
        }
        return arm.get8Unsafe(heapIndex & _HEAD_SIZE);
    }

    // returns new values for the part of the heap affected by updating value at heapIndex to new value
    function _updateWordIndex(
        uint256 head,
        uint256 arm,
        uint16 heapIndex,
        uint8 newWordIndex
    ) private pure returns (uint256, uint256) {
        if (heapIndex <= _HEAD_SIZE) {
            return (head.update8Unsafe(heapIndex, newWordIndex), arm);
        } else {
            return (head, arm.update8Unsafe(heapIndex & _HEAD_SIZE, newWordIndex));
        }
    }

    function _root(Core storage core) private view returns (uint8 wordIndex, uint8 bitIndex) {
        wordIndex = uint8(core.heap[0] >> 8);
        uint256 word = core.bitmap[wordIndex];
        bitIndex = word.leastSignificantBit();
    }

    function _convertRawIndexToHeapIndex(uint8 rawIndex) private pure returns (uint16) {
        unchecked {
            uint16 heapIndex = uint16(rawIndex) + 1;
            if (heapIndex <= 35) {
                return heapIndex;
            } else if (heapIndex < 64) {
                return (heapIndex & 3) + ((heapIndex >> 2) << 5) - 224;
            } else if (heapIndex < 128) {
                return (heapIndex & 7) + ((heapIndex >> 3) << 5) - 220;
            } else if (heapIndex < 256) {
                return (heapIndex & 15) + (((heapIndex >> 4)) << 5) - 212;
            } else {
                return 60;
            }
        }
    }

    function _getParentHeapIndex(uint16 heapIndex) private pure returns (uint16 parentHeapIndex) {
        if (heapIndex <= _HEAD_SIZE) {
            // current node and parent node are both on the head
            assembly {
                parentHeapIndex := shr(1, heapIndex)
            }
        } else if (heapIndex & 0x1c == 0) {
            // current node is on an arm but the parent is on the head
            assembly {
                parentHeapIndex := add(add(14, shr(4, heapIndex)), shr(1, and(heapIndex, 2)))
            }
        } else {
            // current node and parent node are both on an arm
            uint16 offset;
            assembly {
                offset := sub(and(heapIndex, 0xffe0), 0x04)
                parentHeapIndex := add(shr(1, sub(heapIndex, offset)), offset)
            }
        }
    }

    function _getLeftChildHeapIndex(uint16 heapIndex) private pure returns (uint16 childHeapIndex) {
        if (heapIndex < 16) {
            // current node and child node are both on the head
            assembly {
                childHeapIndex := shl(1, heapIndex)
            }
        } else if (heapIndex < 32) {
            // current node is on the head but the child is on an arm
            assembly {
                heapIndex := sub(heapIndex, 14)
                childHeapIndex := add(shl(1, and(heapIndex, 1)), shl(5, shr(1, heapIndex)))
            }
        } else {
            // current node and child node are both on an arm
            uint16 offset;
            assembly {
                offset := sub(and(heapIndex, 0xffe0), 0x04)
                childHeapIndex := add(shl(1, sub(heapIndex, offset)), offset)
            }
        }
    }

    function root(Core storage core) internal view returns (uint16) {
        if (isEmpty(core)) {
            revert OctopusHeapError(_HEAP_EMPTY_ERROR);
        }
        (uint8 wordIndex, uint8 bitIndex) = _root(core);
        return (uint16(wordIndex) << 8) | bitIndex;
    }

    function push(Core storage core, uint16 value) internal {
        (uint8 wordIndex, uint8 bitIndex) = _split(value);
        uint256 mask = 1 << bitIndex;

        uint256 word = core.bitmap[wordIndex];
        if (word & mask > 0) {
            revert OctopusHeapError(_ALREADY_EXISTS_ERROR);
        }
        if (word == 0) {
            uint256 head = core.heap[0];
            uint256 arm;
            uint16 heapIndex = _convertRawIndexToHeapIndex(uint8(head)); // uint8() to get length
            uint16 bodyPartIndex;
            if (heapIndex > _HEAD_SIZE) {
                bodyPartIndex = heapIndex >> _HEAD_SIZE_P;
                arm = core.heap[bodyPartIndex];
            }
            while (heapIndex != _ROOT_HEAP_INDEX) {
                uint16 parentHeapIndex = _getParentHeapIndex(heapIndex);
                uint8 parentWordIndex = _getWordIndex(head, arm, parentHeapIndex);
                if (parentWordIndex > wordIndex) {
                    (head, arm) = _updateWordIndex(head, arm, heapIndex, parentWordIndex);
                } else {
                    break;
                }
                heapIndex = parentHeapIndex;
            }
            (head, arm) = _updateWordIndex(head, arm, heapIndex, wordIndex);
            unchecked {
                if (uint8(head) == 255) {
                    core.heap[0] = head - 255; // increment length by 1
                } else {
                    core.heap[0] = head + 1; // increment length by 1
                }
            }
            if (bodyPartIndex > 0) {
                core.heap[bodyPartIndex] = arm;
            }
        }
        core.bitmap[wordIndex] = word | mask;
    }

    function _pop(
        Core storage core,
        uint256 head,
        uint256[] memory arms
    )
        private
        view
        returns (
            uint256,
            uint16,
            uint256
        )
    {
        uint8 newLength;
        uint256 arm;
        uint16 bodyPartIndex;
        unchecked {
            newLength = uint8(head) - 1;
        }
        if (newLength == 0) return (_INIT_VALUE, 0, 0);
        uint16 heapIndex = _convertRawIndexToHeapIndex(newLength);
        uint8 wordIndex = arms.length == 0
            ? _getWordIndex(core, heapIndex)
            : _getWordIndex(head, arms[heapIndex >> _HEAD_SIZE_P], heapIndex);
        heapIndex = 1;
        uint16 childRawIndex = 1;
        uint16 childHeapIndex = 2;
        while (childRawIndex < newLength) {
            uint8 leftChildWordIndex = _getWordIndex(head, arm, childHeapIndex);
            uint8 rightChildWordIndex = _getWordIndex(head, arm, childHeapIndex + 1);
            if (leftChildWordIndex > wordIndex && rightChildWordIndex > wordIndex) {
                break;
            } else if (leftChildWordIndex > rightChildWordIndex) {
                (head, arm) = _updateWordIndex(head, arm, heapIndex, rightChildWordIndex);
                unchecked {
                    heapIndex = childHeapIndex + 1;
                    childRawIndex = (childRawIndex << 1) + 3; // leftChild(childRawIndex + 1)
                }
            } else {
                (head, arm) = _updateWordIndex(head, arm, heapIndex, leftChildWordIndex);
                heapIndex = childHeapIndex;
                unchecked {
                    childRawIndex = (childRawIndex << 1) + 1; // leftChild(childRawIndex)
                }
            }
            childHeapIndex = _getLeftChildHeapIndex(heapIndex);
            // child in arm
            if (childHeapIndex > _HEAD_SIZE && bodyPartIndex == 0) {
                bodyPartIndex = childHeapIndex >> _HEAD_SIZE_P;
                arm = arms.length == 0 ? core.heap[bodyPartIndex] : arms[bodyPartIndex];
            }
        }
        (head, arm) = _updateWordIndex(head, arm, heapIndex, wordIndex);
        unchecked {
            if (uint8(head) == 0) {
                head += 255; // decrement length by 1
            } else {
                --head; // decrement length by 1
            }
        }
        return (head, bodyPartIndex, arm);
    }

    function popInMemory(
        Core storage core,
        uint256 word,
        uint256[] memory heap
    ) internal view returns (uint256, uint256[] memory) {
        uint8 rootBitIndex = word.leastSignificantBit();
        uint256 mask = 1 << rootBitIndex;
        if (word != mask) return (word & (~mask), heap);
        (uint256 head, uint16 bodyPartIndex, uint256 arm) = _pop(core, heap[0], heap);
        heap[0] = head;
        if (head == _INIT_VALUE) return (0, heap);
        if (bodyPartIndex > 0) {
            heap[bodyPartIndex] = arm;
        }
        return (core.bitmap[uint8(head >> 8)], heap);
    }

    function pop(Core storage core) internal {
        (uint8 rootWordIndex, uint8 rootBitIndex) = _root(core);
        uint256 mask = 1 << rootBitIndex;
        uint256 word = core.bitmap[rootWordIndex];
        if (word == mask) {
            (uint256 head, uint16 bodyPartIndex, uint256 arm) = _pop(core, core.heap[0], new uint256[](0));
            core.heap[0] = head;
            if (bodyPartIndex > 0) {
                core.heap[bodyPartIndex] = arm;
            }
        }
        core.bitmap[rootWordIndex] = word & (~mask);
    }
}