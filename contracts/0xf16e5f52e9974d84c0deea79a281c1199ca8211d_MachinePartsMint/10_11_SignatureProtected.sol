// SPDX-License-Identifier: MIT
// @author: NFT Studios

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

abstract contract SignatureProtected is Ownable {
    address public signerAddress;

    constructor(address _signerAddress) {
        signerAddress = _signerAddress;
    }

    function setSignerAddress(address _signerAddress) external onlyOwner {
        signerAddress = _signerAddress;
    }

    function validateSignature(bytes memory packedParams, bytes calldata signature) internal view {
        require(
            ECDSA.recover(generateHash(packedParams), signature) == signerAddress,
            "SignatureProtected: Invalid signature for the caller"
        );
    }

    function generateHash(bytes memory packedParams) private view returns (bytes32) {
        bytes32 _hash = keccak256(bytes.concat(abi.encodePacked(address(this), msg.sender), packedParams));

        bytes memory result = abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash);

        return keccak256(result);
    }
}