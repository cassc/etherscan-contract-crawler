// SPDX-License-Identifier: MIT

/// @title Interface for Saturna Lottery Contract

pragma solidity ^0.8.6;
import {RNGInterface} from "./RNGInterface.sol";

interface ISaturnaLotteryHub {
    event EntryFeeChanged(uint256 entryFee);
    event DurationChanged(uint256 duration);
    event HouseFeePercentageChanged(uint256 houseFeePercentage);
    event HouseFeePercentageLocked();
    event LotteryEntered(address user, uint256 time);
    event RNGUpdated(RNGInterface rngService);
    event LotteryCreated(uint256 lotteryId, uint256 startTime, uint256 endTime);
    event LotterySetteled(uint256 lotteryId);
    event WinnerDeclared(address winner, uint256 time);
    event WinnerPaid(address winner, uint256 jackpot);
    event CommissionIssued(address owner, uint256 reward);
    event WinnerDeclaredAndPaid(address winner, uint256 pool, uint256 time);

    error SaturnaLotteryHub__HouseFeePercentageLocked();
    error SaturnaLotteryHub__LotteryExipered();
    error SaturnaLotteryHub__NotEnoughUSDC();
    error SaturnaLotteryHub__AlreadyEnteredThisLottery();
    error SaturnaLotteryHub__LotteryHasNotEnded();
    error SaturnaLotteryHub__AddressIsZero();
    error SaturnaLotteryHub__InsufficentUSDCInContract();
    error SaturnaLotteryHub__CannotEnterLotteryEnteryBufferExpired();

    struct Lottery {
        // Id for lottery
        uint256 lotteryId;
        // The time when lottery started
        uint256 startTime;
        // The time when lottery will end
        uint256 endTime;
        // The entry fees for lottery in USDC
        uint256 entryFee;
        // Total entries
        uint256 entries;
        // The winner for lottery
        address payable winner;
        // Wheather or not lottery has been setteled or not
        bool setteled;
    }
}