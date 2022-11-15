//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IStakingEvent{

    /// @dev                this event occurs when set epoch info
    /// @param length       epoch's length(seconds)
    /// @param end          epoch's end time(seconds)
    event SetEpochInfo(
        uint256 length,
        uint256 end
    );


    /// @dev                    this event occurs when set addresses
    /// @param tosAddress       tos address
    /// @param lockTOSAddress   lockTOS address
    /// @param treasuryAddress  treasury address
    event SetAddressInfos(
        address tosAddress,
        address lockTOSAddress,
        address treasuryAddress
    );

    /// @dev                     this event occurs when set rebasePerEpoch data
    /// @param rebasePerEpoch    rebase rate Per Epoch
    event SetRebasePerEpoch(
        uint256 rebasePerEpoch
    );

    /// @dev            this event occurs when set index
    /// @param index    index
    event SetIndex(
        uint256 index
    );

    /// @dev            this event occurs when set the default lockup period(second)
    /// @param period   the default lockup period(second) when bonding.
    event SetBasicBondPeriod(
        uint256 period
    );


    /// @dev            this event occurs when bonding without sTOS
    /// @param to       user address
    /// @param amount   TOS amount used for staking
    /// @param ltos     LTOS amount from staking
    /// @param marketId marketId
    /// @param stakeId  stakeId
    /// @param tosPrice amount of TOS per 1 ETH
    event StakedByBond(
        address to,
        uint256 amount,
        uint256 ltos,
        uint256 marketId,
        uint256 stakeId,
        uint256 tosPrice
    );

    /// @dev                 this event occurs when bonding with sTOS
    /// @param to            user address
    /// @param amount        TOS amount used for staking
    /// @param ltos          LTOS amount from staking
    /// @param periodWeeks   lock period
    /// @param marketId      marketId
    /// @param stakeId       stakeId
    /// @param stosId        sTOSId
    /// @param tosPrice      amount of TOS per 1 ETH
    /// @param stosPrincipal number of TOS used for sTOS calculation
    event StakedGetStosByBond(
        address to,
        uint256 amount,
        uint256 ltos,
        uint256 periodWeeks,
        uint256 marketId,
        uint256 stakeId,
        uint256 stosId,
        uint256 tosPrice,
        uint256 stosPrincipal
    );

    /// @dev           this event occurs when staking without sTOS
    /// @param to      user address
    /// @param amount  TOS amount used for staking
    /// @param stakeId stakeId
    event Staked(address to, uint256 amount, uint256 stakeId);

    /// @dev                 this event occurs when staking with sTOS
    /// @param to            user address
    /// @param amount        TOS amount used for staking
    /// @param periodWeeks   lock period
    /// @param stakeId       stakeId
    /// @param stosId        sTOSId
    /// @param stosPrincipal number of TOS used for sTOS calculation
    event StakedGetStos(
        address to,
        uint256 amount,
        uint256 periodWeeks,
        uint256 stakeId,
        uint256 stosId,
        uint256 stosPrincipal
    );

    /// @dev           this event occurs when additional TOS is used for staking for LTOS
    /// @param to      user address
    /// @param amount  additional TOS used for staking
    /// @param stakeId stakeId
    event IncreasedAmountForSimpleStake(address to, uint256 amount, uint256 stakeId);


    /// @dev                 this event occurs when staking amount or/and lockup period is updated after the lockup period is passed
    /// @param to            user address
    /// @param addAmount     additional TOS used for staking
    /// @param claimAmount   amount of LTOS to claim
    /// @param periodWeeks   lock period
    /// @param stakeId       stakeId
    /// @param stosId        sTOSId
    /// @param stosPrincipal number of TOS used for sTOS calculation
    event ResetStakedGetStosAfterLock(
        address to,
        uint256 addAmount,
        uint256 claimAmount,
        uint256 periodWeeks,
        uint256 stakeId,
        uint256 stosId,
        uint256 stosPrincipal
    );

    /// @dev                 this event occurs when staking amount or/and lockup period is updated before the lockup period is passed
    /// @param staker        user address
    /// @param amount        additional TOS used for staking
    /// @param unlockWeeks   lock period
    /// @param stakeId       stakeId
    /// @param stosId        sTOSId
    /// @param stosPrincipal number of TOS used for sTOS calculation
    event IncreasedBeforeEndOrNonEnd(
        address staker,
        uint256 amount,
        uint256 unlockWeeks,
        uint256 stakeId,
        uint256 stosId,
        uint256 stosPrincipal
    );

    /// @dev               this event occurs claim for non lock stakeId
    /// @param staker      user address
    /// @param claimAmount amount of LTOS to claim
    /// @param stakeId     stakeId
    event ClaimedForNonLock(address staker, uint256 claimAmount, uint256 stakeId);

    /// @dev           this event occurs when unstaking stakeId that has passed the lockup period
    /// @param staker  user address
    /// @param amount  amount of TOS given to the user
    /// @param stakeId stakeId
    event Unstaked(address staker, uint256 amount, uint256 stakeId);

    /// @dev              this event occurs when the LTOS index updated
    /// @param oldIndex   LTOS index before rebase() is called
    /// @param newIndex   LTOS index after rebase() is called
    /// @param totalLTOS  Total amount of LTOS
    event Rebased(uint256 oldIndex, uint256 newIndex, uint256 totalLTOS);
}