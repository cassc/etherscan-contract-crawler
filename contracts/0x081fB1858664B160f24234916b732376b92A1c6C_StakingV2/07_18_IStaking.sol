// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

interface IStaking {


    /* ========== onlyPolicyOwner ========== */

    /// @dev              modify epoch data
    /// @param _length    epoch's length (sec)
    /// @param _end       epoch's end time (sec)
    function setEpochInfo(
        uint256 _length,
        uint256 _end
    ) external;

    /// @dev              set tosAddress, lockTOS, treasuryAddress
    /// @param _tos       tosAddress
    /// @param _lockTOS   lockTOSAddress
    /// @param _treasury  treausryAddress
    function setAddressInfos(
        address _tos,
        address _lockTOS,
        address _treasury
    ) external;

    /// @dev                    set setRebasePerEpoch
    /// @param _rebasePerEpoch  rate for rebase per epoch (eth uint)
    ///                         If input the 0.9 -> 900000000000000000
    function setRebasePerEpoch(
        uint256 _rebasePerEpoch
    ) external;


    /// @dev            set minimum bonding period
    /// @param _period  _period (seconds)
    function setBasicBondPeriod(uint256 _period) external ;


    /* ========== onlyOwner ========== */

    /// @dev             migration of existing lockTOS contract data
    /// @param accounts  array of account for sync
    /// @param balances  array of tos amount for sync
    /// @param period    array of end time for sync
    /// @param tokenId   array of locktos id for sync
    function syncStos(
        address[] memory accounts,
        uint256[] memory balances,
        uint256[] memory period,
        uint256[] memory tokenId
    ) external ;



    /* ========== onlyBonder ========== */


    /// @dev Increment and returns the market ID.
    function generateMarketId() external returns (uint256);

    /// @dev             TOS minted from bonding is automatically staked for the user, and user receives LTOS. Lock-up period is based on the basicBondPeriod
    /// @param to        user address
    /// @param _amount   TOS amount
    /// @param _marketId market id
    /// @param tosPrice  amount of TOS per 1 ETH
    /// @return stakeId  stake id
    function stakeByBond(
        address to,
        uint256 _amount,
        uint256 _marketId,
        uint256 tosPrice
    ) external returns (uint256 stakeId);



    /// @dev                TOS minted from bonding is automatically staked for the user, and user receives LTOS and sTOS.
    /// @param _to          user address
    /// @param _amount      TOS amount
    /// @param _marketId    market id
    /// @param _periodWeeks number of lockup weeks
    /// @param tosPrice     amount of TOS per 1 ETH
    /// @return stakeId     stake id
    function stakeGetStosByBond(
        address _to,
        uint256 _amount,
        uint256 _marketId,
        uint256 _periodWeeks,
        uint256 tosPrice
    ) external returns (uint256 stakeId);


    /* ========== Anyone can execute ========== */


    /// @dev            user can stake TOS for LTOS without lockup period
    /// @param _amount  TOS amount
    /// @return stakeId stake id
    function stake(
        uint256 _amount
    ) external  returns (uint256 stakeId);


    /// @dev                user can stake TOS for LTOS and sTOS with lockup period
    /// @param _amount      TOS amount
    /// @param _periodWeeks number of lockup weeks
    /// @return stakeId     stake id
    function stakeGetStos(
        uint256 _amount,
        uint256 _periodWeeks
    ) external  returns (uint256 stakeId);


    /// @dev            increase the tos amount in stakeId of the simple stake product (without lock, without marketId)
    /// @param _stakeId stake id
    /// @param _amount  TOS amount
    function increaseAmountForSimpleStake(
        uint256 _stakeId,
        uint256 _amount
    )   external;

    /// @dev                used to update the amount of staking after the lockup period is passed
    /// @param _stakeId     stake id
    /// @param _addTosAmount   additional TOS to be staked
    /// @param _relockLtosAmount amount of LTOS to relock
    /// @param _periodWeeks lockup period
    function resetStakeGetStosAfterLock(
        uint256 _stakeId,
        uint256 _addTosAmount,
        uint256 _relockLtosAmount,
        uint256 _periodWeeks
    ) external;

    /// @dev                used to update the amount of staking after the lockup period is passed
    /// @param _stakeId     stake id
    /// @param _addTosAmount   additional TOS to be staked
    /// @param _periodWeeks lockup period
    function resetStakeGetStosAfterLock(
        uint256 _stakeId,
        uint256 _addTosAmount,
        uint256 _periodWeeks
    ) external;


