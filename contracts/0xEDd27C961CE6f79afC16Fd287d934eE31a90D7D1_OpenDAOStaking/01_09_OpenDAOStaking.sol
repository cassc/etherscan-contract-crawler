// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OpenDAOStaking is ERC20("veSOS", "veSOS"), Ownable {
    using SafeERC20 for IERC20;
    using SafeCast for int256;
    using SafeCast for uint256;

    struct Config {
        // Timestamp in seconds is small enough to fit into uint64
        uint64 periodFinish;
        uint64 periodStart;

        // Staking incentive rewards to distribute in a steady rate
        uint128 totalReward;
    }

    IERC20 public sos;
    Config public config;

    /*
     * Construct an OpenDAOStaking contract.
     *
     * @param _sos the contract address of SOS token
     * @param _periodStart the initial start time of rewards period
     * @param _rewardsDuration the duration of rewards in seconds
     */
    constructor(IERC20 _sos, uint64 _periodStart, uint64 _rewardsDuration) {
        require(address(_sos) != address(0), "OpenDAOStaking: _sos cannot be the zero address");
        sos = _sos;
        setPeriod(_periodStart, _rewardsDuration);
    }

    /*
     * Add SOS tokens to the reward pool.
     *
     * @param _sosAmount the amount of SOS tokens to add to the reward pool
     */
    function addRewardSOS(uint256 _sosAmount) external {
        Config memory cfg = config;
        require(block.timestamp < cfg.periodFinish, "OpenDAOStaking: Adding rewards is forbidden");

        sos.safeTransferFrom(msg.sender, address(this), _sosAmount);
        cfg.totalReward += _sosAmount.toUint128();
        config = cfg;
    }

    /*
     * Set the reward peroid. If only possible to set the reward period after last rewards have been
     * expired.
     *
     * @param _periodStart timestamp of reward starting time
     * @param _rewardsDuration the duration of rewards in seconds
     */
    function setPeriod(uint64 _periodStart, uint64 _rewardsDuration) public onlyOwner {
        require(_periodStart >= block.timestamp, "OpenDAOStaking: _periodStart shouldn't be in the past");
        require(_rewardsDuration > 0, "OpenDAOStaking: Invalid rewards duration");

        Config memory cfg = config;
        require(cfg.periodFinish < block.timestamp, "OpenDAOStaking: The last reward period should be finished before setting a new one");

        uint64 _periodFinish = _periodStart + _rewardsDuration;
        config.periodStart = _periodStart;
        config.periodFinish = _periodFinish;
        config.totalReward = 0;
    }

    /*
     * Returns the staked sos + release rewards
     *
     * @returns amount of available sos
     */
    function getSOSPool() public view returns(uint256) {
        return sos.balanceOf(address(this)) - frozenRewards();
    }

    /*
     * Returns the frozen rewards
     *
     * @returns amount of frozen rewards
     */
    function frozenRewards() public view returns(uint256) {
        Config memory cfg = config;

        uint256 time = block.timestamp;
        uint256 remainingTime;
        uint256 duration = uint256(cfg.periodFinish) - uint256(cfg.periodStart);

        if (time <= cfg.periodStart) {
            remainingTime = duration;
        } else if (time >= cfg.periodFinish) {
            remainingTime = 0;
        } else {
            remainingTime = cfg.periodFinish - time;
        }

        return remainingTime * uint256(cfg.totalReward) / duration;
    }

    /*
     * Staking specific amount of SOS token and get corresponding amount of veSOS
     * as the user's share in the pool
     *
     * @param _sosAmount
     */
    function enter(uint256 _sosAmount) external {
        require(_sosAmount > 0, "OpenDAOStaking: Should at least stake something");

        uint256 totalSOS = getSOSPool();
        uint256 totalShares = totalSupply();

        sos.safeTransferFrom(msg.sender, address(this), _sosAmount);

        if (totalShares == 0 || totalSOS == 0) {
            _mint(msg.sender, _sosAmount);
        } else {
            uint256 _share = _sosAmount * totalShares / totalSOS;
            _mint(msg.sender, _share);
        }
    }

    /*
     * Redeem specific amount of veSOS to SOS tokens according to the user's share in the pool.
     * veSOS will be burnt.
     *
     * @param _share
     */
    function leave(uint256 _share) external {
        require(_share > 0, "OpenDAOStaking: Should at least unstake something");

        uint256 totalSOS = getSOSPool();
        uint256 totalShares = totalSupply();

        _burn(msg.sender, _share);

        uint256 _sosAmount = _share * totalSOS / totalShares;
        sos.safeTransfer(msg.sender, _sosAmount);
    }
}