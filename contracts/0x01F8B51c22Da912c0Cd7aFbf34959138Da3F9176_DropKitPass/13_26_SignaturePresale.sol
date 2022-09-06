// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

abstract contract SignaturePresale {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.Bytes32Set;
    using ECDSAUpgradeable for bytes32;

    // verified data per stage
    mapping(uint256 => EnumerableSetUpgradeable.Bytes32Set)
        internal _verified;
    address internal _signer;

    function _verifySignature(
        uint256 stageId,
        uint256 expiration,
        bytes32 data,
        bytes calldata signature
    ) internal {
        require(
            !_verified[stageId].contains(data),
            "Signature already verified"
        );
        require(expiration > block.timestamp, "Signature expired");
        require(
            keccak256(abi.encodePacked(stageId, expiration, data))
                .toEthSignedMessageHash()
                .recover(signature) == _signer,
            "Invalid signature"
        );

        _verified[stageId].add(data);
    }

    function _setSigner(address signer) internal {
        _signer = signer;
    }

    function _isVerified(uint256 stageId, bytes32 data)
        internal
        view
        returns (bool)
    {
        return _verified[stageId].contains(data);
    }
}