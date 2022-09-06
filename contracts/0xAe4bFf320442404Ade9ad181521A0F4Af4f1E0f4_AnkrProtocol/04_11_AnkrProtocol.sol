// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../interfaces/IAnkrProtocol.sol";
import "../interfaces/IERC20.sol";

import "../libs/AddressGenerator.sol";

interface IManuallyFeedCollectedFee {

    function manuallyFeedCollectedFee(uint256 amount) external;
}

contract AnkrProtocol is ReentrancyGuardUpgradeable {

    event TierLevelCreated(uint8 level);
    event TierLevelChanged(uint8 level);
    event TierLevelRemoved(uint8 level);

    event TierAssigned(address indexed sender, uint256 amount, uint8 tier, uint256 roles, uint64 expires, bytes32 publicKey);
    event FundsLocked(address indexed sender, uint256 amount, uint256 fee);
    event FundsUnlocked(address indexed sender, uint256 amount, uint8 tier);
    event FeeCharged(address indexed sender, uint256 fee);
    event FeeWithdrawn(address recipient, uint256 amount);

    struct TierLevel {
        uint256 threshold;
        uint256 fee;
        uint256 roles;
        uint8 tier;
    }

    struct UserDeposit {
        // available (how much user can spend), total (available+charged), pending (pending unlock)
        uint256 available;
        uint256 total;
        uint256 pending;
        // level based on deposited amount
        uint8 tier;
        uint64 expires;
    }

    struct RequestPayload {
        address sender;
        uint256 fee;
        address callback;
        bytes4 sig;
        uint64 lifetime;
        bytes data;
    }

    IERC20Upgradeable private _ankrToken;
    TierLevel[] private _tierLevels;
    mapping(address => UserDeposit) private _userDeposits;
    address private _governance;
    address private _consensus;
    mapping(address => uint256) private _requestNonce;
    uint256 private _collectedFee;
    address private _enterpriseAdmin;

    function initialize(IERC20Upgradeable ankrToken, address governance, address consensus) external initializer {
        __ReentrancyGuard_init();
        __AnkrProtocol_init(ankrToken, governance, consensus);
    }

    function __AnkrProtocol_init(IERC20Upgradeable ankrToken, address governance, address consensus) internal {
        // init fields
        _ankrToken = ankrToken;
        _governance = governance;
        _consensus = consensus;
        // create zero vip level
        _tierLevels.push(TierLevel({
        threshold : 0,
        tier : 0,
        roles : 0,
        fee : 0
        }));
    }

    modifier onlyFromGovernance() virtual {
        require(msg.sender == address(_governance), "AnkrProtocol: not governance");
        _;
    }

    modifier onlyFromConsensus() virtual {
        require(msg.sender == address(_consensus), "AnkrProtocol: not consensus");
        _;
    }

    modifier onlyFromEnterpriseAdmin() virtual {
        require(msg.sender == address(_enterpriseAdmin), "AnkrProtocol: not enterprise admin");
        _;
    }

    function createTierLevel(uint8 tier, uint256 threshold, uint256 roles, uint256 fee) external onlyFromGovernance {
        require(tier == _tierLevels.length, "AnkrProtocol: out of order");
        // if its not first level then make sure its not lower than previous (lets allow to set equal amount)
        uint256 prevThreshold = _tierLevels[tier - 1].threshold;
        require(prevThreshold >= 0 && threshold >= prevThreshold, "AnkrProtocol: threshold too low");
        // add new vip level
        _tierLevels.push(TierLevel({
        threshold : threshold,
        tier : tier,
        roles : roles,
        fee : fee
        }));
        emit TierLevelCreated(tier);
    }

    function changeTierLevel(uint8 level, uint256 threshold, uint256 fee) external onlyFromGovernance {
        require(_tierLevels[level].tier > 0, "AnkrProtocol: level doesn't exist");
        _tierLevels[level].threshold = threshold;
        _tierLevels[level].fee = fee;
        emit TierLevelChanged(level);
    }

    function calcNextTierLevel(address user, uint256 amount) external view returns (TierLevel memory) {
        UserDeposit memory userDeposit = _userDeposits[user];
        return _matchTierLevelOf(userDeposit.total + amount);
    }

    function _matchTierLevelOf(uint256 balance) internal view returns (TierLevel memory) {
        if (_tierLevels.length == 1) {
            return _tierLevels[0];
        }
        for (uint256 i = _tierLevels.length - 1; i >= 0; i--) {
            TierLevel memory level = _tierLevels[i];
            if (balance >= level.threshold) {
                return level;
            }
        }
        revert("AnkrProtocol: can't match level");
    }

    function getDepositLevel(uint8 level) external view returns (TierLevel memory) {
        return _tierLevels[level];
    }

    function currentLevel(address user) external view returns (uint8 tier, uint64 expires, uint256 roles) {
        UserDeposit memory userDeposit = _userDeposits[user];
        TierLevel memory depositLevel = _tierLevels[userDeposit.tier];
        return (userDeposit.tier, userDeposit.expires, depositLevel.roles);
    }

    function deposit(uint256 amount, uint64 timeout, bytes32 publicKey) external nonReentrant {
        require(timeout <= 31536000, "timeout can't be greater than 1 year");
        _lockDeposit(msg.sender, amount, timeout, publicKey);
    }

    function assignTier(uint64 timeout, uint8 tier, address user, bytes32 publicKey) external onlyFromEnterpriseAdmin {
        require(tier < _tierLevels.length, "AnkrProtocol: wrong tier level");
        require(timeout <= 3153600000, "timeout can't be greater than 100 year");
        TierLevel memory level = _tierLevels[tier];
        UserDeposit memory userDeposit = _userDeposits[user];
        userDeposit.tier = level.tier;
        _userDeposits[user] = userDeposit;
        // emit event
        emit TierAssigned(user, 0, level.tier, level.roles, uint64(block.timestamp) + timeout, publicKey);
    }

    function _lockDeposit(address user, uint256 amount, uint64 timeout, bytes32 publicKey) internal {
        // transfer ERC20 tokens when its required
        if (amount > 0) {
            require(_ankrToken.transferFrom(user, address(this), amount), "Ankr Protocol: can't transfer");
        }
        // obtain user's lock and match next tier level
        UserDeposit memory userDeposit = _userDeposits[user];
        TierLevel memory newLevel = _matchTierLevelOf(userDeposit.total + amount);
        // check do we need to charge for level increase
        if (newLevel.fee > 0 && (newLevel.tier > userDeposit.tier || userDeposit.expires > block.timestamp)) {
            amount -= newLevel.fee;
            _collectedFee += newLevel.fee;
        }
        // increase locked amount
        userDeposit.total += amount;
        userDeposit.available += amount;
        // if we have no expires set then increase it
        if (userDeposit.expires == 0) {
            userDeposit.expires = uint64(block.timestamp) + timeout;
        }
        // save new tier
        userDeposit.tier = newLevel.tier;
        _userDeposits[user] = userDeposit;
        // emit event
        emit TierAssigned(user, amount, userDeposit.tier, newLevel.roles, userDeposit.expires, publicKey);
        emit FundsLocked(user, amount, newLevel.fee);
    }

    function withdraw(uint256 /*amount*/, uint256 /*fee*/) external nonReentrant {
        revert("not supported yet");
    }

    function _validateWithdrawal(UserDeposit memory lock, uint256 amount) internal view {
        require(lock.expires <= block.timestamp, "AnkrProtocol: too early to withdraw");
        require(lock.available >= amount, "AnkrProtocol: insufficient balance");
    }

    function getCollectedFee() external view returns (uint256) {
        return _collectedFee;
    }

    function transferCollectedFee(IManuallyFeedCollectedFee recipient, uint256 amount) external onlyFromGovernance {
        require(amount <= _collectedFee, "AnkrProtocol: insufficient fee");
        _collectedFee -= amount;
        _ankrToken.approve(address(recipient), amount);
        recipient.manuallyFeedCollectedFee(amount);
        emit FeeWithdrawn(address(recipient), amount);
    }

    function changeConsensus(address newConsensus) external onlyFromGovernance {
        _consensus = newConsensus;
    }

    function changeGovernance(address newGovernance) external onlyFromGovernance {
        _governance = newGovernance;
    }

    function changeEnterpriseAdmin(address newEnterpriseAdmin) external onlyFromGovernance {
        _enterpriseAdmin = newEnterpriseAdmin;
    }
}