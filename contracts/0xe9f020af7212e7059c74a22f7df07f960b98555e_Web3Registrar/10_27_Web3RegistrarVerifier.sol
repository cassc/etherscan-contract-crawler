// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/LibWeb3Domain.sol";

contract Web3RegistrarVerifier is Ownable, EIP712 {
    address public verifierAddress;

    constructor(address _verifierAddress) EIP712("Web3Registrar", "1") {
        verifierAddress = _verifierAddress;
    }

    function verifyOrder(LibWeb3Domain.Order memory order, bytes memory signature) internal view {
        require(
            SignatureChecker.isValidSignatureNow(
                verifierAddress,
                _hashTypedDataV4(LibWeb3Domain.getHash(order)),
                signature
            ),
            "invalid signature"
        );
    }

    function setVerifierAddress(address newVerifierAddress) external onlyOwner {
        verifierAddress = newVerifierAddress;
    }
}