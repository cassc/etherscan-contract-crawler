// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NonTransferableToken.sol";
import "./BRRRToken.sol";
import "./sBRRRToken.sol";

contract BANKToken is NonTransferableToken {
    uint256 public constant MINT_COST_BRRR = 200_000 * (10 ** 18);
    uint256 public constant DAILY_AMOUNT = 50000 * (10 ** 18);
    uint256 public constant MAX_REWARDS = 395971 * (10 ** 18);

    BRRRToken private _brrrToken;
    sBRRRToken private _sBrrrToken;
    address private _w1;

    mapping(address => uint256[]) public _userStartTime;
    mapping(address => uint256) private _claimedRewards;

    constructor(BRRRToken brrrToken, sBRRRToken sBrrrToken, address w1) NonTransferableToken("BANK Token", "BANK") {
        _brrrToken = brrrToken;
        _sBrrrToken = sBrrrToken;
        _w1 = w1;
    }

    function mint() external {
        _brrrToken.transferFrom(msg.sender, _w1, MINT_COST_BRRR);
        _mint(msg.sender, 1);
        _userStartTime[msg.sender].push(block.timestamp);
    }

    function getUserStartTimes(address user) public view returns (uint256[] memory) {
        return _userStartTime[user];
    }


    function CalculateRewards(uint256 userStartTime) public view returns (uint256) {
        uint256 timePassed = block.timestamp - userStartTime;
        uint256 daysPassed = timePassed / 1 days;

        uint256 rewards = 0;
        uint256 dailyReward = DAILY_AMOUNT;

        for (uint256 i = 0; i < daysPassed; i++) {
            rewards += dailyReward;
            dailyReward = dailyReward * 9 / 10; // Decrease dailyReward by 10%
        }

        uint256 remainingSeconds = timePassed % 1 days;
        uint256 currentDayReward = dailyReward * remainingSeconds / 86400;
        rewards += currentDayReward;

        if (rewards > MAX_REWARDS) {
            rewards = MAX_REWARDS;
        }

        return rewards;
    }

    function calculateTotalRewards(address user) public view returns (uint256) {
        uint256[] memory userStartTimes = _userStartTime[user];
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < userStartTimes.length; i++) {
            totalRewards += CalculateRewards(userStartTimes[i]);
        }

        return totalRewards;
    }

    function calculateUnclaimedRewards(address user) public view returns (uint256) {
        uint256 totalRewards = calculateTotalRewards(user);
        uint256 unclaimedRewards = totalRewards - _claimedRewards[user];

        return unclaimedRewards;
    }

    function claimRewards() external {
        uint256 unclaimedRewards = calculateUnclaimedRewards(msg.sender);
        require(unclaimedRewards > 0, "No rewards to claim");

        _claimedRewards[msg.sender] += unclaimedRewards;
        _sBrrrToken.mint(msg.sender, unclaimedRewards);
    }
}

contract CBANKToken is NonTransferableToken {
    uint256 public constant MINT_COST_BRRR = 1_000_000 * (10 ** 18);
    uint256 public constant MINT_COST_SBRRR = 1_000_000 * (10 ** 18);
    uint256 public constant DAILY_AMOUNT = 500_000 * (10 ** 18);
    uint256 public constant MAX_REWARDS = 7_563_386 * (10 ** 18);

    BRRRToken private _brrrToken;
    sBRRRToken private _sBrrrToken;
    address private _w1;

    mapping(address => uint256[]) public _userStartTime;
    mapping(address => uint256) private _claimedRewards;

    constructor(BRRRToken brrrToken, sBRRRToken sBrrrToken, address w1) NonTransferableToken("BANK Token", "BANK") {
        _brrrToken = brrrToken;
        _sBrrrToken = sBrrrToken;
        _w1 = w1;
    }

    function mint() external {
        _brrrToken.transferFrom(msg.sender, _w1, MINT_COST_BRRR);
        _sBrrrToken.transferFrom(msg.sender, _w1, MINT_COST_SBRRR);
        _mint(msg.sender, 1);
        _userStartTime[msg.sender].push(block.timestamp);
    }

    function getUserStartTimes(address user) public view returns (uint256[] memory) {
        return _userStartTime[user];
    }

    function CalculateRewards(uint256 userStartTime) public view returns (uint256) {
        uint256 timePassed = block.timestamp - userStartTime;
        uint256 daysPassed = timePassed / 1 days;

        uint256 rewards = 0;
        uint256 dailyReward = DAILY_AMOUNT;

        for (uint256 i = 0; i < daysPassed; i++) {
            rewards += dailyReward;
            dailyReward = dailyReward * 95 / 100; // Decrease dailyReward by 5%
        }

        uint256 remainingSeconds = timePassed % 1 days;
        uint256 currentDayReward = dailyReward * remainingSeconds / 86400;
        rewards += currentDayReward;

        if (rewards > MAX_REWARDS) {
            rewards = MAX_REWARDS;
        }

        return rewards;
    }

    function calculateTotalRewards(address user) public view returns (uint256) {
        uint256[] memory userStartTimes = _userStartTime[user];
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < userStartTimes.length; i++) {
            totalRewards += CalculateRewards(userStartTimes[i]);
        }

        return totalRewards;
    }

    function calculateUnclaimedRewards(address user) public view returns (uint256) {
        uint256 totalRewards = calculateTotalRewards(user);
        uint256 unclaimedRewards = totalRewards - _claimedRewards[user];

        return unclaimedRewards;
    }

    function claimRewards() external {
        uint256 unclaimedRewards = calculateUnclaimedRewards(msg.sender);
        require(unclaimedRewards > 0, "No rewards to claim");

        _claimedRewards[msg.sender] += unclaimedRewards;
        _sBrrrToken.mint(msg.sender, unclaimedRewards);
    }
}

