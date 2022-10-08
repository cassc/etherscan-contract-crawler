//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
    @dev This V3 supports the type id field for the ERC1155 tokens.
 */
library GenericBuyV3Lib {
    using ECDSA for bytes32;

    struct GenericBuyV3 {
        address sender;
        address signer;
        address paymentToken;
        address nft;
        uint256 nonce;
        uint256 totalPrice;
        uint256 purchaseId;
        uint256 amount;
        uint256 timestamp;
        uint256 typeId;
        bytes signature;
    }

    function getSigner(
        GenericBuyV3 memory self,
        address sender,
        address transactor,
        uint256 chainId
    ) internal pure returns (address) {
        require(self.sender == sender, "!msg_sender");
        bytes32 hash = hashRequest(self, sender, transactor, chainId);
        bytes32 messageHash = hash.toEthSignedMessageHash();
        return messageHash.recover(self.signature);
    }

    function hashRequest(
        GenericBuyV3 memory self,
        address sender,
        address transactor,
        uint256 chainId
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    sender,
                    transactor,
                    self.signer,
                    self.nft,
                    self.nonce,
                    self.paymentToken,
                    self.totalPrice,
                    self.purchaseId,
                    self.typeId,
                    self.amount,
                    self.timestamp,
                    chainId
                )
            );
    }
}