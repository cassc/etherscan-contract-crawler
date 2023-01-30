// SPDX-License-Identifier: MIT
// WARNING! This smart contract and the associated zk-SNARK verifiers have not been audited.
// DO NOT USE THIS CONTRACT FOR PRODUCTION
pragma solidity ^0.8.12;

import "./IAxiomV0.sol";

contract AccountAge {
    address private axiomAddress;    
    address private verifierAddress;

    mapping(address => uint32) public birthBlocks;

    event AccountAgeProof(address account, uint32 blockNumber);

    constructor(address _axiomAddress, address _verifierAddress) {
        axiomAddress = _axiomAddress;        
        verifierAddress = _verifierAddress;
    }

    function verifyAge(
        IAxiomV0.BlockHashWitness calldata prevBlock,
        IAxiomV0.BlockHashWitness calldata currBlock,
        bytes calldata proof
    ) external {
        if (block.number - prevBlock.blockNumber <= 256) {
            require(IAxiomV0(axiomAddress).isRecentBlockHashValid(prevBlock.blockNumber, prevBlock.claimedBlockHash),
                    "Prev block hash was not validated in cache");
        } else {
            require(IAxiomV0(axiomAddress).isBlockHashValid(prevBlock),
                    "Prev block hash was not validated in cache");
        }
        if (block.number - currBlock.blockNumber <= 256) {
            require(IAxiomV0(axiomAddress).isRecentBlockHashValid(currBlock.blockNumber, currBlock.claimedBlockHash),
                    "Curr block hash was not validated in cache");
        } else {
            require(IAxiomV0(axiomAddress).isBlockHashValid(currBlock),
                    "Curr block hash was not validated in cache");
        }

        // Extract instances from proof 
        uint256 _prevBlockHash = uint256(bytes32(proof[384    :384+32 ])) << 128 | 
                                 uint128(bytes16(proof[384+48 :384+64 ]));
        uint256 _currBlockHash = uint256(bytes32(proof[384+64 :384+96 ])) << 128 | 
                                 uint128(bytes16(proof[384+112:384+128]));
        uint256 _blockNumber   = uint256(bytes32(proof[384+128:384+160]));
        address account        = address(bytes20(proof[384+172:384+204]));

        // Check instance values
        if (_prevBlockHash != uint256(prevBlock.claimedBlockHash)) {
            revert("Invalid previous block hash in instance");
        }
        if (_currBlockHash != uint256(currBlock.claimedBlockHash)) {
            revert("Invalid current block hash in instance");
        }
        if (_blockNumber != currBlock.blockNumber) {
            revert("Invalid block number");
        }

        // Verify the following statement: 
        //   nonce(account, blockNumber - 1) == 0 AND 
        //   nonce(account, blockNumber) != 0     AND
        //   codeHash(account, blockNumber) == keccak256([])
        (bool success, ) = verifierAddress.call(proof);
        if (!success) {
            revert("Proof verification failed");
        }
        birthBlocks[account] = currBlock.blockNumber;
        emit AccountAgeProof(account, currBlock.blockNumber);
    }
}