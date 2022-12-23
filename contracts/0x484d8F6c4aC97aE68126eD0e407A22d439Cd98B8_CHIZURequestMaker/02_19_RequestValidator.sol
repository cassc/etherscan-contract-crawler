// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./RequestCore.sol";

import "../interfaces/INodeRole.sol";
import "hardhat/console.sol";

abstract contract RequestValidator is RequestCore {
    using ECDSA for bytes32;

    /**
     * @dev The internal function that validate register signature of users and node for currency
     */
    function _validateRegisterWithCurrencySignature(
        uint8 requestStatus,
        OrderInfo memory orderInfo,
        CurrencyInfo memory currencyInfo,
        UserValidate memory userValidate,
        NodeValidate memory nodeValidate
    ) internal view returns (bool success, string memory message) {
        if (!INodeRole(core).isNode(nodeValidate.nodeAddress)) {
            return (false, "ReqeustValidator : is not node");
        }

        string memory prefix = "I agree to request policy\n\n[Hash]\n";

        bytes32 creatorHash;
        bytes32 requesterHash;
        /**
         * ==================
         * Creator
         * ==================
         */
        {
            creatorHash = keccak256(
                abi.encodePacked(
                    uint256(orderInfo.creatorSalt),
                    uint256(uint160(orderInfo.creatorAccount)),
                    uint256(uint160(orderInfo.collectionAddress)),
                    uint256(orderInfo.policy)
                )
            );

            string memory creatorHashString = Strings.toHexString(
                uint256(creatorHash)
            );
            string memory creatorSignedMessage = string(
                abi.encodePacked(prefix, creatorHashString)
            );

            bytes32 creatorOrigin = keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n100",
                    creatorSignedMessage
                )
            );

            address creatorSigner = creatorOrigin.recover(
                userValidate.creatorSignature
            );

            if (creatorHash != userValidate.creatorHash) {
                return (
                    false,
                    "ReqeustValidator : creator hash does not match"
                );
            }
            if (creatorSigner != orderInfo.creatorAccount) {
                return (
                    false,
                    "ReqeustValidator : creator signer does not match"
                );
            }
        }

        /**
         * ==================
         * Requester
         * ==================
         */
        {
            requesterHash = keccak256(
                abi.encodePacked(
                    uint256(creatorHash),
                    uint256(orderInfo.requesterSalt),
                    uint256(uint160(orderInfo.requesterAccount)),
                    uint256(uint160(currencyInfo.currencyAddress)),
                    uint256(currencyInfo.price)
                )
            );

            string memory requesterHashString = Strings.toHexString(
                uint256(requesterHash)
            );

            string memory requesterSignedMessage = string(
                abi.encodePacked(prefix, requesterHashString)
            );

            bytes32 requesterOrigin = keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n100",
                    requesterSignedMessage
                )
            );

            address requesterSigner = requesterOrigin.recover(
                userValidate.requesterSignature
            );

            if (requesterHash != userValidate.requesterHash) {
                return (
                    false,
                    "ReqeustValidator : requester hash does not match"
                );
            }
            if (requesterSigner != orderInfo.requesterAccount) {
                return (
                    false,
                    "ReqeustValidator : requester signer does not match"
                );
            }
        }

        /**
         * ==================
         * Node
         * ==================
         */
        {
            bytes32 nodeHash = keccak256(
                abi.encodePacked(
                    uint256(uint8(requestStatus)),
                    uint256(creatorHash),
                    uint256(requesterHash),
                    uint256(nodeValidate.expiredAt)
                )
            );

            bytes32 nodeOrigin = nodeHash.toEthSignedMessageHash();
            address nodeSigner = nodeOrigin.recover(nodeValidate.signature);

            if (nodeHash != nodeValidate.hashValue) {
                return (false, "ReqeustValidator : node hash does not match");
            }
            if (nodeSigner != nodeValidate.nodeAddress) {
                return (false, "ReqeustValidator : node signer does not match");
            }
        }

        success = true;
    }

    /**
     * @dev The internal function that validate register signature of users and node for nft
     */
    function _validateRegisterWithNFTSignature(
        uint8 requestStatus,
        OrderInfo memory orderInfo,
        NFTInfo memory nftInfo,
        UserValidate memory userValidate,
        NodeValidate memory nodeValidate
    ) internal view returns (bool success, string memory message) {
        if (!INodeRole(core).isNode(nodeValidate.nodeAddress)) {
            return (false, "ReqeustValidator : is not node");
        }

        string memory prefix = "I agree to request policy\n\n[Hash]\n";

        bytes32 creatorHash;
        bytes32 requesterHash;

        /**
         * ==================
         * Creator
         * ==================
         */
        {
            creatorHash = keccak256(
                abi.encodePacked(
                    uint256(orderInfo.creatorSalt),
                    uint256(uint160(orderInfo.creatorAccount)),
                    uint256(uint160(orderInfo.collectionAddress)),
                    uint256(orderInfo.policy)
                )
            );

            string memory creatorHashString = Strings.toHexString(
                uint256(creatorHash)
            );
            string memory creatorSignedMessage = string(
                abi.encodePacked(prefix, creatorHashString)
            );

            bytes32 creatorOrigin = keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n100",
                    creatorSignedMessage
                )
            );

            address creatorSigner = creatorOrigin.recover(
                userValidate.creatorSignature
            );

            if (creatorHash != userValidate.creatorHash) {
                return (
                    false,
                    "ReqeustValidator : creator hash does not match"
                );
            }
            if (creatorSigner != orderInfo.creatorAccount) {
                return (
                    false,
                    "ReqeustValidator : creator signer does not match"
                );
            }
        }

        /**
         * ==================
         * Requester
         * ==================
         */
        {
            requesterHash = keccak256(
                abi.encodePacked(
                    uint256(creatorHash),
                    uint256(orderInfo.requesterSalt),
                    uint256(uint160(orderInfo.requesterAccount)),
                    uint256(uint160(nftInfo.collectionAddress)),
                    uint256(nftInfo.tokenId),
                    uint256(nftInfo.amount)
                )
            );

            string memory requesterHashString = Strings.toHexString(
                uint256(requesterHash)
            );

            string memory requesterSignedMessage = string(
                abi.encodePacked(prefix, requesterHashString)
            );

            bytes32 requesterOrigin = keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n100",
                    requesterSignedMessage
                )
            );

            address requesterSigner = requesterOrigin.recover(
                userValidate.requesterSignature
            );

            if (requesterHash != userValidate.requesterHash) {
                return (
                    false,
                    "ReqeustValidator : requester hash does not match"
                );
            }
            if (requesterSigner != orderInfo.requesterAccount) {
                return (
                    false,
                    "ReqeustValidator : requester signer does not match"
                );
            }
        }

        /**
         * ==================
         * Node
         * ==================
         */
        {
            bytes32 nodeHash = keccak256(
                abi.encodePacked(
                    uint256(uint8(requestStatus)),
                    uint256(creatorHash),
                    uint256(requesterHash),
                    uint256(nodeValidate.expiredAt)
                )
            );

            bytes32 nodeOrigin = nodeHash.toEthSignedMessageHash();
            address nodeSigner = nodeOrigin.recover(nodeValidate.signature);

            if (nodeHash != nodeValidate.hashValue) {
                return (false, "ReqeustValidator : node hash does not match");
            }
            if (nodeSigner != nodeValidate.nodeAddress) {
                return (false, "ReqeustValidator : node signer does not match");
            }
        }

        success = true;
    }

    /**
     * @dev The internal function that validate delivery signature of user and node
     */
    function _validateDeliverySignature(
        uint8 requestStatus,
        RequestInfo memory requestInfo,
        LazyNFTInfo memory lazyNFTInfo,
        NodeValidate memory nodeValidate
    ) internal view returns (bool success, string memory message) {
        if (!INodeRole(core).isNode(nodeValidate.nodeAddress)) {
            return (false, "ReqeustValidator : is not node");
        }
        bytes32 calculatedHash = keccak256(
            abi.encodePacked(
                uint256(uint8(requestStatus)),
                uint256(uint160(requestInfo.creatorAccount)),
                uint256(uint160(requestInfo.requesterAccount)),
                uint256(uint160(requestInfo.contractAddress)),
                uint256(requestInfo.value),
                uint256(requestInfo.amount),
                uint256(uint160(lazyNFTInfo.collectionAddress)),
                uint256(lazyNFTInfo.policy),
                lazyNFTInfo.uri,
                uint256(nodeValidate.expiredAt)
            )
        );

        bytes32 calculatedOrigin = calculatedHash.toEthSignedMessageHash();

        address recoveredSigner = calculatedOrigin.recover(
            nodeValidate.signature
        );

        if (calculatedHash != nodeValidate.hashValue) {
            return (false, "ReqeustValidator : hash does not match");
        }
        if (recoveredSigner != nodeValidate.nodeAddress) {
            return (false, "ReqeustValidator : signer does not match");
        }
        success = true;
    }

    uint256[1000] private __gap;
}