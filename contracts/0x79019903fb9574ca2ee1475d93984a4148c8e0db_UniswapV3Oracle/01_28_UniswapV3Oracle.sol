// SPDX-License-Identifier: MIT
// WARNING! This smart contract has not been audited.
// DO NOT USE THIS CONTRACT FOR PRODUCTION
// This is an example contract to demonstrate how to integrate an application with the audited production release of AxiomV1 and AxiomV1Query.
pragma solidity 0.8.19;

import "./Oracle.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {IUniswapV3Oracle, IAxiomV1Query} from "./IUniswapV3Oracle.sol";

contract UniswapV3Oracle is Ownable, IUniswapV3Oracle {
    address private axiomQueryAddress;

    /// @notice Mapping between abi.encodePacked(address poolAddress, uint32 startBlockNumber, uint32 endBlockNumber)
    ///         => keccak(abi.encodePacked(bytes32 startObservationPacked, bytes32 endObservationPacked)) where observationPacked
    ///         is the packing of Oracle.Observation observation into 32 bytes:
    ///         bytes32(bytes1(0x0) . secondsPerLiquidityCumulativeX128 . tickCumulative . blockTimestamp)
    /// @dev    This is the same as how Oracle.Observation is laid out in EVM storage EXCEPT that we set initialized = false (for some gas optimization reasons)
    mapping(bytes28 => bytes32) public twapObservations;

    event UpdateAxiomQueryAddress(address newAddress);

    constructor(address _axiomQueryAddress) {
        axiomQueryAddress = _axiomQueryAddress;
        emit UpdateAxiomQueryAddress(_axiomQueryAddress);
    }

    function updateAxiomQueryAddress(address _axiomQueryAddress) external onlyOwner {
        axiomQueryAddress = _axiomQueryAddress;
        emit UpdateAxiomQueryAddress(_axiomQueryAddress);
    }

    function unpackObservation(uint256 observation) internal pure returns (Oracle.Observation memory) {
        // observation` (31 bytes) is single field element, concatenation of `secondsPerLiquidityCumulativeX128 . tickCumulative . blockTimestamp`
        return Oracle.Observation({
            blockTimestamp: uint32(observation),
            tickCumulative: int56(uint56(observation >> 32)),
            secondsPerLiquidityCumulativeX128: uint160(observation >> 88),
            initialized: true
        });
    }

    /// @notice Verify a ZK proof of a Uniswap V3 TWAP oracle observation and verifies the validity of checkpoint blockhashes using Axiom.
    ///         Caches the [hash of] raw observations for future use.
    ///         Returns the time (seconds) weighted average tick (geometric mean) and the time (seconds) weight average liquidity (harmonic mean).
    /// @dev    We provide the time weighted average tick and time weighted average inverse liquidity for convenience, but return
    ///         the full Observations in case developers want more fine-grained calculations of the oracle observations.
    ///         For example the price can be calculated from the tick by P = 1.0001^tick
    function verifyUniswapV3TWAP(
        IAxiomV1Query.StorageResponse[] calldata storageProofs,
        bytes32[3] calldata keccakResponses
    )
        external
        returns (
            int56 twaTick,
            uint160 twaLiquidity,
            Oracle.Observation memory startObservation,
            Oracle.Observation memory endObservation
        )
    {
        require(storageProofs[0].slot == 8 && storageProofs[1].slot == 8, "invalid reserve slot");
        require(storageProofs[1].blockNumber > storageProofs[0].blockNumber, "end block must be after start block");
        require(storageProofs[0].addr == storageProofs[1].addr, "inconsistent pool address");
        require(
            IAxiomV1Query(axiomQueryAddress).areResponsesValid(
                keccakResponses[0],
                keccakResponses[1],
                keccakResponses[2],
                new IAxiomV1Query.BlockResponse[](0),
                new IAxiomV1Query.AccountResponse[](0),
                storageProofs
            ),
            "invalid proofs"
        );

        startObservation = unpackObservation(storageProofs[0].value);
        endObservation = unpackObservation(storageProofs[1].value);

        twapObservations[bytes28(
            abi.encodePacked(storageProofs[0].addr, storageProofs[0].blockNumber, storageProofs[1].blockNumber)
        )] = keccak256(abi.encodePacked(storageProofs[0].value, storageProofs[1].value));

        emit UniswapV3TwapProof(
            storageProofs[0].addr,
            storageProofs[0].blockNumber,
            storageProofs[1].blockNumber,
            startObservation,
            endObservation
        );

        uint32 secondsElapsed = endObservation.blockTimestamp - startObservation.blockTimestamp;
        // floor division
        twaTick = (endObservation.tickCumulative - startObservation.tickCumulative) / int56(uint56(secondsElapsed));
        // floor division
        twaLiquidity = ((uint160(1) << 128) * secondsElapsed)
            / (endObservation.secondsPerLiquidityCumulativeX128 - startObservation.secondsPerLiquidityCumulativeX128);
    }
}