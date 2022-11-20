// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library BetLogic {
    enum BetType {
        WIN,
        DRAW,
        OVER,
        UNDER,
        HANDICAP,
        BOTH_TEAM_SCORE,
        CORRECT_SCORE, //6
        PENALTY_SCORE,
        NUM_RED_CARD,
        NUM_YELLOW_CARD,
        TOTAL_SCORE, //10
        PENALTY_TOTAL,
        RED_CARD_TOTAL,
        YELLOW_CARD_TOTAL
    }

    uint256 internal constant LOSE_ALL = 0;

    uint256 internal constant WIN_ALL = 1;
    uint256 internal constant LOSE_HALF = 2; //
    uint256 internal constant WIN_HALF = 3; //
    uint256 internal constant REFUND = 4; //

    function isValidClaim(
        uint256 side,
        uint256 sideAgainst_,
        uint256 betType_,
        uint256 betData_,
        uint256 scores_
    ) internal pure returns (uint256 result) {
        uint256 sideInFavorResult = (scores_ >> (side << 3)) & 0xff;
        uint256 sideAgainstResult = (scores_ >> (sideAgainst_ << 3)) & 0xff;

        uint256 sideInFavorScore = (betData_ >> (side << 3)) & 0xff;
        uint256 sideAgainstScore = (betData_ >> (sideAgainst_ << 3)) & 0xff;
        unchecked {
            if (betType_ == uint8(BetType.HANDICAP)) {
                sideAgainstResult *= 100;
                sideInFavorResult *= 100 + betData_;

                if (sideInFavorResult == sideAgainstResult) return REFUND;

                if (sideInFavorResult == 25 + sideAgainstResult)
                    return WIN_HALF;
                if (sideInFavorResult + 25 == sideAgainstResult)
                    return LOSE_HALF;

                if (sideInFavorResult > 25 + sideAgainstResult) return WIN_ALL;
                if (sideInFavorResult + 25 < sideAgainstResult) return LOSE_ALL;
            }
            bool valid;
            if (betType_ >= uint8(BetType.TOTAL_SCORE)) {
                valid = betData_ >> 8 != 0
                    ? sideInFavorResult + sideAgainstResult >= uint8(betData_)
                    : sideInFavorResult + sideAgainstResult == betData_;
                return valid ? WIN_ALL : LOSE_ALL;
            }
            if (betType_ >= uint8(BetType.CORRECT_SCORE)) {
                valid =
                    sideAgainstScore == sideAgainstResult &&
                    sideInFavorScore == sideInFavorResult;
                return valid ? WIN_ALL : LOSE_ALL;
            }
            if (betType_ == uint8(BetType.OVER)) {
                valid =
                    sideInFavorResult + sideAgainstResult >= sideInFavorScore;
                return valid ? WIN_ALL : LOSE_ALL;
            }
            if (betType_ == uint8(BetType.UNDER)) {
                valid =
                    sideInFavorResult + sideAgainstResult < sideInFavorScore;
                return valid ? WIN_ALL : LOSE_ALL;
            }
            if (betType_ == uint8(BetType.WIN)) {
                valid = sideInFavorResult > sideAgainstResult;
                return valid ? WIN_ALL : LOSE_ALL;
            }
            if (betType_ == uint8(BetType.DRAW)) {
                valid = sideInFavorResult == sideAgainstResult;
                return valid ? WIN_ALL : LOSE_ALL;
            }

            if (betType_ == uint8(BetType.BOTH_TEAM_SCORE)) {
                valid = betData_ != 0
                    ? sideInFavorResult * sideAgainstResult != 0
                    : sideInFavorResult + sideAgainstResult == 0;
                return valid ? WIN_ALL : LOSE_ALL;
            }
        }

        return LOSE_ALL;
    }
}