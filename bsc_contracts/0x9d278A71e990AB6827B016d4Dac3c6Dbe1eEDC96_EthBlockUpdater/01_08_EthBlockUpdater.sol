// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./client/BLS12381.sol";
import "./EthVerifier.sol";

interface ILightClient {
    function getCommitteeRoot(uint64 slot) external view returns (bytes32);
}

contract EthBlockUpdater is EthVerifier, Initializable, OwnableUpgradeable, BLS12381 {
    event ImportBlock(uint256 slot, bytes32 singingRoot, bytes32 receiptHash);

    struct ParsedInput {
        uint64 slot;
        bytes32 syncCommitteeRoot;
        bytes32 receiptHash;
    }

    // signingRoot=>receiptsRoot
    mapping(bytes32 => bytes32) public blockInfos;

    ILightClient public lightClient;

    function initialize(address _lightClient) public initializer {
        lightClient = ILightClient(_lightClient);
        __Ownable_init();
    }

    function importBlock(
        uint256[2] calldata a,
        uint256[2][2] calldata b,
        uint256[2] calldata c,
        uint256[5] calldata inputs,
        bytes32 signingRoot
    ) external {
        uint256[33] memory verifyInputs;
        ParsedInput memory parsedInput = _parseInput(inputs);
        uint256[28] memory fieldElement = hashToField(signingRoot);
        for (uint i = 0; i < 28; i++) {
            verifyInputs[i] = fieldElement[i];
        }
        verifyInputs[28] = inputs[0];
        verifyInputs[29] = inputs[1];
        verifyInputs[30] = inputs[2];
        verifyInputs[31] = inputs[3];
        verifyInputs[32] = inputs[4];

        bytes32 committeeRoot = lightClient.getCommitteeRoot(parsedInput.slot);
        require(committeeRoot == parsedInput.syncCommitteeRoot, "invalid committeeRoot");

        require(verifyProof(a, b, c, verifyInputs), "invalid proof");

        blockInfos[signingRoot] = parsedInput.receiptHash;
        emit ImportBlock(
            parsedInput.slot,
            signingRoot,
            parsedInput.receiptHash
        );
    }

    function checkBlock(bytes32 signingRoot, bytes32 receiptHash) external view returns (bool) {
        bytes32 _receiptsHash = blockInfos[signingRoot];
        if (_receiptsHash != bytes32(0) && _receiptsHash == receiptHash) {
            return true;
        }
        return false;
    }

    function _parseInput(uint256[5] memory inputs) internal pure returns (ParsedInput memory) {
        ParsedInput memory result;
        result.syncCommitteeRoot = bytes32((inputs[1] << 128) | inputs[0]);
        result.slot = uint64(inputs[2]);
        result.receiptHash = bytes32((inputs[4] << 128) | inputs[3]);
        return result;
    }
}