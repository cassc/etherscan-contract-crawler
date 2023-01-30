// SPDX-License-Identifier: MIT
// WARNING! This smart contract and the associated zk-SNARK verifiers have not been audited.
// DO NOT USE THIS CONTRACT FOR PRODUCTION
pragma solidity ^0.8.12;

import "./IAxiomV0.sol";

contract UniswapV2Twap {
    address private axiomAddress;    
    address private verifierAddress;

    // mapping between packed [startBlockNumber (32) || endBlockNumber (32)] and twapPri
    mapping(uint64 => uint256) public twapPris;

    event UniswapV2TwapProof(uint32 startBlockNumber, uint32 endBlockNumber, uint256 twapPri);

    constructor(address _axiomAddress, address _verifierAddress) {
        axiomAddress = _axiomAddress;        
        verifierAddress = _verifierAddress;
    }

    function verifyUniswapV2Twap(
        IAxiomV0.BlockHashWitness calldata startBlock,
        IAxiomV0.BlockHashWitness calldata endBlock,
        bytes calldata proof
    ) external {
        if (block.number - startBlock.blockNumber <= 256) {
            require(IAxiomV0(axiomAddress).isRecentBlockHashValid(startBlock.blockNumber, startBlock.claimedBlockHash),
                    "Starting block hash was not validated in cache");
        } else {
            require(IAxiomV0(axiomAddress).isBlockHashValid(startBlock),
                    "Starting block hash was not validated in cache");
        }
        if (block.number - endBlock.blockNumber <= 256) {
            require(IAxiomV0(axiomAddress).isRecentBlockHashValid(endBlock.blockNumber, endBlock.claimedBlockHash),
                    "Ending block hash was not validated in cache");
        } else {
            require(IAxiomV0(axiomAddress).isBlockHashValid(endBlock),
                    "Ending block hash was not validated in cache");
        }

        // Extract instances from proof 
        uint256 _startBlockHash   = uint256(bytes32(proof[384    :384+32 ])) << 128 | 
                                            uint128(bytes16(proof[384+48 :384+64 ]));
        uint256 _endBlockHash     = uint256(bytes32(proof[384+64 :384+96 ])) << 128 | 
                                            uint128(bytes16(proof[384+112:384+128]));
        uint256 _startBlockNumber = uint256(bytes32(proof[384+128:384+160]));
        uint256 _endBlockNumber   = uint256(bytes32(proof[384+160:384+192]));
        uint256 _twapPri          = uint256(bytes32(proof[384+192:384+224]));

        // Check instance values
        if (_startBlockHash != uint256(startBlock.claimedBlockHash)) {
            revert("Invalid startBlockHash in instance");
        }
        if (_endBlockHash != uint256(endBlock.claimedBlockHash)) {
            revert("Invalid endBlockHash in instance");
        }
        if (_startBlockNumber != startBlock.blockNumber) {
            revert("Invalid startBlockNumber");
        }
        if (_endBlockNumber != endBlock.blockNumber) {
            revert("Invalid endBlockNumber");
        }        

        (bool success, ) = verifierAddress.call(proof);
        if (!success) {
            revert("Proof verification failed");
        }
        twapPris[uint64(uint64(startBlock.blockNumber) << 32 | endBlock.blockNumber)] = _twapPri;
        emit UniswapV2TwapProof(startBlock.blockNumber, endBlock.blockNumber, _twapPri);        
    }
}