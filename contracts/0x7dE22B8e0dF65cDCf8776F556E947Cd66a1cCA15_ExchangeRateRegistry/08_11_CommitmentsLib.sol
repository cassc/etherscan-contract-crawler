// SPDX-License-Identifier: BUSL-1.1
/*
██████╗░██╗░░░░░░█████╗░░█████╗░███╗░░░███╗
██╔══██╗██║░░░░░██╔══██╗██╔══██╗████╗░████║
██████╦╝██║░░░░░██║░░██║██║░░██║██╔████╔██║
██╔══██╗██║░░░░░██║░░██║██║░░██║██║╚██╔╝██║
██████╦╝███████╗╚█████╔╝╚█████╔╝██║░╚═╝░██║
╚═════╝░╚══════╝░╚════╝░░╚════╝░╚═╝░░░░░╚═╝
*/

pragma solidity 0.8.19;

import {SafeCastLib} from "solady/utils/SafeCastLib.sol";

struct AssetCommitment {
    address owner;
    uint128 committedAmount;
    uint128 cumulativeAmountEnd;
}

struct Commitments {
    mapping(uint256 => AssetCommitment) commitments;
    uint64 commitmentCount;
    uint192 totalAssetsCommitted;
}

library CommitmentsLib {
    using SafeCastLib for uint256;

    error NonexistentCommit();

    function add(Commitments storage commitments, address owner, uint256 amount)
        internal
        returns (uint256 newCommitmendId, uint256 cumulativeAmountEnd)
    {
        uint256 commitmentCount = commitments.commitmentCount;
        unchecked {
            newCommitmendId = commitmentCount++;
        }
        cumulativeAmountEnd = commitments.totalAssetsCommitted + amount;
        commitments.commitments[newCommitmendId] = AssetCommitment({
            owner: owner,
            committedAmount: uint128(amount),
            cumulativeAmountEnd: cumulativeAmountEnd.toUint128()
        });
        commitments.commitmentCount = commitmentCount.toUint64();
        // If safe cast to uint128 did not fail cast to uint192 cannot truncate.
        commitments.totalAssetsCommitted = uint192(cumulativeAmountEnd);
    }

    function getAmountSplit(AssetCommitment storage commitment, uint256 totalIncludedAmount)
        internal
        view
        returns (uint256 includedAmount, uint256 excludedAmount)
    {
        uint256 committedAmount = commitment.committedAmount;
        uint256 cumulativeAmountEnd = commitment.cumulativeAmountEnd;
        if (totalIncludedAmount >= cumulativeAmountEnd) {
            includedAmount = committedAmount;
            excludedAmount = 0;
        } else {
            uint256 cumulativeAmountStart = cumulativeAmountEnd - committedAmount;
            if (cumulativeAmountStart > totalIncludedAmount) {
                includedAmount = 0;
                excludedAmount = committedAmount;
            } else {
                unchecked {
                    includedAmount = totalIncludedAmount - cumulativeAmountStart;
                    excludedAmount = committedAmount - includedAmount;
                }
            }
        }
    }

    function get(Commitments storage commitments, uint256 id) internal view returns (AssetCommitment storage) {
        if (id >= commitments.commitmentCount) {
            revert NonexistentCommit();
        }
        return commitments.commitments[id];
    }
}