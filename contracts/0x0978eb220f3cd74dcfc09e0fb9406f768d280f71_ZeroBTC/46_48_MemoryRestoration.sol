// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.13;

contract MemoryRestoration {
  modifier RestoreOneWord(uint256 slot1) {
    uint256 cachedValue;
    assembly {
      cachedValue := mload(slot1)
    }
    _;
    assembly {
      mstore(slot1, cachedValue)
    }
  }

  modifier RestoreTwoWords(uint256 slot1, uint256 slot2) {
    uint256 cachedValue1;
    uint256 cachedValue2;
    assembly {
      cachedValue1 := mload(slot1)
      cachedValue2 := mload(slot2)
    }
    _;
    assembly {
      mstore(slot1, cachedValue1)
      mstore(slot2, cachedValue2)
    }
  }

  modifier RestoreThreeWords(
    uint256 slot1,
    uint256 slot2,
    uint256 slot3
  ) {
    uint256 cachedValue1;
    uint256 cachedValue2;
    uint256 cachedValue3;
    assembly {
      cachedValue1 := mload(slot1)
      cachedValue2 := mload(slot2)
      cachedValue3 := mload(slot3)
    }
    _;
    assembly {
      mstore(slot1, cachedValue1)
      mstore(slot2, cachedValue2)
      mstore(slot3, cachedValue3)
    }
  }

  modifier RestoreFourWords(
    uint256 slot1,
    uint256 slot2,
    uint256 slot3,
    uint256 slot4
  ) {
    uint256 cachedValue1;
    uint256 cachedValue2;
    uint256 cachedValue3;
    uint256 cachedValue4;
    assembly {
      cachedValue1 := mload(slot1)
      cachedValue2 := mload(slot2)
      cachedValue3 := mload(slot3)
      cachedValue4 := mload(slot4)
    }
    _;
    assembly {
      mstore(slot1, cachedValue1)
      mstore(slot2, cachedValue2)
      mstore(slot3, cachedValue3)
      mstore(slot4, cachedValue4)
    }
  }

  modifier RestoreFourWordsBefore(bytes memory data) {
    uint256 cachedValue1;
    uint256 cachedValue2;
    uint256 cachedValue3;
    uint256 cachedValue4;
    assembly {
      cachedValue1 := mload(sub(data, 0x20))
      cachedValue2 := mload(sub(data, 0x40))
      cachedValue3 := mload(sub(data, 0x60))
      cachedValue4 := mload(sub(data, 0x80))
    }
    _;
    assembly {
      mstore(sub(data, 0x20), cachedValue1)
      mstore(sub(data, 0x40), cachedValue2)
      mstore(sub(data, 0x60), cachedValue3)
      mstore(sub(data, 0x80), cachedValue4)
    }
  }

  modifier RestoreFirstTwoUnreservedSlots() {
    uint256 cachedValue1;
    uint256 cachedValue2;
    assembly {
      cachedValue1 := mload(0x80)
      cachedValue2 := mload(0xa0)
    }
    _;
    assembly {
      mstore(0x80, cachedValue1)
      mstore(0xa0, cachedValue2)
    }
  }

  modifier RestoreFreeMemoryPointer() {
    uint256 freeMemoryPointer;
    assembly {
      freeMemoryPointer := mload(0x40)
    }
    _;
    assembly {
      mstore(0x40, freeMemoryPointer)
    }
  }

  modifier RestoreZeroSlot() {
    _;
    assembly {
      mstore(0x60, 0)
    }
  }
}