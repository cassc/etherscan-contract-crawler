// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;
pragma experimental ABIEncoderV2;

import './IERC20.sol';

interface IDexe is IERC20 {
    enum HolderRoundStatus {None, Received}

    struct HolderRound {
        uint120 deposited; // USDC
        uint128 endBalance; // DEXE
        HolderRoundStatus status;
    }

    struct UserInfo {
        uint128 balanceBeforeLaunch; // Final balance before product launch.
        uint120 firstRoundLimit; // limit of USDC that could deposited in first round
        uint8 firstRoundDeposited; // First round when holder made a deposit or received DEXE.
    }

    struct BalanceInfo {
        uint32 firstBalanceChange; // Timestamp of first tokens receive.
        uint32 lastBalanceChange; // Timestamp of last balance change.
        uint128 balanceAverage; // Average balance for the previous period.
        uint balanceAccumulator; // Accumulates average for current period.
    }

    function launchedAfter() external view returns (uint);
    function launchDate() external view returns(uint);
    function tokensaleEndDate() external view returns (uint);
    function holderRounds(uint _round, address _holder) external view returns(HolderRound memory);
    function usersInfo(address _holder) external view returns(UserInfo memory);
    function getAverageBalance(address _holder) external view returns(uint);
    function firstBalanceChange(address _holder) external view returns(uint);
}