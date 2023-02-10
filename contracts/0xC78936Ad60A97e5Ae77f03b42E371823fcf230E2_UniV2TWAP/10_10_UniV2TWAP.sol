/// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@relicprotocol/contracts/interfaces/IBatchProver.sol";
import "@relicprotocol/contracts/interfaces/IReliquary.sol";
import "@relicprotocol/contracts/lib/Facts.sol";
import "@relicprotocol/contracts/lib/FactSigs.sol";
import "@relicprotocol/contracts/lib/CoreTypes.sol";
import "@relicprotocol/contracts/lib/Storage.sol";

/**
 * @title UniV2TWAP
 * @author Theori, Inc.
 * @notice A trustless, fully on-chain UniswapV2 TWAP oracle built using Relic.
 */
contract UniV2TWAP {
    bytes32 constant reservesTimeSlot = bytes32(uint256(8));
    bytes32 constant price0CumulativeLastSlot = bytes32(uint256(9));
    bytes32 constant price1CumulativeLastSlot = bytes32(uint256(10));

    IReliquary immutable reliquary;

    struct TWAPParams {
        address pair;
        bool zero;
        uint256 startBlock;
        uint256 endBlock;
    }

    event TWAP(TWAPParams params, uint224 cumulativePrice);

    mapping(bytes32 => uint224) public priceMap;

    constructor(IReliquary _reliquary) {
        reliquary = _reliquary;
    }

    function paramsHash(TWAPParams memory params) public pure returns (bytes32 hash) {
        hash = keccak256(abi.encode(params));
    }

    /**
     * @notice Returns the TWAP price for the given params, or 0 if no such price was proven
     * @dev The returned price is in UQ112x112 format used by Uniswap V2. Many libraries exist
     *      for handing these values, for example
     *      https://github.com/compound-finance/open-oracle/blob/master/contracts/Uniswap/UniswapLib.sol
     * @param params the TWAP params
     */
    function getPrice(TWAPParams memory params) public view returns (uint224) {
        return priceMap[paramsHash(params)];
    }

    function extractReservesSlot(uint256 slot) internal pure returns (
        uint256 reserve0,
        uint256 reserve1,
        uint256 timestamp
    ) {
        reserve0 = uint256(uint112(slot));
        reserve1 = uint256(uint112(slot >> 112));
        timestamp = uint256(uint32(slot >> 224));
    }

    function proveUniV2State(
        IBatchProver prover,
        uint256 blockNum,
        address pair,
        bool zero,
        bytes calldata proof
    ) internal returns (
        uint256 cumulativePrice, uint256 timestamp
    ) {
        bytes32 slot = zero ? price0CumulativeLastSlot : price1CumulativeLastSlot;

        // prove the startBlock fact, forwarding along any proving fee
        Fact[] memory facts = prover.proveBatch(proof, false);
        require(facts.length == 3, "prover returned incorect number of facts");

        require(
            FactSignature.unwrap(facts[0].sig) ==
            FactSignature.unwrap(FactSigs.blockHeaderSig(blockNum)),
            "first fact is not block header"
        );
        bytes memory encoded = facts[0].data;
        CoreTypes.BlockHeaderData memory head;
        assembly {
            // this decoding is safe because BlockHeaderData contains only value types
            head := add(encoded, 0x20)
        }
        timestamp = head.Time;
        require(
            facts[1].account == pair,
            "fact1 account mismatch"
        );
        require(
            FactSignature.unwrap(facts[1].sig) ==
            FactSignature.unwrap(FactSigs.storageSlotFactSig(slot, blockNum)),
            "prover returned unexpected fact signature"
        );
        cumulativePrice = Storage.parseUint256(facts[1].data);

        require(
            facts[2].account == pair,
            "fact2 account mismatch"
        );
        require(
            FactSignature.unwrap(facts[2].sig) ==
            FactSignature.unwrap(FactSigs.storageSlotFactSig(reservesTimeSlot, blockNum)),
            "prover returned unexpected fact signature"
        );
        uint256 reservesSlot = Storage.parseUint256(facts[2].data);

        (uint256 reserve0, uint256 reserve1, uint256 lastTime) = extractReservesSlot(reservesSlot);
        uint256 timeElapsed = timestamp - lastTime;
        uint256 spotPrice = zero ? ((reserve1 << 112) / reserve0) : ((reserve0 << 112) / reserve1);

        cumulativePrice += spotPrice * timeElapsed;
    }

    /**
     * @notice submit a price to oracle's price map
     * @param params the TWAP parameters
     * @param prover the Relic batch prover to use
     * @param startProof the proof to verify the data at startBlock
     * @param endProof the proof to verify the data at endBlock
     */
    function submitPrice(
        TWAPParams memory params,
        address prover,
        bytes calldata startProof,
        bytes calldata endProof
    ) external {
        require(params.startBlock < params.endBlock, "startBlock must be before endBlock");

        // check that it's a valid prover
        IReliquary.ProverInfo memory info = reliquary.provers(prover);
        require(info.version > 0 && !info.revoked, "Invalid prover provided");

        (uint256 startCumulativePrice, uint256 startTime) = proveUniV2State(
            IBatchProver(prover), params.startBlock, params.pair, params.zero, startProof
        );
        (uint256 endCumulativePrice, uint256 endTime) = proveUniV2State(
            IBatchProver(prover), params.endBlock, params.pair, params.zero, endProof
        );
        uint224 cumulativePrice = uint224((endCumulativePrice - startCumulativePrice) / (endTime - startTime));

        emit TWAP(params, cumulativePrice);
        priceMap[paramsHash(params)] = cumulativePrice;
    }
}