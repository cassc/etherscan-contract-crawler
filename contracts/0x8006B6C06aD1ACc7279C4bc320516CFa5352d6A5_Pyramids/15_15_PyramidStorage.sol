// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

library PyramidStorage {
    struct TokenSlot {
        uint16 tokenId;
        bool occupied;
    }

    struct Layout {
        mapping(uint16 => TokenSlot[4]) pyramidToSlots;
        address itemsContract;
        string contractURI;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("grizzly.contracts.storage.Pyramid");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function setItemsContract(
        Layout storage l,
        address _itemsContract
    ) internal {
        l.itemsContract = _itemsContract;
    }

    function setContractURI(
        Layout storage l,
        string memory _contractURI
    ) internal {
        l.contractURI = _contractURI;
    }
}