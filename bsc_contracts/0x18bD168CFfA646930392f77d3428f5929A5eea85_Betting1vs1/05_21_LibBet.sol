// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./LibTokenAsset.sol";

library LibBet {
    using LibTokenAsset for LibTokenAsset.TokenAsset;

    enum EventResult {
        LEFT,
        RIGHT
    }

    struct Bet {
        address bettor;
        uint256 matchId;
        uint256 matchTypeId;
        EventResult betOn;
        LibTokenAsset.TokenAsset asset;
        uint256 salt;
    }

    bytes32 constant BET_TYPE_TYPEHASH =
        keccak256(
            "Bet(address bettor,uint256 matchId,uint256 matchTypeId,uint8 betOn,TokenAsset asset,uint256 salt)TokenAsset(address token,uint256 amount)"
        );

    function hash(Bet calldata bet) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    BET_TYPE_TYPEHASH,
                    bet.bettor,
                    bet.matchId,
                    bet.matchTypeId,
                    bet.betOn,
                    bet.asset.hash(),
                    bet.salt
                )
            );
    }
}