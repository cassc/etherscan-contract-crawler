// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interface/IBlockUpdater.sol";
import "./PolygonBlockVerifier.sol";
import "./PolygonValidatorVerifier.sol";

contract PolygonBlockUpdater is IBlockUpdater, PolygonBlockVerifier, PolygonValidatorVerifier, Initializable, OwnableUpgradeable {
    event ImportSyncCommitteeRoot(uint256 indexed period, bytes32 indexed syncCommitteeRoot);
    event ModBlockConfirmation(uint256 oldBlockConfirmation, uint256 newBlockConfirmation);

    struct ValidatorInput {
        uint256 blockNumber;
        uint256 blockConfirmation;
        bytes32 blockHash;
        bytes32 receiptHash;
        bytes32 validatorSetHash;
        bytes32 nextValidatorSetHash;
    }

    struct BlockInput {
        uint256 blockNumber;
        uint256 blockConfirmation;
        bytes32 validatorSetHash;
        bytes32 receiptHash;
        bytes32 blockHash;
    }

    struct ValidatorProof {
        uint256[2] a;
        uint256[2][2] b;
        uint256[2] c;
        uint256[8] inputs;
    }

    struct BlockProof {
        uint256[2] a;
        uint256[2][2] b;
        uint256[2] c;
        uint256[7] inputs;
    }

    // period => validatorHash
    mapping(uint256 => bytes32) public validatorHashes;

    // blockHash=>receiptsRoot =>BlockConfirmation
    mapping(bytes32 => mapping(bytes32 => uint256)) public blockInfos;

    uint256 public minBlockConfirmation;

    uint256 public currentPeriod;

    function initialize(uint64 period, bytes32 validatorSetHash, uint256 _minBlockConfirmation) public initializer {
        __Ownable_init();
        currentPeriod = period;
        validatorHashes[period] = validatorSetHash;
        minBlockConfirmation = _minBlockConfirmation;
    }

    function importNextValidatorSet(bytes calldata _proof) external {
        _importNextValidatorSet(_proof);
    }

    function batchImportNextValidatorSet(bytes[] calldata _proof) external {
        for (uint256 i = 0; i < _proof.length; i++) {
            _importNextValidatorSet(_proof[i]);
        }
    }

    function importBlock(bytes calldata _proof) external {
        _importBlock(_proof);
    }

    function batchImportBlock(bytes[] calldata _proof) external {
        for (uint256 i = 0; i < _proof.length; i++) {
            _importBlock(_proof[i]);
        }
    }

    function checkBlock(bytes32 _blockHash, bytes32 _receiptHash) external view returns (bool) {
        (bool exist,) = _checkBlock(_blockHash, _receiptHash);
        return exist;
    }

    function checkBlockConfirmation(bytes32 _blockHash, bytes32 _receiptHash) external view returns (bool, uint256) {
        return _checkBlock(_blockHash, _receiptHash);
    }

    function _importNextValidatorSet(bytes calldata _proof) internal {
        ValidatorProof memory proofData;
        (proofData.a, proofData.b, proofData.c, proofData.inputs) = abi.decode(_proof, (uint256[2], uint256[2][2], uint256[2], uint256[8]));
        ValidatorInput memory parsedInput = _parseValidatorInput(proofData.inputs);

        uint256 period = _computePeriod(parsedInput.blockNumber);
        uint256 nextPeriod = period + 1;
        //        require(validatorHashes[period] == parsedInput.validatorSetHash, "invalid validatorSetHash");
        //        require(validatorHashes[nextPeriod] == bytes32(0), "nextValidatorSetHash already exist");

        uint256[1] memory compressInput;
        compressInput[0] = _hashValidatorInput(proofData.inputs);
        require(verifyValidatorProof(proofData.a, proofData.b, proofData.c, compressInput), "invalid proof");
        validatorHashes[nextPeriod] = parsedInput.nextValidatorSetHash;
        currentPeriod = nextPeriod;
        blockInfos[parsedInput.blockHash][parsedInput.receiptHash] = parsedInput.blockConfirmation;
        emit ImportSyncCommitteeRoot(nextPeriod, parsedInput.nextValidatorSetHash);
        emit ImportBlock(parsedInput.blockNumber, parsedInput.blockHash, parsedInput.receiptHash);
    }

    function _importBlock(bytes calldata _proof) internal {
        BlockProof memory proofData;
        (proofData.a, proofData.b, proofData.c, proofData.inputs) = abi.decode(_proof, (uint256[2], uint256[2][2], uint256[2], uint256[7]));
        BlockInput memory parsedInput = _parseBlockInput(proofData.inputs);

        require(parsedInput.blockConfirmation >= minBlockConfirmation, "Not enough block confirmations");
        (bool exist,uint256 blockConfirmation) = _checkBlock(parsedInput.blockHash, parsedInput.receiptHash);
        if (exist && parsedInput.blockConfirmation <= blockConfirmation) {
            revert("already exist");
        }
        //        uint256 period = _computePeriod(parsedInput.blockNumber);
        //        require(validatorHashes[period] == parsedInput.validatorSetHash, "invalid validatorSetHash");

        uint256[1] memory compressInput;
        compressInput[0] = _hashBlockInput(proofData.inputs);
        require(verifyBlockProof(proofData.a, proofData.b, proofData.c, compressInput), "invalid proof");

        blockInfos[parsedInput.blockHash][parsedInput.receiptHash] = parsedInput.blockConfirmation;
        emit ImportBlock(parsedInput.blockNumber, parsedInput.blockHash, parsedInput.receiptHash);
    }

    function _checkBlock(bytes32 _blockHash, bytes32 _receiptHash) internal view returns (bool, uint256) {
        uint256 blockConfirmation = blockInfos[_blockHash][_receiptHash];
        if (blockConfirmation > 0) {
            return (true, blockConfirmation);
        }
        return (false, blockConfirmation);
    }

    function _parseValidatorInput(uint256[8] memory _inputs) internal pure returns (ValidatorInput memory) {
        ValidatorInput memory result;
        result.blockHash = bytes32((_inputs[1] << 128) | _inputs[0]);
        result.receiptHash = bytes32((_inputs[3] << 128) | _inputs[2]);
        result.validatorSetHash = bytes32(_inputs[4]);
        result.nextValidatorSetHash = bytes32(_inputs[5]);
        result.blockNumber = _inputs[6];
        result.blockConfirmation = _inputs[7];
        return result;
    }

    function _parseBlockInput(uint256[7] memory _inputs) internal pure returns (BlockInput memory) {
        BlockInput memory result;
        result.blockHash = bytes32((_inputs[1] << 128) | _inputs[0]);
        result.receiptHash = bytes32((_inputs[3] << 128) | _inputs[2]);
        result.validatorSetHash = bytes32(_inputs[4]);
        result.blockNumber = _inputs[5];
        result.blockConfirmation = _inputs[6];
        return result;
    }

    function _hashValidatorInput(uint256[8] memory _inputs) internal pure returns (uint256) {
        uint256 computedHash = uint256(keccak256(abi.encodePacked(_inputs[0], _inputs[1], _inputs[2], _inputs[3], _inputs[4], _inputs[5], _inputs[6], _inputs[7])));
        return computedHash / 256;
    }

    function _hashBlockInput(uint256[7] memory _inputs) internal pure returns (uint256) {
        uint256 computedHash = uint256(keccak256(abi.encodePacked(_inputs[0], _inputs[1], _inputs[2], _inputs[3], _inputs[4], _inputs[5], _inputs[6])));
        return computedHash / 256;
    }

    function _computePeriod(uint256 blockNumber) internal pure returns (uint256) {
        return blockNumber / 16;
    }

    //----------------------------------------------------------------------------------
    // onlyOwner
    function setBlockConfirmation(uint256 _minBlockConfirmation) external onlyOwner {
        emit ModBlockConfirmation(minBlockConfirmation, _minBlockConfirmation);
        minBlockConfirmation = _minBlockConfirmation;
    }
}