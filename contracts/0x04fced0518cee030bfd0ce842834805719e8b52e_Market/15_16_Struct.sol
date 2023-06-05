// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "contracts/lib/Enum.sol";

struct OfferItem {
    ItemType itemType;
    address token;
    uint256 identifierOrCriteria;
    uint256 startAmount;
    uint256 endAmount;
}

struct ConsiderationItem {
    ItemType itemType;
    address token;
    uint256 identifierOrCriteria;
    uint256 startAmount;
    uint256 endAmount;
    address payable recipient;
}

struct OrderParameters {
    address offerer;
    OfferItem[] offer;
    ConsiderationItem[] consideration;
    uint256 startTime;
    uint256 endTime;
    uint256 salt;
    bytes signature;
}

struct OrderComponents {
    address offerer;
    OfferItem[] offer;
    ConsiderationItem[] consideration;
    uint256 startTime;
    uint256 endTime;
    uint256 salt;
    bytes signature;
    uint256 counter;
}

contract OrderParameterBase {
    bytes internal constant _OFFER_ITEM = abi.encodePacked(
        "OfferItem(",
            "uint8 itemType,",
            "address token,",
            "uint256 identifierOrCriteria,",
            "uint256 startAmount,",
            "uint256 endAmount",
        ")"
    );
    bytes32 internal constant _OFFER_ITEM_TYPEHASH = 
        keccak256(
            _OFFER_ITEM
        );

    bytes internal constant _CONSIDERATION_ITEM = abi.encodePacked(
        "ConsiderationItem(",
            "uint8 itemType,",
            "address token,",
            "uint256 identifierOrCriteria,",
            "uint256 startAmount,",
            "uint256 endAmount,",
            "address recipient",
        ")"
    );
    bytes32 internal constant _CONSIDERATION_ITEM_TYPEHASH = 
        keccak256(
            _CONSIDERATION_ITEM
        );

    bytes32 internal constant _ORDER_TYPEHASH = 
        keccak256(
            abi.encodePacked(
                "OrderComponents(",
                    "address offerer,",
                    "OfferItem[] offer,",
                    "ConsiderationItem[] consideration,",
                    "uint256 startTime,",
                    "uint256 endTime,",
                    "uint256 salt,",
                    "uint256 counter",
                ")",
                _CONSIDERATION_ITEM,
                _OFFER_ITEM
            )
        );
    bytes32 internal constant _ORDER_TYPEHASH_NOT_ARRAY = 
        keccak256(
            abi.encodePacked(
                "OrderComponents(",
                    "address offerer,",
                    "OfferItem offer,",
                    "ConsiderationItem consideration,",
                    "uint256 startTime,",
                    "uint256 endTime,",
                    "uint256 salt,",
                    "uint256 counter",
                ")",
                _CONSIDERATION_ITEM,
                _OFFER_ITEM
            )
        );

    

    function _deriveOrderHash(
        OrderParameters memory orderParameters,
        uint256 counter
    ) internal pure returns (bytes32 orderHash) {
        // Designate new memory regions for offer and consideration item hashes.
        bytes32[] memory offerHashes = new bytes32[](
            orderParameters.offer.length
        );
        bytes32[] memory considerationHashes = new bytes32[](
            orderParameters.consideration.length
        );

        // Iterate over each offer on the order.
        for (uint256 i = 0; i < orderParameters.offer.length; ++i) {
            // Hash the offer and place the result into memory.
            offerHashes[i] = _hashOfferItem(orderParameters.offer[i]);
        }

        // Iterate over each consideration on the order.
        for (uint256 i = 0; i < orderParameters.consideration.length; ++i) {
            // Hash the consideration and place the result into memory.
            considerationHashes[i] = _hashConsiderationItem(
                orderParameters.consideration[i]
            );
        }

        // Derive and return the order hash as specified by EIP-712.
        return
            keccak256(
                abi.encode(
                    _ORDER_TYPEHASH,
                    orderParameters.offerer,
                    keccak256(abi.encodePacked(offerHashes)),
                    keccak256(abi.encodePacked(considerationHashes)),
                    orderParameters.startTime,
                    orderParameters.endTime,
                    orderParameters.salt,
                    counter
                )
            );
    }

    function _deriveOrderHash_NotArray(
        OrderParameters memory orderParameters,
        uint256 counter
    ) internal pure returns (bytes32 orderHash) {
        bytes32 offerHash = _hashOfferItem(orderParameters.offer[0]);

        bytes32 considerationHash = _hashConsiderationItem(
            orderParameters.consideration[0]
        );

        // Derive and return the order hash as specified by EIP-712.
        return
            keccak256(
                abi.encode(
                    _ORDER_TYPEHASH_NOT_ARRAY,
                    orderParameters.offerer,
                    offerHash,
                    considerationHash,
                    orderParameters.startTime,
                    orderParameters.endTime,
                    orderParameters.salt,
                    counter
                )
            );
    }

    function _hashOfferItem(
        OfferItem memory offerItem
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _OFFER_ITEM_TYPEHASH,
                    offerItem.itemType,
                    offerItem.token,
                    offerItem.identifierOrCriteria,
                    offerItem.startAmount,
                    offerItem.endAmount
                )
            );
    }

    function _hashConsiderationItem(ConsiderationItem memory considerationItem)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    _CONSIDERATION_ITEM_TYPEHASH,
                    considerationItem.itemType,
                    considerationItem.token,
                    considerationItem.identifierOrCriteria,
                    considerationItem.startAmount,
                    considerationItem.endAmount,
                    considerationItem.recipient
                )
            );
    }
}