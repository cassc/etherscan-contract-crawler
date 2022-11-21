// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./LibBet.sol";

library LibMatch {
    struct Odds {
        LibBet.EventResult eventResult;
        uint256 value;
    }
    struct Match {
        uint256 id;
        uint256 typeId;
        Odds leftOdds;
        Odds rightOdds;
        uint256 startTimestamp;
    }

    bytes32 constant ODDS_TYPEHASH =
        keccak256("Odds(uint8 eventResult,uint256 value)");

    bytes32 constant MATCH_TYPEHASH =
        keccak256(
            "Match(uint256 id,uint256 typeId,Odds leftOdds,Odds rightOdds,uint256 startTimestamp)Odds(uint8 eventResult,uint256 value)"
        );

    function hash(Odds calldata odds) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(ODDS_TYPEHASH, odds.eventResult, odds.value)
            );
    }

    function hash(Match calldata _match) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    MATCH_TYPEHASH,
                    _match.id,
                    _match.typeId,
                    hash(_match.leftOdds),
                    hash(_match.rightOdds),
                    _match.startTimestamp
                )
            );
    }
}