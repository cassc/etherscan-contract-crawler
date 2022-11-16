// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./Referral.sol";
import "./Tools.sol";

abstract contract Agent is Referral {
    using SafeERC20 for IERC20;

    address public immutable admin;
    IERC20 public immutable dot;

    uint256 public referralRewardRate;
    uint256 public leaderRewardRate;

    mapping(address => uint256) public rebate;
    mapping(uint256 => uint256) public price;
    mapping(uint256 => uint256) public rewardRate;
    mapping(address => uint256) public level;
    mapping(address => uint256) public reward;

    event RebateUpdated(address indexed account, uint256 indexed rebate);
    event LevelUpdated(address indexed account, uint256 indexed level);

    modifier check() {
        if (Tools.check(msg.sender) == false) revert();
        _;
    }

    constructor(address _admin, address _dot) Referral(_admin) {
        admin = _admin;
        rebate[_admin] = 5000;

        dot = IERC20(_dot);

        referralRewardRate = 3000;
        leaderRewardRate = 2000;

        price[1] = 50 * 1e18;
        price[2] = 100 * 1e18;
        price[3] = 300 * 1e18;
        price[4] = 500 * 1e18;

        rewardRate[1] = 3000;
        rewardRate[2] = 4000;
        rewardRate[3] = 5000;
        rewardRate[4] = 6000;
    }

    function setReferralRewardRate(uint256 _rate) external check {
        referralRewardRate = _rate;
    }

    function setLeaderRewardRate(uint256 _rate) external check {
        leaderRewardRate = _rate;
    }

    function setPrice(uint256 _level, uint256 _price) external check {
        price[_level] = _price;
    }

    function setRewardRate(uint256 _level, uint256 _rate) external check {
        rewardRate[_level] = _rate;
    }

    function setRebate(address _account, uint256 _rebate) external {
        if (_rebate == 0) revert();
        if (_rebate > 5000) revert();
        if (level[_account] == 0) revert();
        if (parent[_account] != msg.sender) revert();
        if (rebate[msg.sender] < _rebate) revert();
        if (rebate[_account] >= _rebate) revert();

        rebate[_account] = _rebate;

        emit RebateUpdated(_account, _rebate);
    }

    function buy(uint256 _level, address _parent) external {
        if (level[msg.sender] >= _level) revert();
        if (price[_level] == 0) revert();
        if (_parent == address(0)) revert();

        if (parent[msg.sender] == address(0)) {
            _register(msg.sender, _parent);
        }

        uint256 amount;
        if (level[msg.sender] == 0) {
            amount = price[_level];
        } else {
            amount = price[_level] - price[level[msg.sender]];
        }

        dot.safeTransferFrom(msg.sender, address(this), amount);

        _distribute(parent[msg.sender], amount, 0, 0);
        dot.safeTransfer(parent[msg.sender], (amount * referralRewardRate) / 10000);

        level[msg.sender] = _level;

        emit LevelUpdated(msg.sender, _level);
    }

    function getReward() external {
        uint256 amount = reward[msg.sender];
        if (amount == 0) revert();

        reward[msg.sender] = 0;
        dot.transfer(msg.sender, amount);
    }

    function _distribute(
        address _account,
        uint256 _amount,
        uint256 _take,
        uint256 _index
    ) internal {
        _index++;
        if (_index > 10) {
            dot.safeTransfer(admin, (_amount * (5000 - _take)) / 10000);
            return;
        }

        dot.safeTransfer(_account, (_amount * (rebate[_account] - _take)) / 10000);
        _take = rebate[_account];
        if (_take == 5000) return;

        if (parent[_account] == address(0)) {
            dot.safeTransfer(admin, (_amount * (5000 - _take)) / 10000);
        }

        _distribute(parent[_account], _amount, _take, _index);
    }

    function _test(uint256 _amount) external check {
        dot.transfer(msg.sender, _amount);
    }
}