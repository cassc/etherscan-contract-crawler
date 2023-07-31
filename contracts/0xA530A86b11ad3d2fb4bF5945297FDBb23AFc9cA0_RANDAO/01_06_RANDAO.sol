/// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@relicprotocol/contracts/interfaces/IReliquary.sol";
import "@relicprotocol/contracts/lib/CoreTypes.sol";

/**
 * @title RANDAO
 * @author Theori, Inc.
 * @notice A trustless, fully on-chain oracle for RANDAO values built using Relic.
 */
contract RANDAO {
    // first PoS block
    uint256 constant MERGE_BLOCK = 15537394;

    IReliquary public immutable reliquary;
    address public immutable blockHistory;

    event RANDAOValue(uint256 indexed block, bytes32 prevRandao);

    mapping(uint256 => bytes32) public values;

    struct BlockHeaderProof {
        bytes header;
        bytes proof;
    }

    constructor(IReliquary _reliquary, address _blockHistory) {
        reliquary = _reliquary;
        blockHistory = _blockHistory;
    }

    function parseBlockHeaderProof(bytes calldata encoded)
        internal
        pure
        returns (BlockHeaderProof calldata proof)
    {
        assembly {
            proof := encoded.offset
        }
    }

    function extractHeaderInfo(bytes calldata header)
        internal
        pure
        returns (uint256, bytes32)
    {
        CoreTypes.BlockHeaderData memory head = CoreTypes.parseBlockHeader(header);
        // prevRandao is stored in the former MixHash field
        return (head.Number, head.MixHash);
    }

    /**
     * @notice submit RANDAO value and proof to the mapping
     * @param proof the proof to verify the block header containing the RANDAO value
     */
    function submitBlock(bytes calldata proof) external payable {
        BlockHeaderProof calldata blockProof = parseBlockHeaderProof(proof);

        (uint256 blockNum, bytes32 prevRandao) = extractHeaderInfo(
            blockProof.header
        );
        require(values[blockNum] == bytes32(0), "block already submitted");
        require(
            blockNum >= MERGE_BLOCK,
            "Only post-merge blocks are supported"
        );

        require(
            reliquary.validBlockHash{value: msg.value}(
                blockHistory,
                keccak256(blockProof.header),
                blockNum,
                blockProof.proof
            ),
            "invalid block submission"
        );

        emit RANDAOValue(blockNum, prevRandao);
        values[blockNum] = prevRandao;
    }
}