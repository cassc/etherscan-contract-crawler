// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "../interfaces/IDO/IIDOPoint.sol";
import "../interfaces/staking/IStaking.sol";
import "../interfaces/staking/ILPMining.sol";
import "../Library/SharedStructs.sol";

contract IDOPoint is Ownable, IIDOPoint {
    // Add the library methods
    using EnumerableSet for EnumerableSet.AddressSet;

    // address of playToken
    IERC20 public playToken;

    // address of lpTokens
    EnumerableSet.AddressSet private lpTokens;

    // PLAY staking and PLAY-BUSD lpMining
    IStaking public playStaking; // 30 days
    IStaking public playStakingLong; // 90 days
    IStaking public playStakingYear; // 365 days
    ILPMining public playBusdLpMining;

    // weight for unit test
    // uint256 public playWeight = 5; // 0
    // uint256 public stakedPlayWeight = 15; // 1.5; multiplied by 10
    // uint256 public stakedPlayLongWeight = 22; // 2.2; multiplied by 10
    // uint256 public stakedPlayYearWeight = 0;
    // uint256 public lpTokenWeight = 0; // 3
    // uint256 public lpTokenLockedWeight = 40; // 4
    // uint256 public constant weightMultiplier = 10;

    // weight for deploy
    uint256 public playWeight = 1467;
    uint256 public stakedPlayWeight = 1690; // 30 days
    uint256 public stakedPlayLongWeight = 1954; // 60 days 
    uint256 public stakedPlayYearWeight = 2370; // 1 year
    uint256 public lpTokenWeight = 0;
    uint256 public lpTokenLockedWeight = 0;
    uint256 public constant weightMultiplier = 10000;

    modifier isNewLp(address lp) {
        require(!lpTokens.contains(lp), "Already added");
        _;
    }

    modifier isExistLp(address lp) {
        require(lpTokens.contains(lp), "Not exist");
        _;
    }

    /**
     * get count of lpTokens
     */
    function lpCount() external view returns (uint256) {
        return lpTokens.length();
    }

    /**
     * get lpToken address at certain point
     */
    function getLP(uint256 index) external view returns (address) {
        return lpTokens.at(index);
    }

    /**
     * @notice get score of user based on balance, staked balance, lp balance, lpLocked
     */
    function getPoint(address user) external view override returns (uint256) {
        uint256 total;

        // sum play balance
        if (address(playToken) != address(0)) {
            total = total + (playWeight * playToken.balanceOf(user)) / weightMultiplier;
        }

        uint256 totalLP; // total lp balance
        uint256 lpLength = lpTokens.length();

        for (uint256 index = 0; index < lpLength; index++) {
            address lpToken = lpTokens.at(index);
            // sum up each lpToken balance
            totalLP = totalLP + IERC20(lpToken).balanceOf(user);
        }
        // sum lpBalance * lpWeight
        total = total + (totalLP * lpTokenWeight) / weightMultiplier;

        if (address(playStaking) != address(0)) {
            // sum staked play amount * stakedPlayWeight
            total = total + (playStaking.getDepositedAmount(user) * stakedPlayWeight) / weightMultiplier;
        }

        if (address(playStakingLong) != address(0)) {
            // sum staked play amount * stakedPlayLongWeight
            total = total + (playStakingLong.getDepositedAmount(user) * stakedPlayLongWeight) / weightMultiplier;
        }

        if (address(playStakingYear) != address(0)) {
            // sum staked play amount * stakedPlayYearWeight
            total = total + (playStakingYear.getDepositedAmount(user) * stakedPlayYearWeight) / weightMultiplier;
        }

        if (address(playBusdLpMining) != address(0)) {
            // sum locked playBusd amount * lpTokenLockedWeight
            total = total + (playBusdLpMining.getDepositedAmount(user) * lpTokenLockedWeight) / weightMultiplier;
        }

        return total;
    }

    /**
     * @notice add lpToken address
     */
    function removeLPToken(address lp) external onlyOwner isExistLp(lp) {
        require(lp != address(0), "Invalid address");

        lpTokens.remove(lp);
    }

    /**
     * @notice add lpToken address
     */
    function addLPToken(address lp) external onlyOwner isNewLp(lp) {
        require(lp != address(0), "Invalid address");

        lpTokens.add(lp);
    }

    /**
     * @notice set address of playBusdLpMinig lpMining (polyplay.games)
     */
    function setPlayBusdLpMining(ILPMining _playBusdLpMining) external onlyOwner {
        require(address(_playBusdLpMining) != address(0), "Invalid address");

        playBusdLpMining = _playBusdLpMining;
    }

    /**
     * @notice set address of play staking (polyplay.games)
     */
    function setPlayStakingYear(IStaking _playStakingYear) external onlyOwner {
        require(address(_playStakingYear) != address(0), "Invalid address");

        playStakingYear = _playStakingYear;
    }

    /**
     * @notice set address of play staking (polyplay.games)
     */
    function setPlayStakingLong(IStaking _playStakingLong) external onlyOwner {
        require(address(_playStakingLong) != address(0), "Invalid address");

        playStakingLong = _playStakingLong;
    }

    /**
     * @notice set address of play staking (polyplay.games)
     */
    function setPlayStaking(IStaking _playStaking) external onlyOwner {
        require(address(_playStaking) != address(0), "Invalid address");

        playStaking = _playStaking;
    }

    /**
     * @notice set address of play token
     */
    function setPlayToken(IERC20 _playToken) external onlyOwner {
        require(address(_playToken) != address(0), "Invalid address");

        playToken = _playToken;
    }

    /**
     * @notice set wegiths
     */
    function setWeights(
        uint256 _playWeight,
        uint256 _stakedPlayWeight,
        uint256 _stakedPlayLongWeight,
        uint256 _stakedPlayYearWeight,
        uint256 _lpTokenWeight,
        uint256 _lpTokenLockedWeight
    ) external onlyOwner {
        playWeight = _playWeight;
        stakedPlayWeight = _stakedPlayWeight;
        stakedPlayLongWeight = _stakedPlayLongWeight;
        stakedPlayYearWeight = _stakedPlayYearWeight;
        lpTokenWeight = _lpTokenWeight;
        lpTokenLockedWeight = _lpTokenLockedWeight;
    }
}