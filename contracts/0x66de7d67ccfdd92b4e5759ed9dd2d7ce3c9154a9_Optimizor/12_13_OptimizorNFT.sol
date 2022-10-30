// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IChallenge} from "src/IChallenge.sol";
import {Base64} from "src/Base64.sol";
import {packTokenId, unpackTokenId} from "src/DataHelpers.sol";
import {NFTSVG} from "src/NFTSVG.sol";
import {TokenDetails} from "src/TokenDetails.sol";
import {HexString} from "src/HexString.sol";

import {ERC721} from "solmate/tokens/ERC721.sol";
import {LibString} from "solmate/utils/LibString.sol";

contract OptimizorNFT is ERC721 {
    // Invalid inputs
    error InvalidSolutionId(uint256 challengeId, uint32 solutionId);

    // Challenge id errors
    error ChallengeNotFound(uint256 challengeId);

    struct ChallengeInfo {
        /// The address of the challenge contract.
        IChallenge target;
        /// The number of valid solutions so far.
        uint32 solutions;
    }

    struct ExtraDetails {
        /// The address of the solution contract.
        address code;
        /// The address of the challenger who called `challenge`.
        address solver;
        /// The amount of gas spent by this solution.
        uint32 gas;
    }

    /// Maps challenge ids to their contracts and amount of solutions.
    mapping(uint256 => ChallengeInfo) public challenges;

    /// Maps token ids to extra details about the solution.
    mapping(uint256 => ExtraDetails) public extraDetails;

    constructor() ERC721("Optimizor Club", "OC") {}

    function contractURI() external pure returns (string memory) {
        return
        "data:application/json;base64,eyJuYW1lIjoiT3B0aW1pem9yIENsdWIiLCJkZXNjcmlwdGlvbiI6IlRoZSBPcHRpbWl6b3IgQ2x1YiBORlQgY29sbGVjdGlvbiByZXdhcmRzIGdhcyBlZmZpY2llbnQgcGVvcGxlIGFuZCBtYWNoaW5lcyBieSBtaW50aW5nIG5ldyBpdGVtcyB3aGVuZXZlciBhIGNoZWFwZXIgc29sdXRpb24gaXMgc3VibWl0dGVkIGZvciBhIGNlcnRhaW4gY2hhbGxlbmdlLiIsImltYWdlIjoiZGF0YTppbWFnZS9zdmcreG1sO2Jhc2U2NCxQSE4yWnlCM2FXUjBhRDBpTVRZMkxqVTVOeUlnYUdWcFoyaDBQU0l4TWpndU9UUXhJaUIyYVdWM1FtOTRQU0l3SURBZ05EUXVNRGM1SURNMExqRXhOaUlnZUcxc2JuTTlJbWgwZEhBNkx5OTNkM2N1ZHpNdWIzSm5Mekl3TURBdmMzWm5JajQ4Y0dGMGFDQmtQU0pOTWpBdU56a3pJREV6TGpNeU1XZ3RMall5TTFZeE1pNDNhQzAyTGpJeU5YWXVOakl5YUM0Mk1qSjJMall5TTJndExqWXlNbll1TmpJeWFDMHVOakl6ZGkwdU5qSXlTREV5TGpkMk5pNHlNalZvTGpZeU1uWXVOakl6YUM0Mk1qTjJMall5TW1nMkxqSXlOWFl0TGpZeU1tZ3VOakl6ZGkwdU5qSXphQzQyTWpKMkxUWXVNakkxYUMwdU5qSXllbTB0TXk0M016VWdOUzQyTUROMkxUUXVNelU0YURFdU9EWTNkalF1TXpVNGVtMHhNeTQyT1RndE5pNHlNalZvTFRZdU9EUTRkaTQyTWpKb0xqWXlNM1l1TmpJemFDMHVOakl6ZGk0Mk1qSm9MUzQyTWpKMkxTNDJNakpvTFM0Mk1qTjJOaTR5TWpWb0xqWXlNM1l1TmpJemFDNDJNakoyTGpZeU1tZzJMamcwT0hZdExqWXlNbWd1TmpJeWRpMHhMakkwTldndExqWXlNbll0TGpZeU0wZ3lOeTR3TW5ZdE5DNHpOVGhvTXk0M016VjJMUzQyTWpKb0xqWXlNbll0TGpZeU0yZ3RMall5TW5vaUlITjBlV3hsUFNKbWFXeHNPaU0yTmpZaUx6NDhMM04yWno0PSIsImV4dGVybmFsX2xpbmsiOiJodHRwczovL29wdGltaXpvci5jbHViLyJ9";
    }

    function tokenDetails(uint256 tokenId) public view returns (TokenDetails memory) {
        (uint256 challengeId, uint32 solutionId) = unpackTokenId(tokenId);
        if (solutionId == 0) revert InvalidSolutionId(challengeId, solutionId);

        ChallengeInfo storage chl = challenges[challengeId];
        if (address(chl.target) == address(0)) revert ChallengeNotFound(challengeId);
        if (solutionId > chl.solutions) revert InvalidSolutionId(challengeId, solutionId);

        ExtraDetails storage details = extraDetails[tokenId];

        uint256 leaderTokenId = packTokenId(challengeId, chl.solutions);
        ExtraDetails storage leaderDetails = extraDetails[leaderTokenId];

        uint32 leaderSolutionId = chl.solutions;
        uint32 rank = leaderSolutionId - solutionId + 1;

        // This means the first holder will have a 0% improvement.
        uint32 percentage = 0;
        if (solutionId > 1) {
            ExtraDetails storage prevDetails = extraDetails[tokenId - 1];
            percentage = (details.gas * 100) / prevDetails.gas;
        }

        return TokenDetails({
            challengeId: challengeId,
            challenge: chl.target,
            leaderGas: leaderDetails.gas,
            leaderSolutionId: leaderSolutionId,
            leaderSolver: leaderDetails.solver,
            leaderOwner: _ownerOf[leaderTokenId],
            leaderSubmission: leaderDetails.code,
            gas: details.gas,
            solutionId: solutionId,
            rank: rank,
            improvementPercentage: percentage,
            solver: details.solver,
            owner: _ownerOf[tokenId],
            submission: details.code
        });
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        TokenDetails memory details = tokenDetails(tokenId);

        string memory description = string.concat(details.challenge.description(), "\\n\\n", leaderboardString(tokenId));

        return string.concat(
            "data:application/json;base64,",
            Base64.encode(
                bytes(
                    string.concat(
                        '{"name":"Optimizor Club: ',
                        details.challenge.name(),
                        '","description":"',
                        description,
                        '","attributes":',
                        attributesJSON(details),
                        ',"image":"data:image/svg+xml;base64,',
                        Base64.encode(bytes(svg(tokenId, details))),
                        '"}'
                    )
                )
            )
        );
    }

    function leaderboard(uint256 tokenId) public view returns (address[] memory board) {
        (uint256 challengeId,) = unpackTokenId(tokenId);
        uint32 winners = challenges[challengeId].solutions;
        board = new address[](winners);
        unchecked {
            for (uint32 i = 1; i <= winners; ++i) {
                ExtraDetails storage details = extraDetails[packTokenId(challengeId, i)];
                board[i - 1] = details.solver;
            }
        }
    }

    function leaderboardString(uint256 tokenId) private view returns (string memory) {
        address[] memory leaders = leaderboard(tokenId);
        string memory leadersStr = "";
        uint256 lIdx = leaders.length;
        unchecked {
            for (uint256 i = 0; i < leaders.length; ++i) {
                leadersStr = string.concat(
                    "\\n",
                    LibString.toString(lIdx),
                    ". ",
                    HexString.toHexString(uint256(uint160(leaders[i])), 20),
                    leadersStr
                );
                --lIdx;
            }
        }
        return string.concat("Leaderboard:\\n", leadersStr);
    }

    function attributesJSON(TokenDetails memory details) private view returns (string memory attributes) {
        uint32 rank = details.rank;

        attributes = string.concat(
            '[{"trait_type":"Challenge","value":"',
            details.challenge.name(),
            '"},{"trait_type":"Gas used","value":',
            LibString.toString(details.gas),
            ',"display_type":"number"},{"trait_type":"Code size","value":',
            LibString.toString(details.submission.code.length),
            ',"display_type":"number"},{"trait_type":"Improvement percentage","value":"',
            LibString.toString(details.improvementPercentage),
            '%"},{"trait_type":"Solver","value":"',
            HexString.toHexString(uint256(uint160(details.solver)), 20),
            '"},{"trait_type":"Rank","value":',
            LibString.toString(rank),
            ',"display_type":"number"},{"trait_type":"Leader","value":"',
            (rank == 1) ? "Yes" : "No",
            '"},{"trait_type":"Top 3","value":"',
            (rank <= 3) ? "Yes" : "No",
            '"},{"trait_type":"Top 10","value":"',
            (rank <= 10) ? "Yes" : "No",
            '"}]'
        );
    }

    // This scales the value from [0,255] to [minOut,maxOut].
    // Assumes 255*maxOut <= 2^256-1.
    function scale(uint8 value, uint256 minOut, uint256 maxOut) private pure returns (uint256) {
        unchecked {
            return ((uint256(value) * (maxOut - minOut)) / 255) + minOut;
        }
    }

    function svg(uint256 tokenId, TokenDetails memory details) private view returns (string memory) {
        uint256 gradRgb = 0;
        if (details.rank > 10) {
            gradRgb = 0xbebebe;
        } else if (details.rank > 3) {
            uint256 fRank;
            uint256 init = 40;
            uint256 factor = 15;
            unchecked {
                fRank = init + details.rank * factor;
            }
            gradRgb = (uint256(fRank) << 16) | (uint256(fRank) << 8) | uint256(fRank);
        }

        NFTSVG.SVGParams memory svgParams = NFTSVG.SVGParams({
            projectName: "Optimizor Club",
            challengeName: details.challenge.name(),
            solverAddr: HexString.toHexString(uint256(uint160(address(details.owner))), 20),
            challengeAddr: HexString.toHexString(uint256(uint160(address(details.challenge))), 20),
            gasUsed: details.gas,
            gasOpti: details.improvementPercentage,
            tokenId: tokenId,
            rank: details.rank,
            // The leader is the last player, e.g. its solution id equals the number of players.
            participants: details.leaderSolutionId,
            color: HexString.toHexStringNoPrefix(gradRgb, 3),
            x1: scale(NFTSVG.getCircleCoord(address(details.challenge), 16, tokenId), 16, 274),
            y1: scale(NFTSVG.getCircleCoord(address(details.solver), 16, tokenId), 100, 484),
            x2: scale(NFTSVG.getCircleCoord(address(details.challenge), 32, tokenId), 16, 274),
            y2: scale(NFTSVG.getCircleCoord(address(details.solver), 32, tokenId), 100, 484),
            x3: scale(NFTSVG.getCircleCoord(address(details.challenge), 48, tokenId), 16, 274),
            y3: scale(NFTSVG.getCircleCoord(address(details.solver), 48, tokenId), 100, 484)
        });

        return NFTSVG.generateSVG(svgParams, details.challenge.svg(tokenId));
    }
}