    /// @dev             used to update the amount of staking before the lockup period is not passed
    /// @param _stakeId  stake id
    /// @param _amount   additional TOS to be staked
    function increaseBeforeEndOrNonEnd(
        uint256 _stakeId,
        uint256 _amount
    ) external;


    /// @dev                used to update the amount of staking before the lockup period is not passed
    /// @param _stakeId     stake id
    /// @param _amount      additional TOS to be staked
    /// @param _unlockWeeks additional lockup period
    function increaseBeforeEndOrNonEnd(
        uint256 _stakeId,
        uint256 _amount,
        uint256 _unlockWeeks
    ) external;


    /// @dev             claiming LTOS from stakeId without sTOS
    /// @param _stakeId  stake id
    /// @param claimLtos amount of LTOS to claim
    function claimForSimpleType(
        uint256 _stakeId,
        uint256 claimLtos
    ) external;


    /// @dev             used to unstake a specific staking ID
    /// @param _stakeId  stake id
    function unstake(
        uint256 _stakeId
    ) external;

    /// @dev             used to unstake multiple staking IDs
    /// @param _stakeIds stake id
    function multiUnstake(
        uint256[] calldata _stakeIds
    ) external;


    /// @dev LTOS index adjustment. Apply compound interest to the LTOS index
    function rebaseIndex() external;

    /* ========== VIEW ========== */


    /// @dev             returns the amount of LTOS for a specific stakingId.
    /// @param _stakeId  stake id
    /// @return return   LTOS balance of stakingId
    function remainedLtos(uint256 _stakeId) external view returns (uint256) ;

    /// @dev             returns the claimable amount of LTOS for a specific staking ID.
    /// @param _stakeId  stake id
    /// @return return   claimable amount of LTOS
    function claimableLtos(uint256 _stakeId) external view returns (uint256);

    /// @dev returns the current LTOS index value
    function getIndex() external view returns(uint256) ;

    /// @dev returns the LTOS index value if rebase() is called
    function possibleIndex() external view returns (uint256);

    /// @dev           returns a list of stakingIds owned by a specific account
    /// @param _addr   user account
    /// @return return list of stakingIds owned by account
    function stakingOf(address _addr)
        external
        view
        returns (uint256[] memory);

    /// @dev            returns the staked LTOS amount of the user in TOS
    /// @param _addr    user account
    /// @return balance staked LTOS amount of the user in TOS
    function balanceOf(address _addr) external view returns (uint256 balance);

    /// @dev returns the time left until next rebase
    /// @return time
    function secondsToNextEpoch() external view returns (uint256);

    /// @dev        returns amount of TOS owned by Treasury that can be used for staking interest in the future (if rebase() is not called)
    /// @return TOS returns number of TOS owned by the treasury that is not owned by the foundation nor for LTOS
    function runwayTos() external view returns (uint256);


    /// @dev        returns amount of TOS owned by Treasury that can be used for staking interest in the future (if rebase() is called)
    /// @return TOS returns number of TOS owned by the treasury that is not owned by the foundation nor for LTOS
    function runwayTosPossibleIndex() external view returns (uint256);

    /// @dev           converts TOS amount to LTOS (if rebase() is not called)
    /// @param amount  TOS amount
    /// @return return LTOS amount
    function getTosToLtos(uint256 amount) external view returns (uint256);

    /// @dev           converts LTOS to TOS (if rebase() is not called)
    /// @param ltos    LTOS Amount
    /// @return return TOS Amount
    function getLtosToTos(uint256 ltos) external view returns (uint256);


    /// @dev           converts TOS amount to LTOS (if rebase() is called)
    /// @param amount  TOS Amount
    /// @return return LTOS Amount
    function getTosToLtosPossibleIndex(uint256 amount) external view returns (uint256);

    /// @dev           converts LTOS to TOS (if rebase() is called)
    /// @param ltos    LTOS Amount
    /// @return return TOS Amount
    function getLtosToTosPossibleIndex(uint256 ltos) external view returns (uint256);

    /// @dev           returns number of LTOS staked (converted to TOS) in stakeId
    /// @param stakeId stakeId
    function stakedOf(uint256 stakeId) external view returns (uint256);

    /// @dev returns the total number of LTOS staked (converted to TOS) by users
    function stakedOfAll() external view returns (uint256) ;

    /// @dev            detailed information of specific staking ID
    /// @param stakeId  stakeId
    function stakeInfo(uint256 stakeId) external view returns (
        address staker,
        uint256 deposit,
        uint256 LTOS,
        uint256 endTime,
        uint256 marketId
    );

}