contract PRINTERToken is NonTransferableToken {
    uint256 public constant MINT_COST_BRRR = 10_000_000 * (10 ** 18);
    uint256 public constant MINT_COST_SBRRR = 10_000_000 * (10 ** 18);
    uint256 public constant DAILY_AMOUNT = 1_111_111 * (10 ** 18);
    uint256 public constant MAX_REWARDS = 100_000_000 * (10 ** 18);
    uint256 public constant MAX_TOKENS_PER_WALLET = 1;

    BRRRToken private _brrrToken;
    sBRRRToken private _sBrrrToken;
    address private _w1;

    mapping(address => uint256[]) public _userStartTime;
    mapping(address => uint256) private _claimedRewards;
    mapping(address => uint256) private _tokensMinted;

    constructor(BRRRToken brrrToken, sBRRRToken sBrrrToken, address w1) NonTransferableToken("BANK Token", "BANK") {
        _brrrToken = brrrToken;
        _sBrrrToken = sBrrrToken;
        _w1 = w1;
    }

    function mint() external {
        require(_tokensMinted[msg.sender] < MAX_TOKENS_PER_WALLET, "Max tokens per wallet reached");
        _brrrToken.transferFrom(msg.sender, _w1, MINT_COST_BRRR);
        _sBrrrToken.transferFrom(msg.sender, _w1, MINT_COST_SBRRR);
        _mint(msg.sender, 1);
        _userStartTime[msg.sender].push(block.timestamp);
        _tokensMinted[msg.sender] += 1;
    }

    function getUserStartTimes(address user) public view returns (uint256[] memory) {
        return _userStartTime[user];
    }

    function CalculateRewards(uint256 userStartTime) public view returns (uint256) {
        uint256 timePassed = block.timestamp - userStartTime;
        uint256 daysPassed = timePassed / 1 days;

        uint256 rewards = 0;
        uint256 dailyReward = DAILY_AMOUNT;

        for (uint256 i = 0; i < daysPassed; i++) {
            rewards += dailyReward;
        }

        uint256 remainingSeconds = timePassed % 1 days;
        uint256 currentDayReward = dailyReward * remainingSeconds / 86400;
        rewards += currentDayReward;

        if (rewards > MAX_REWARDS) {
            rewards = MAX_REWARDS;
        }

        return rewards;
    }

    function calculateTotalRewards(address user) public view returns (uint256) {
        uint256[] memory userStartTimes = _userStartTime[user];
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < userStartTimes.length; i++) {
            totalRewards += CalculateRewards(userStartTimes[i]);
        }

        return totalRewards;
    }

    function calculateUnclaimedRewards(address user) public view returns (uint256) {
        uint256 totalRewards = calculateTotalRewards(user);
        uint256 unclaimedRewards = totalRewards - _claimedRewards[user];

        return unclaimedRewards;
    }

    function claimRewards() external {
        uint256 unclaimedRewards = calculateUnclaimedRewards(msg.sender);
        require(unclaimedRewards > 0, "No rewards to claim");

        _claimedRewards[msg.sender] += unclaimedRewards;
        _sBrrrToken.mint(msg.sender, unclaimedRewards);
    }
}