// SPDX-License-Identifier: MIT

/// @title Interface for Noun Auction Houses

pragma solidity ^0.8.9;

import {IRoyalContractBase} from "./IRoyalContractBase.sol";
import {RoyalLibrary} from "../contracts/lib//RoyalLibrary.sol";
import {IQueenTraits} from "./IQueenTraits.sol";
import {IQueenE} from "./IQueenE.sol";

interface IQueenLab is IRoyalContractBase {
    function buildDna(uint256 queeneId, bool isSir)
        external
        view
        returns (RoyalLibrary.sDNA[] memory dna);

    function produceBlueBlood(RoyalLibrary.sDNA[] memory dna)
        external
        view
        returns (RoyalLibrary.sBLOOD[] memory blood);

    function generateQueen(uint256 _queenId, bool isSir)
        external
        view
        returns (RoyalLibrary.sQUEEN memory);

    function getQueenRarity(RoyalLibrary.sDNA[] memory _dna)
        external
        pure
        returns (RoyalLibrary.queeneRarity finalRarity);

    function getQueenRarityBidIncrement(
        RoyalLibrary.sDNA[] memory _dna,
        uint256[] calldata map
    ) external pure returns (uint256 value);

    function getQueenRarityName(RoyalLibrary.sDNA[] memory _dna)
        external
        pure
        returns (string memory rarityName);

    function constructTokenUri(
        RoyalLibrary.sQUEEN memory _queene,
        string memory _ipfsUri
    ) external view returns (string memory);
}