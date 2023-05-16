// SPDX-License-Identifier: MIT

// solhint-disable-next-line
pragma solidity 0.8.2;

import "./CustomDTOs.sol";

abstract contract CustomProcessor {
    // Refund main token and alter token(if pay alter fee)
    // Only after expiration + expirationDelay call without bet closed action
    function processRefundingCustomBet(CustomDTOs.CustomMatchingInfo storage info, CustomDTOs.JoinCustomBetClientList storage clientList) internal returns (uint) {
        uint resultAmount;
        for (uint i = 0; i < clientList.length; ++i) {
            CustomDTOs.JoinCustomBetClient storage joinClient = extractCustomJoinBetClientByRef(info, clientList.joinListRefs[i]);
            resultAmount += joinClient.freeAmount;
            resultAmount += joinClient.lockedAmount;

            joinClient.freeAmount = 0;
            joinClient.lockedAmount = 0;
        }

        return resultAmount;
    }

    // Evaluate mainToken for giving prize and modify joins
    // returns (mainToken amount)
    function takePrize(CustomDTOs.CustomBet storage bet, CustomDTOs.CustomMatchingInfo storage info, CustomDTOs.JoinCustomBetClientList storage clientList) internal returns (uint) {
        uint resultAmount;
        for (uint i = 0; i < clientList.length; ++i) {
            CustomDTOs.JoinCustomBetClient storage joinClient = extractCustomJoinBetClientByRef(info, clientList.joinListRefs[i]);
            if (joinClient.targetSide) {
                // left side
                if (bet.targetSideWon) {
                    resultAmount += applyCoefficient(joinClient.lockedAmount, bet.coefficient, true);
                    joinClient.lockedAmount = 0;
                }
            } else {
                // right side
                if (!bet.targetSideWon) {
                    resultAmount += applyCoefficient(joinClient.lockedAmount, bet.coefficient, false);
                    joinClient.lockedAmount = 0;
                }
            }
            resultAmount += joinClient.freeAmount;

            joinClient.freeAmount = 0;
        }

        return resultAmount;
    }

    // Evaluate mainToken for giving prize
    // returns (mainToken amount)
    function evaluatePrize(CustomDTOs.CustomBet storage bet, CustomDTOs.CustomMatchingInfo storage info, CustomDTOs.JoinCustomBetClientList storage clientList) internal view returns (uint) {
        uint resultAmount;
        for (uint i = 0; i < clientList.length; ++i) {
            CustomDTOs.JoinCustomBetClient storage joinClient = extractCustomJoinBetClientByRef(info, clientList.joinListRefs[i]);
            if (joinClient.targetSide) {
                // left side
                if (bet.targetSideWon) {
                    resultAmount += applyCoefficient(joinClient.lockedAmount, bet.coefficient, true);
                }
            } else {
                // right side
                if (!bet.targetSideWon) {
                    resultAmount += applyCoefficient(joinClient.lockedAmount, bet.coefficient, false);
                }
            }
            resultAmount += joinClient.freeAmount;
        }

        return resultAmount;
    }

    // Evaluate mainToken and alternativeToken for refunding
    // returns (mainToken amount, alternativeToken amount)
    function cancelCustomBet(CustomDTOs.CustomMatchingInfo storage info, CustomDTOs.JoinCustomBetClient storage joinClient) internal returns (uint) {
        uint freeAmount = joinClient.freeAmount;
        if (joinClient.targetSide) {
            // left side
            info.leftFree -= freeAmount;
        } else {
            // right side
            info.rightFree -= freeAmount;
        }

        joinClient.freeAmount = 0;

        return freeAmount;
    }

    function joinCustomBet(CustomDTOs.CustomBet storage bet, CustomDTOs.CustomMatchingInfo storage info, CustomDTOs.JoinCustomBetClient memory joinCustomRequestBet) internal returns (CustomDTOs.JoinCustomBetClient storage, uint) {
        // not xor
        if (joinCustomRequestBet.targetSide) {
            // left side
            processLeft(info, joinCustomRequestBet, bet.coefficient);
            return (info.leftSide[info.leftLength - 1], info.leftLength - 1);
        } else {
            // right side
            processRight(info, joinCustomRequestBet, bet.coefficient);
            return (info.rightSide[info.rightLength - 1], info.rightLength - 1);
        }
    }

    function processLeft(CustomDTOs.CustomMatchingInfo storage info, CustomDTOs.JoinCustomBetClient memory joinRequest, uint coefficient) private {
        joinRequest.id = info.leftLength;
        info.leftSide[info.leftLength++] = joinRequest;
        CustomDTOs.JoinCustomBetClient storage joinRequestStored = info.leftSide[info.leftLength - 1];
        if (info.leftFree > 0) {
            // if there are free amounts
            // just add to the end of left bet queue
        } else {
            // recursion update with other side
            // update right last id
            info.rightLastId = mapToOtherSide(info.rightSide, info, info.rightLastId, joinRequestStored, coefficient, true);
        }

        info.leftFree += joinRequestStored.freeAmount;
        info.leftLocked += joinRequestStored.lockedAmount;

        info.rightFree -= applyPureCoefficientMapping(joinRequestStored.lockedAmount, coefficient, true);
        info.rightLocked += applyPureCoefficientMapping(joinRequestStored.lockedAmount, coefficient, true);
    }

    function processRight(CustomDTOs.CustomMatchingInfo storage info, CustomDTOs.JoinCustomBetClient memory joinRequest, uint coefficient) private {
        joinRequest.id = info.rightLength;
        info.rightSide[info.rightLength++] = joinRequest;
        CustomDTOs.JoinCustomBetClient storage joinRequestStored = info.rightSide[info.rightLength - 1];
        if (info.rightFree > 0) {
            // if there are free amounts
            // just add to the end of right bet queue
        } else {
            // recursion update with other side
            // update left last id
            info.leftLastId = mapToOtherSide(info.leftSide, info, info.leftLastId, joinRequestStored, coefficient, false);
        }

        info.rightFree += joinRequestStored.freeAmount;
        info.rightLocked += joinRequestStored.lockedAmount;

        info.leftFree -= applyPureCoefficientMapping(joinRequestStored.lockedAmount, coefficient, false);
        info.leftLocked += applyPureCoefficientMapping(joinRequestStored.lockedAmount, coefficient, false);
    }

    // Match joinRequest amount with otherSides values
    // recursion call(iteration by otherSide array)
    function mapToOtherSide(mapping(uint => CustomDTOs.JoinCustomBetClient) storage otherSide,
        CustomDTOs.CustomMatchingInfo storage info,
        uint otherLastId, CustomDTOs.JoinCustomBetClient storage joinRequest,
        uint coefficient, bool direct) private returns (uint) {

        // End of other side
        if (otherSide[otherLastId].client == address(0)) {
            return otherLastId;
        }

        // Found cancelled bet or fully bet
        if (otherSide[otherLastId].freeAmount == 0) {
            return mapToOtherSide(otherSide, info, otherLastId + 1, joinRequest, coefficient, direct);
        }

        uint freeAmountWithCoefficient = applyPureCoefficientMapping(joinRequest.freeAmount, coefficient, direct);

        // Other side fully locked current joinRequest
        // end of recursion
        if (otherSide[otherLastId].freeAmount >= freeAmountWithCoefficient) {
            otherSide[otherLastId].freeAmount -= freeAmountWithCoefficient;
            otherSide[otherLastId].lockedAmount += freeAmountWithCoefficient;

            joinRequest.lockedAmount += joinRequest.freeAmount;
            joinRequest.freeAmount = 0;
            return otherLastId;
        }

        // Current joinRequest more than otherSide bet
        // Continue with next bet by other side recursive iteration
        uint otherFreeAmount = applyPureCoefficientMapping(otherSide[otherLastId].freeAmount, coefficient, !direct);

        joinRequest.lockedAmount += otherFreeAmount;
        joinRequest.freeAmount -= otherFreeAmount;

        otherSide[otherLastId].lockedAmount += otherSide[otherLastId].freeAmount;
        otherSide[otherLastId].freeAmount = 0;
        // recursion call with next otherLastId
        return mapToOtherSide(otherSide, info, otherLastId + 1, joinRequest, coefficient, direct);
    }

    function extractCustomJoinBetClientByRef(CustomDTOs.CustomMatchingInfo storage info, CustomDTOs.JoinCustomBetClientRef storage ref) internal view returns (CustomDTOs.JoinCustomBetClient storage) {
        if (ref.side) {
            return info.leftSide[ref.id];
        } else {
            return info.rightSide[ref.id];
        }
    }

    uint private constant coefficientDecimals = 10 ** 9;

    function applyPureCoefficientMapping(uint amount, uint coefficient, bool direct) private pure returns (uint) {
        if (amount == 0) {
            return 0;
        }
        return applyCoefficient(amount, coefficient, direct) - amount;
    }

    function applyCoefficient(uint amount, uint coefficient, bool direct) private pure returns (uint) {
        if (amount == 0) {
            return 0;
        }

        if (direct) {
            return (amount * coefficient) / coefficientDecimals;
        } else {
            return (amount * ((coefficientDecimals ** 2) / (coefficient - coefficientDecimals) + coefficientDecimals)) / coefficientDecimals;
        }
    }
}