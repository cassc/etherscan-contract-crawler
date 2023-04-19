// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts-0.8/security/Pausable.sol";
import "@openzeppelin/contracts-0.8/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-0.8/security/ReentrancyGuard.sol";

import "../utils/AccessProtected-0.8.sol";

import "./InterestCalculator.sol";

contract ArcLPTokenStaking is
    AccessProtected,
    ReentrancyGuard,
    InterestCalculator
{
    IERC20 public arc;
    uint public stoppedAt;

    mapping(address => mapping(address => Stake)) public stakeOf;

    mapping(address => bool) public isListedLPToken;

    event Staked(address indexed token, address indexed user, uint amount);
    event SetTokenListing(address token, bool enabled);
    event StakingStopped(uint at);

    event UnStaked(
        address indexed user,
        address indexed token,
        uint amount,
        uint rewards
    );

    struct Stake {
        uint amount;
        uint interestGained;
        uint lastStakedAt;
    }

    constructor(address _arc, uint _rate) InterestCalculator(_rate) {
        arc = IERC20(_arc);
    }

    function stake(
        address token,
        uint amount
    ) external whenNotPaused nonReentrant {
        require(isListedLPToken[token], "Stake is not allowed for this token");

        uint time = block.timestamp;
        require(stoppedAt == 0, "Staking is no longer allowed");

        address caller = _msgSender();
        Stake memory s = stakeOf[caller][token];
        uint rewards = calculateRewards(s.lastStakedAt, s.amount);
        IERC20(token).transferFrom(caller, address(this), amount);

        stakeOf[caller][token] = Stake({
            lastStakedAt: time,
            amount: s.amount + amount,
            interestGained: rewards
        });

        emit Staked(token, caller, amount);
    }

    function unstake(
        address token,
        uint amount
    ) external whenNotPaused nonReentrant {
        address caller = _msgSender();

        Stake memory s = stakeOf[caller][token];
        require(s.amount >= amount, "Invalid amount");

        uint rewards = calculateRewards(s.lastStakedAt, amount) +
            s.interestGained;

        stakeOf[caller][token].amount -= amount;
        stakeOf[caller][token].interestGained = 0;

        IERC20 pair = IERC20(token);

        pair.transfer(caller, amount);
        arc.transfer(caller, rewards);

        emit UnStaked(caller, token, amount, rewards);
    }

    function calculateRewards(
        uint time,
        uint amount
    ) internal view returns (uint) {
        uint current = block.timestamp;
        uint ending = (stoppedAt == 0 ? current : stoppedAt);

        return _earned(amount, time, ending);
    }

    function stopStaking() external onlyOwner {
        stoppedAt = block.timestamp;
        emit StakingStopped(block.timestamp);
    }

    function setTokenListing(address token, bool enabled) external onlyAdmin {
        isListedLPToken[token] = enabled;
        emit SetTokenListing(token, enabled);
    }

    function updateInterest(uint rate) external onlyOwner {
        _updateInterest(rate);
    }
}