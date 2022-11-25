// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

abstract contract SignaturePresale {
    using ECDSA for bytes32;

    // verified data per stage
    mapping(uint256 => mapping(bytes32 => bool)) internal _verifiedData;
    address internal _signer;

    function _verifySignature(
        uint256 stageId,
        uint256 expiration,
        bytes32 data,
        bytes calldata signature
    ) internal {
        require(!_verifiedData[stageId][data], "Signature already verified");
        require(expiration > block.timestamp, "Signature expired");
        require(
            keccak256(abi.encodePacked(stageId, expiration, data))
                .toEthSignedMessageHash()
                .recover(signature) == _signer,
            "Invalid signature"
        );

        _verifiedData[stageId][data] = true;
    }

    function _setSigner(address signer) internal {
        _signer = signer;
    }

    function _isVerified(uint256 stageId, bytes32 data)
        internal
        view
        returns (bool)
    {
        return _verifiedData[stageId][data];
    }
}