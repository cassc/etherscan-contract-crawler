// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library Encoder {
    uint256 internal constant AMOUNT_SHIFT = 32;
    uint256 internal constant BET_DATA_SHIFT = 15;
    uint256 internal constant SIDE_AGAINST_SHIFT = 31;

    function toUniqueKey(
        uint256 gameId_,
        uint256 matchId_,
        uint256 status_,
        uint256 betType_
    ) internal pure returns (uint48) {
        return
            uint48(
                (gameId_ << 40) | (matchId_ << 16) | (status_ << 8) | betType_
            );
    }

    function toBetDetail(
        uint256 betSize_,
        uint256 sideAgainst_,
        uint256 betData_,
        uint256 odd_
    ) internal pure returns (uint128) {
        return
            uint128(
                (betSize_ << AMOUNT_SHIFT) |
                    (sideAgainst_ << SIDE_AGAINST_SHIFT) |
                    (betData_ << BET_DATA_SHIFT) |
                    odd_
            );
    }

    function betData(uint256 betDetail_) internal pure returns (uint256) {
        return (betDetail_ >> BET_DATA_SHIFT) & 0x7fff;
    }

    function odd(uint256 betDetail_) internal pure returns (uint256) {
        return (betDetail_ & 0xffff) * 100;
    }

    function amount(uint256 betDetail_) internal pure returns (uint256) {
        return betDetail_ >> AMOUNT_SHIFT;
    }

    function sideAgainst(uint256 betDetail_) internal pure returns (uint256) {
        return (betDetail_ >> SIDE_AGAINST_SHIFT) & 1;
    }

    function decodeBetId(
        uint256 betId_
    )
        internal
        pure
        returns (
            uint8 gameId,
            uint24 matchId,
            uint16 odd_,
            uint16 betData_,
            uint8 settleStatus,
            uint8 side,
            uint8 sideAgainst_,
            uint8 betType
        )
    {
        assembly {
            gameId := shr(96, betId_)
            matchId := and(shr(72, betId_), 0xffffff)
            odd_ := and(shr(48, betId_), 0xffff)
            betData_ := shr(32, betId_)
            settleStatus := shr(24, betId_)
            side := shr(16, betId_)
            sideAgainst_ := shr(8, betId_)
            betType := betId_
        }
    }

    function receiptOf(
        address user_,
        uint256 id_,
        uint256 side_
    ) internal pure returns (uint256) {
        uint256 digest;
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, user_)
            mstore(add(ptr, 160), id_)
            mstore(add(ptr, 208), side_)
            digest := keccak256(ptr, 216)
        }
        return digest;
    }
}