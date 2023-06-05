// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interface/IZKMptValidator.sol";
import "./MptVerifier.sol";

contract ZKMptValidator is MptVerifier, IZKMptValidator, Initializable {

    struct ParsedInput {
        bytes32 receiptHash;
        bytes32 logHash;
    }

    struct ZkProof {
        uint256[2] a;
        uint256[2][2] b;
        uint256[2] c;
        uint256[4] inputs;
    }

    function initialize() public initializer {
    }

    function validateMPT(bytes calldata _proof) external view returns (Receipt memory receipt){
        ZkProof memory proofData;
        (proofData.a, proofData.b, proofData.c, proofData.inputs)
        = abi.decode(_proof, (uint256[2], uint256[2][2], uint256[2], uint256[4]));
        uint256[1] memory compressInput;
        compressInput[0] = _hashInput(proofData.inputs);
        require(verifyProof(proofData.a, proofData.b, proofData.c, compressInput), "invalid zkProof");
        ParsedInput memory parsedInput = _parseInput(proofData.inputs);
        receipt = Receipt(parsedInput.receiptHash, parsedInput.logHash);
    }

    function _parseInput(uint256[4] memory _inputs) internal pure returns (ParsedInput memory){
        ParsedInput memory result;
        result.receiptHash = bytes32((_inputs[1] << 128) | _inputs[0]);
        result.logHash = bytes32((_inputs[3] << 128) | _inputs[2]);
        return result;
    }

    function _hashInput(uint256[4] memory _inputs) internal pure returns (uint256) {
        uint256 computedHash = uint256(keccak256(abi.encodePacked(_inputs[0], _inputs[1], _inputs[2], _inputs[3])));
        return computedHash / 256;
    }
}