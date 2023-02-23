// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract StakingDYNA is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    uint256 public apr = 3200;
    uint256 constant RATE_PRECISION = 10000;
    uint256 constant ONE_YEAR_IN_SECONDS = 365 * 24 * 60 * 60;
    uint256 constant ONE_DAY_IN_SECONDS = 24 * 60 * 60;

    uint256 constant PERIOD_PRECISION = 10000;
    IERC20 public token;

    bool public enabled;

    modifier noContract() {
        require(
            tx.origin == msg.sender,
            "StakingDYNA: Contract not allowed to interact"
        );
        _;
    }

    event Deposit(address indexed user, uint256 amount);
    event Redeem(address indexed user, uint256 amount);

    constructor(IERC20 _token) {
        token = _token;
    }

    struct StakeDetail {
        uint256 principal;
        uint256 lastProcessAt;
        uint256 pendingReward;
        uint256 firstStakeAt;
    }

    mapping(address => StakeDetail) public stakers;

    function setEnabled(bool _enabled) external onlyOwner {
        enabled = _enabled;
    }

    function updateAPR(uint256 _apr) external onlyOwner {
        apr = _apr;
    }

    function emergencyWithdraw(uint256 _amount) external onlyOwner {
        token.transfer(msg.sender, _amount);
    }

    function getStakeDetail(address _staker)
        public
        view
        returns (
            uint256 principal,
            uint256 pendingReward,
            uint256 lastProcessAt,
            uint256 firstStakeAt
        )
    {
        StakeDetail memory stakeDetail = stakers[_staker];
        return (
            stakeDetail.principal,
            stakeDetail.pendingReward,
            stakeDetail.lastProcessAt,
            stakeDetail.firstStakeAt
        );
    }

    function getInterest(address _staker) public view returns (uint256) {
        StakeDetail memory stakeDetail = stakers[_staker];
        uint256 duration = block.timestamp.sub(stakeDetail.lastProcessAt);
        uint256 interest = stakeDetail
            .principal
            .mul(apr)
            .mul(duration)
            .div(ONE_YEAR_IN_SECONDS)
            .div(RATE_PRECISION);
        return interest.add(stakeDetail.pendingReward);
    }

    function deposit(uint256 _stakeAmount) external nonReentrant noContract {
        require(enabled, "Staking is not enabled");
        require(
            _stakeAmount > 0,
            "StakingDYNA: stake amount must be greater than 0"
        );
        token.transferFrom(msg.sender, address(this), _stakeAmount);
        StakeDetail storage stakeDetail = stakers[msg.sender];
        if (stakeDetail.firstStakeAt == 0) {
            stakeDetail.principal = stakeDetail.principal.add(_stakeAmount);
            stakeDetail.firstStakeAt = stakeDetail.firstStakeAt == 0
                ? block.timestamp
                : stakeDetail.firstStakeAt;
        } else {
            uint256 interest = getInterest(msg.sender);
            stakeDetail.principal = stakeDetail.principal.add(_stakeAmount).add(
                interest
            );
        }
        stakeDetail.lastProcessAt = block.timestamp;

        emit Deposit(msg.sender, _stakeAmount);
    }

    function redeem(uint256 _redeemAmount) external nonReentrant noContract {
        require(enabled, "Staking is not enabled");
        StakeDetail storage stakeDetail = stakers[msg.sender];
        require(stakeDetail.firstStakeAt > 0, "StakingDYNA: no stake");

        uint256 interest = getInterest(msg.sender);

        uint256 claimAmount = interest.mul(_redeemAmount).div(
            stakeDetail.principal
        );

        uint256 remainAmount = interest.sub(claimAmount);

        stakeDetail.lastProcessAt = block.timestamp;
        require(
            stakeDetail.principal >= _redeemAmount,
            "StakingDYNA: redeem amount must be less than principal"
        );
        stakeDetail.principal = stakeDetail.principal.sub(_redeemAmount);
        stakeDetail.pendingReward = remainAmount;
        require(
            token.transfer(msg.sender, _redeemAmount.add(claimAmount)),
            "StakingDYNA: transfer failed"
        );
        emit Redeem(msg.sender, _redeemAmount.add(claimAmount));
    }
}