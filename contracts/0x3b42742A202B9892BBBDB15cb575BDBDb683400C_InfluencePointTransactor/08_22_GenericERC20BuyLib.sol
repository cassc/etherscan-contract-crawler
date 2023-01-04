//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

library GenericERC20BuyLib {
    using ECDSA for bytes32;

    struct GenericERC20Buy {
        address sender;
        address signer;
        address paymentToken;
        uint256 nonce;
        uint256 totalPrice;
        uint256 purchaseId;
        uint256 amount;
        uint256 timestamp;
        bytes signature;
    }

    function getSigner(
        GenericERC20Buy memory self,
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
        GenericERC20Buy memory self,
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
                    self.nonce,
                    self.paymentToken,
                    self.totalPrice,
                    self.purchaseId,
                    self.amount,
                    self.timestamp,
                    chainId
                )
            );
    }
}