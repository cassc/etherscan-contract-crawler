// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.21;

import "@openzeppelin/[email protected]/proxy/ERC1967/ERC1967Upgrade.sol";
import "@openzeppelin/[email protected]/proxy/Proxy.sol";

contract Moushley is Proxy, ERC1967Upgrade {
    uint8 constant LOG2_LEAVES = 16;

    bytes32 merkleRoot;

    event MoushleyBootstrap(
        bytes32 indexed merkleRoot,
        uint256 indexed merkleLeafIndex,
        bytes32 indexed lamportPublicKeyHash
    );

    constructor(bytes32 _merkleRoot) payable {
        require(_merkleRoot != 0, "Merkle root cannot be zero");
        merkleRoot = _merkleRoot;
    }

    function _implementation() internal view override returns (address) {
        return _getImplementation();
    }

    function moushleyBootstrap(
        bytes calldata initCode,
        bytes32 salt,
        address target,
        bytes calldata data,
        bool forceCall,
        uint256 merkleLeafIndex,
        bytes32[LOG2_LEAVES] calldata merkleProof,
        bytes32[256] calldata lamportSignature,
        bytes32[2][256] calldata lamportPublicKey
    ) public payable {
        if (merkleRoot == 0 || _implementation() != address(0)) {
            _fallback();
        }
        require(
            merkleLeafIndex < 1 << LOG2_LEAVES,
            "Merkle leaf index out of bounds"
        );

        bytes32 hash = keccak256(abi.encode(lamportPublicKey));
        emit MoushleyBootstrap(merkleRoot, merkleLeafIndex, hash);

        uint256 challenge = uint256(keccak256(abi.encode(
            merkleRoot,
            target,
            hash,
            forceCall,
            keccak256(data),
            block.chainid
        )));
        for (uint16 i = 0; i < 256; ++i) {
            require(
                lamportPublicKey[i][challenge & 1]
                    == keccak256(abi.encode(lamportSignature[i])),
                "Invalid Lamport signature"
            );
            challenge >>= 1;
        }

        uint256 index = merkleLeafIndex;
        for (uint8 i = 0; i < LOG2_LEAVES; ++i) {
            hash = keccak256(
                index & 1 == 0
                    ? abi.encode(hash, merkleProof[i])
                    : abi.encode(merkleProof[i], hash)
            );
            index >>= 1;
        }
        require(
            hash == merkleRoot,
            "Could not locate Lamport public key hash in Merkle tree"
        );

        merkleRoot = 0;
        address deployed;
        {
            bytes memory _ic = initCode;
            assembly ("memory-safe") {
                deployed := create2(0, add(_ic, 0x20), mload(_ic), salt)
            }
        }
        require(deployed != address(0), "CREATE2 failed");
        require(deployed == target, "Bad deployment target");
        _upgradeToAndCallUUPS(deployed, data, forceCall);
    }
}