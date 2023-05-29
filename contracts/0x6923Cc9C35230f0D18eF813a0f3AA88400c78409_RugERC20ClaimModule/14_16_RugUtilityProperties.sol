// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {IMembershipRenderer} from "./Renderer/IMembershipRenderer.sol";

/// Custom contract for RugRadio utility NFTsproperties
contract RugUtilityProperties is Ownable, IMembershipRenderer {
    using Strings for uint256;

    uint256 public seed;
    string public baseURI; // https://pinata.cloud/<location>/

    // tokenId => custom combination ID
    mapping(uint256 => uint256) public oneOfOneCombination;
    // tokenId => custom token production
    mapping(uint256 => uint256) public oneOfOneProduction;

    event SeedGenerated(string phrase, uint256 seed);
    event UpdateBaseURI(string baseURI);
    event UpdateCombination(
        uint256 indexed tokenId,
        uint256 indexed combinationId
    );
    event UpdateProduction(uint256 indexed tokenId, uint256 indexed production);

    modifier onlyAfterReveal() {
        require(
            seed > 0 && bytes(baseURI).length > 0,
            "Reveal not released yet"
        );
        _;
    }

    function generateSeed(string memory phrase)
        external
        onlyOwner
        returns (uint256)
    {
        require(seed == 0, "Seed already set");
        seed = uint256(keccak256(abi.encode(phrase)));
        emit SeedGenerated(phrase, seed);
    }

    function updateBaseURI(string memory uri)
        external
        onlyOwner
        returns (string memory)
    {
        baseURI = uri;
        emit UpdateBaseURI(baseURI);
    }

    function updateOneOfOneCombination(uint256 tokenId, uint256 combination)
        external
        onlyOwner
    {
        // max combination Id = 4 * 100 + 16 = 416 -> use 500 for clean separation
        // additionally let people set to 0 in case an error occured and need a reset
        require(
            combination >= 500 || combination == 0,
            "One-of-One combination id invalid"
        );
        oneOfOneCombination[tokenId] = combination;
        emit UpdateCombination(tokenId, combination);
    }

    function updateOneOfOneProduction(uint256 tokenId, uint256 production)
        external
        onlyOwner
    {
        oneOfOneProduction[tokenId] = production;
        emit UpdateProduction(tokenId, production);
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        if (seed == 0) {
            // fixed URL for utility NFT pre-reveal, allows us to switch renderer before reveal easily
            return "ipfs://QmPLizWkV3zmDybjXZnr7AALNLjab67QsmfrzHC8bhUm4S";
        }
        return
            string(
                abi.encodePacked(
                    baseURI,
                    getCombinationId(tokenId).toString(),
                    ".json"
                )
            );
    }

    function tokenURIOf(address, uint256 tokenId)
        external
        view
        returns (string memory)
    {
        return tokenURI(tokenId);
    }

    function getSlot(uint256 tokenId)
        internal
        view
        onlyAfterReveal
        returns (uint256)
    {
        // randomly distributee tokenId's across slots by re-hashing with seed
        uint256 slotSeed = uint256(keccak256(abi.encode(seed, tokenId)));
        return slotSeed % 19989;
    }

    function getCombinationId(uint256 tokenId) internal view returns (uint256) {
        if (oneOfOneCombination[tokenId] == 0) {
            return uint256(getRole(tokenId)) * 100 + getMeme(tokenId);
        } else {
            return oneOfOneCombination[tokenId];
        }
    }

    function getRole(uint256 tokenId) public view returns (uint8) {
        if (oneOfOneCombination[tokenId] == 0) {
            uint256 slot = getSlot(tokenId);

            if (slot < 112) {
                // 7 * 16 rows = 112 "Rare 2" roles
                return 1;
            } else if (slot < 112 + 1104) {
                // 69 * 16 rows = 1104 "Scarce 1" roles
                return 2;
            } else if (slot < 112 + 1104 + 7648) {
                // 478 * 16 rows = 7648 "Scarce 2" roles
                return 3;
            } else {
                // rest of roles are "Standard"
                return 4;
            }
        } else {
            // custom additions of "Rare 1" roles
            return 0;
        }
    }

    function getMeme(uint256 tokenId) public view returns (uint8) {
        if (oneOfOneCombination[tokenId] == 0) {
            // all rows share uniform distribution of different meme values
            return uint8((getSlot(tokenId) % 16) + 1);
        } else {
            // "One-of-One" for special tokens with override
            return 0;
        }
    }

    function getProduction(uint256 tokenId) external view returns (uint256) {
        if (oneOfOneProduction[tokenId] > 0) {
            // "Rare 1" roles with additional custom production rate
            return oneOfOneProduction[tokenId];
        }
        uint8 role = getRole(tokenId);
        if (role <= 1) {
            // "Rare X" roles
            return 11;
        } else if (role <= 3) {
            // "Scarce X" roles
            return 7;
        } else {
            // "Standard" roles
            return 5;
        }
    }
}