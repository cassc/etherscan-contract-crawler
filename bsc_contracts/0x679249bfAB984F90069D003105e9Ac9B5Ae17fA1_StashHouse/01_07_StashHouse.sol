/* SPDX-License-Identifier: UNLICENSED */

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";

abstract contract ManageableUpgradeable is OwnableUpgradeable {
    mapping(address => bool) private _managers;
    event ManagerAdded(address indexed manager_);
    event ManagerRemoved(address indexed manager_);

    function managers(address manager_) public view virtual returns (bool) {
        return _managers[manager_];
    }

    modifier onlyManager() {
        require(_managers[_msgSender()], "Manageable: caller is not the owner");
        _;
    }

    function removeManager(address manager_) public virtual onlyOwner {
        _managers[manager_] = false;
        emit ManagerRemoved(manager_);
    }

    function addManager(address manager_) public virtual onlyOwner {
        require(
            manager_ != address(0),
            "Manageable: new owner is the zero address"
        );
        _managers[manager_] = true;
        emit ManagerAdded(manager_);
    }
}

interface ITeams {
    function getReferrer(address user) external view returns (address);

    function getReferred(address user) external view returns (address[] memory);
}

interface IBank {
    function addRewards(address token, uint256 amount) external;
}

contract StashHouse is
    Initializable,
    OwnableUpgradeable,
    ManageableUpgradeable
{
    struct Fees {
        uint16 deposits;
        uint16 withdrawals;
        uint16 claimReferrals;
        uint16 compounds;
    }

    struct FeesDistribution {
        uint16 rewards;
        uint16 bank;
        uint16 referrer;
        uint16 growth;
    }

    struct Staking {
        uint256 amount;
        uint256 lastAction;
        uint256 lastTimeableAction;
        uint256 initialDeposit;
        uint256 nOfReinvestments;
        uint256 nOfClaims;
        uint256 totalCompounded;
        uint256 totalClaimed;
        uint256 pendingRewards;
    }

    address public BANDIT;
    IERC20Upgradeable public TOKEN;
    IBank public BANK;
    address public GROWTH;
    ITeams public TEAMS;

    Fees public fees;

    FeesDistribution public depositsFeesDistribution;

    FeesDistribution public withdrawalsFeesDistribution;

    FeesDistribution public compoundFeesDistribution;

    uint256 public maxROI;
    uint256 public dailyROI;

    mapping(address => Staking) public stakings;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public claimedRewards;

    uint256 public actionTimeout;
    uint256 public cutoffTimeout;
    uint256 public maxCompound;

    bool public isMaxCompoundEnabled;

    function initialize(
        address token,
        address bank,
        address growth,
        address teams
    ) public initializer {
        __Ownable_init();
        TOKEN = IERC20Upgradeable(token);
        BANK = IBank(bank);
        GROWTH = growth;
        TEAMS = ITeams(teams);

        fees = Fees({
            deposits: 700,
            withdrawals: 1000,
            claimReferrals: 3000,
            compounds: 500
        });

        depositsFeesDistribution = FeesDistribution({
            rewards: 0,
            bank: 0,
            referrer: 2000,
            growth: 8000
        });

        withdrawalsFeesDistribution = FeesDistribution({
            rewards: 8000,
            bank: 0,
            referrer: 0,
            growth: 2000
        });

        compoundFeesDistribution = FeesDistribution({
            rewards: 10000,
            bank: 0,
            referrer: 0,
            growth: 0
        });

        maxROI = 20000;
        dailyROI = 150;
        actionTimeout = 1 days;
        cutoffTimeout = 2 days;
        maxCompound = 500000;
    }

    function setMaxROI(uint256 value) public onlyOwner {
        maxROI = value;
    }

    function setDailyROI(uint256 value) public onlyOwner {
        dailyROI = value;
    }

    function setActionTimeout(uint256 value) public onlyOwner {
        actionTimeout = value;
    }

    function setMaxCompound(uint256 value) public onlyOwner {
        maxCompound = value;
    }

    function setIsMaxCompoundEnabled(bool value) public onlyOwner {
        isMaxCompoundEnabled = value;
    }

    function setFees(
        uint16 deposits,
        uint16 withdrawals,
        uint16 claimReferrals_,
        uint16 compound_
    ) public onlyOwner {
        fees = Fees({
            deposits: deposits,
            withdrawals: withdrawals,
            claimReferrals: claimReferrals_,
            compounds: compound_
        });
    }

    function setDepositFeeDistribution(
        uint16 rewards_,
        uint16 bank,
        uint16 referrer,
        uint16 growth
    ) public onlyOwner {
        depositsFeesDistribution = FeesDistribution({
            rewards: rewards_,
            bank: bank,
            referrer: referrer,
            growth: growth
        });
    }

    function setWithdrawalsFeesDistribution(
        uint16 rewards_,
        uint16 bank,
        uint16 referrer,
        uint16 growth
    ) public onlyOwner {
        withdrawalsFeesDistribution = FeesDistribution({
            rewards: rewards_,
            bank: bank,
            referrer: referrer,
            growth: growth
        });
    }

    function setCompoundFeeDistribution(
        uint16 rewards_,
        uint16 bank,
        uint16 referrer,
        uint16 growth
    ) public onlyOwner {
        compoundFeesDistribution = FeesDistribution({
            rewards: rewards_,
            bank: bank,
            referrer: referrer,
            growth: growth
        });
    }

    function setToken(address value) public onlyOwner {
        TOKEN = IERC20Upgradeable(value);
    }

    function setBank(address value) public onlyOwner {
        BANK = IBank(value);
    }

    function setGrowth(address value) public onlyOwner {
        GROWTH = value;
    }

    function setTeams(address value) public onlyOwner {
        TEAMS = ITeams(value);
    }

    function _sortFees(
        uint16 fee,
        FeesDistribution memory feesDistribution,
        uint256 amount
    ) internal {
        amount = (amount * fee) / 10000;
        if (feesDistribution.bank > 0) {
            TOKEN.transfer(
                address(BANK),
                (amount * feesDistribution.bank) / 10000
            );
            BANK.addRewards(
                address(TOKEN),
                (amount * feesDistribution.bank) / 10000
            );
        }

        if (feesDistribution.referrer > 0) {
            rewards[TEAMS.getReferrer(_msgSender())] +=
                (amount * feesDistribution.referrer) /
                10000;
        }

        if (feesDistribution.growth > 0) {
            TOKEN.transfer(GROWTH, (amount * feesDistribution.growth) / 10000);
        }
    }

    function _claim(address user, uint256 claimAmount) internal {
        Staking memory userStaking = stakings[user];
        if (userStaking.amount < claimAmount) {
            userStaking.amount = userStaking.initialDeposit;
        } else {
            userStaking.amount -= claimAmount;
            if (userStaking.amount < userStaking.initialDeposit) {
                userStaking.amount = userStaking.initialDeposit;
            }
        }
        userStaking.pendingRewards = 0;
        userStaking.lastTimeableAction = block.timestamp;
        userStaking.lastAction = block.timestamp;
        userStaking.nOfClaims += 1;
        userStaking.totalClaimed += claimAmount;
        stakings[_msgSender()] = userStaking;
    }

    function _compound(address user, uint256 claimAmount) internal {
        Staking memory userStaking = stakings[user];
        userStaking.totalCompounded += claimAmount;
        if (isMaxCompoundEnabled) {
            require(
                userStaking.totalCompounded <=
                    (userStaking.initialDeposit * maxCompound) / 10000,
                "COMPOUND: Reached the maximum compound."
            );
        }
        userStaking.pendingRewards = 0;
        userStaking.lastTimeableAction = block.timestamp;
        userStaking.lastAction = block.timestamp;
        userStaking.nOfReinvestments++;
        userStaking.amount += claimAmount;
        stakings[user] = userStaking;
    }

    function deposit(uint256 amount) public {
        require(
            TOKEN.balanceOf(_msgSender()) >= amount,
            "DEPOSIT: Balance too low."
        );
        require(
            TOKEN.allowance(_msgSender(), address(this)) >= amount,
            "DEPOSIT: Allowance too low."
        );
        TOKEN.transferFrom(_msgSender(), address(this), amount);
        _sortFees(fees.deposits, depositsFeesDistribution, amount);
        Staking memory userStaking = stakings[_msgSender()];
        if (userStaking.amount > 0) {
            userStaking.pendingRewards = availableRewards(_msgSender());
        }
        userStaking.amount += amount;
        userStaking.lastAction = block.timestamp;
        userStaking.initialDeposit += amount;
        stakings[_msgSender()] = userStaking;
    }

    function claim() public {
        Staking memory userStaking = stakings[_msgSender()];
        require(
            userStaking.nOfReinvestments / 3 - userStaking.nOfClaims > 0,
            "CLAIM: No claims available."
        );
        require(
            block.timestamp - userStaking.lastTimeableAction >= actionTimeout,
            "CLAIM: Currently on timeout."
        );
        uint256 claimAmount = availableRewards(_msgSender());
        require(claimAmount > 0, "CLAIM: Nothing to claim.");
        _claim(_msgSender(), claimAmount);
        uint256 afterFees = claimAmount -
            (claimAmount * fees.withdrawals) /
            10000;
        _sortFees(fees.withdrawals, withdrawalsFeesDistribution, claimAmount);
        TOKEN.transfer(_msgSender(), afterFees);
    }

    function compound() public {
        Staking memory userStaking = stakings[_msgSender()];
        require(
            block.timestamp - userStaking.lastTimeableAction >= actionTimeout,
            "CLAIM: Currently on timeout."
        );
        uint256 claimAmount = availableRewards(_msgSender());
        require(claimAmount > 0, "CLAIM: Nothing to claim.");
        uint256 afterFees = claimAmount -
            (claimAmount * fees.compounds) /
            10000;
        _compound(_msgSender(), afterFees);
        _sortFees(fees.compounds, compoundFeesDistribution, afterFees);
    }

    function compoundReferrals() public {
        uint256 amount = availableReferralsRewards(_msgSender());
        claimedRewards[_msgSender()] += amount;
        Staking memory userStaking = stakings[_msgSender()];
        userStaking.totalCompounded += amount;
        if (isMaxCompoundEnabled) {
            require(
                userStaking.totalCompounded <=
                    (userStaking.initialDeposit * maxCompound) / 10000,
                "COMPOUND: Reached the maximum compound."
            );
        }
        userStaking.amount += amount;
        stakings[_msgSender()] = userStaking;
    }

    function claimReferrals() public {
        uint256 amount = availableReferralsRewards(_msgSender());
        uint256 fees_ = (amount * fees.claimReferrals) / 10000;
        claimedRewards[_msgSender()] += amount;
        TOKEN.transfer(_msgSender(), amount - fees_);
    }

    function availableRewards(address user)
        public
        view
        returns (uint256 claimAmount)
    {
        Staking memory userStaking = stakings[user];
        uint256 secondsElapsed = block.timestamp - userStaking.lastAction >=
            cutoffTimeout
            ? cutoffTimeout
            : block.timestamp - userStaking.lastAction;
        claimAmount =
            stakings[user].pendingRewards +
            (stakings[user].amount * secondsElapsed * dailyROI) /
            86400 /
            10000;
    }

    function availableReferralsRewards(address user)
        public
        view
        returns (uint256)
    {
        return rewards[user] - claimedRewards[user];
    }

    function addToUsers(address[] memory users, uint256[] memory amounts)
        public
        onlyOwner
    {
        require(users.length == amounts.length, "ATU: Invalid lengths");
        for (uint256 i = 0; i < users.length; i++) {
            Staking memory userStaking = stakings[users[i]];
            if (userStaking.amount > 0) {
                userStaking.pendingRewards = availableRewards(users[i]);
            }
            userStaking.amount += (amounts[i] * 1e18);
            stakings[users[i]] = userStaking;
        }
    }

    function addToUsers(address[] memory users, uint256 amount)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < users.length; i++) {
            Staking memory userStaking = stakings[users[i]];
            if (userStaking.amount > 0) {
                userStaking.pendingRewards = availableRewards(users[i]);
            }
            userStaking.amount += (amount * 1e18);
            stakings[users[i]] = userStaking;
        }
    }
}