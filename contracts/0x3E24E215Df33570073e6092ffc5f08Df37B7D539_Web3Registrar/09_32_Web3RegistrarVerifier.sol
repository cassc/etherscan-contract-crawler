// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./libraries/LibWeb3Domain.sol";

contract Web3RegistrarVerifier is OwnableUpgradeable, EIP712Upgradeable {
    address public verifierAddress;

    function __Web3RegistrarVerifier_init_unchained(
        address _verifierAddress
    ) internal onlyInitializing {
        __Ownable_init_unchained();
        __EIP712_init_unchained("Web3Registrar", "1");
        verifierAddress = _verifierAddress;
    }

    function verifyOrder(LibWeb3Domain.Order memory order, bytes memory signature) internal view {
        require(
            SignatureCheckerUpgradeable.isValidSignatureNow(
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

    uint256[49] private __gap;
}