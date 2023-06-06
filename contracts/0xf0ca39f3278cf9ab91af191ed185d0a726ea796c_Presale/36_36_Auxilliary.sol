// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./LaunchPadLib.sol";
import "./AuxLibrary.sol";

interface ILocker {
    function unlockCycles() view external returns(uint);
    function unlockSchedule(uint cycle) view external returns(AuxLibrary.UnlockScheduleInternal memory);
    function lockerInfo() view external returns(AuxLibrary.LockerInfo memory);
}

interface IPresale {
    function tokenInfo() view external returns(LaunchPadLib.TokenInfo memory);
    function presaleTimes() view external returns(LaunchPadLib.PresaleTimes memory);
    function finalizingTime() view external returns(uint);
    function temaVestingCycles() view external returns(uint);
    function teamVestingRecord(uint cycle) view external returns(AuxLibrary.TeamVestingRecordInternal memory);
    function teamVesting() view external returns(LaunchPadLib.TeamVesting memory);

    function participant(address _address) view external returns(AuxLibrary.Participant memory);
    function contributorVestingRecord(uint cycle) view external returns(AuxLibrary.ContributorsVestingRecordInternal memory);
    function contributorCycles() view external returns(uint);
    function getContributorReleaseStatus(uint _time, address _address) view external returns(uint8);

    function uniswapV2Router02() view external returns (address);
}

interface IUniswapRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

interface IUniswapFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

contract Auxilliary {

    function getLockerSchedule(ILocker locker) public view returns(AuxLibrary.UnlockSchedule[] memory)  {
        uint tokensLocked = locker.lockerInfo().numOfTokensLocked;
        uint cycles = locker.unlockCycles();
        AuxLibrary.UnlockSchedule[] memory unlockSchedule = new AuxLibrary.UnlockSchedule[](cycles+1);

        for(uint i=0; i <= cycles; i++){
            AuxLibrary.UnlockScheduleInternal memory schedule = locker.unlockSchedule(i);
            unlockSchedule[i].cycle = schedule.cycle;
            unlockSchedule[i].releaseTime = schedule.releaseTime;
            unlockSchedule[i].tokens = tokensLocked * schedule.percentageToRelease * schedule.tokensPC / 10000;
            unlockSchedule[i].releaseStatus = schedule.releaseStatus;
        }

        return unlockSchedule;
    }

    function getTeamVestingSchedule(IPresale presale) public view returns(AuxLibrary.TeamVestingRecord[] memory)  {
        uint decimals = presale.tokenInfo().decimals;
        uint tokensLocked = presale.teamVesting().vestingTokens;
        uint finalizingTime = presale.finalizingTime();
        uint expiredAt = presale.presaleTimes().expiredAt;

        if (finalizingTime == 0) {
            finalizingTime = expiredAt;
        }

        uint cycles = presale.temaVestingCycles();
        AuxLibrary.TeamVestingRecord[] memory unlockSchedule = new AuxLibrary.TeamVestingRecord[](cycles+1);

        for(uint i=0; i <= cycles; i++){
            AuxLibrary.TeamVestingRecordInternal memory schedule = presale.teamVestingRecord(i);
            unlockSchedule[i].cycle = schedule.cycle;
            unlockSchedule[i].releaseTime = finalizingTime + schedule.releaseTime;
            unlockSchedule[i].tokens = (tokensLocked * schedule.percentageToRelease * schedule.tokensPC * (10**decimals)) / 10000;
            unlockSchedule[i].releaseStatus = schedule.releaseStatus;
        }

        return unlockSchedule;

    }

    function getContributorVestingSchedule(IPresale presale, address _address) public view returns(AuxLibrary.ContributorsVestingRecord[] memory)  {
        uint tokens = presale.participant(_address).tokens;
        uint finalizingTime = presale.finalizingTime();
        uint expiredAt = presale.presaleTimes().expiredAt;

        if (finalizingTime == 0) {
            finalizingTime = expiredAt;
        }

        uint cycles = presale.contributorCycles();
        AuxLibrary.ContributorsVestingRecord[] memory unlockSchedule = new AuxLibrary.ContributorsVestingRecord[](cycles+1);

        for (uint i=0; i <= cycles; i++){
            AuxLibrary.ContributorsVestingRecordInternal memory schedule = presale.contributorVestingRecord(i);
            uint8 releaseStatus = presale.getContributorReleaseStatus(finalizingTime + schedule.releaseTime, _address);
            unlockSchedule[i].cycle = schedule.cycle;
            unlockSchedule[i].releaseTime = finalizingTime + schedule.releaseTime;
            unlockSchedule[i].tokens = (tokens * schedule.percentageToRelease * schedule.tokensPC ) / 10000;
            unlockSchedule[i].releaseStatus = releaseStatus;
        }

        return unlockSchedule;

    }

    function getPresaleLpBalance(IPresale presale) public view returns(address _lpToken, uint256 _balance) {

        IUniswapRouter router = IUniswapRouter(presale.uniswapV2Router02());
        IUniswapFactory factory = IUniswapFactory(router.factory());

        address wethAddress = router.WETH();
        address pairAddress = factory.getPair(presale.tokenInfo().tokenAddress, wethAddress);

        if (pairAddress == address(0)) {
            return (address(0), 0);
        }

        uint balance = IERC20(pairAddress).balanceOf(address(presale));
        return (pairAddress, balance);
    }
}