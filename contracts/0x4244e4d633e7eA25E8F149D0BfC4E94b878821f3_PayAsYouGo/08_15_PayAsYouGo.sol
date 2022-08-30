// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../interfaces/IAnkrProtocol.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IStakingConfig.sol";
import "../interfaces/IEarnConfig.sol";
import "../interfaces/ITokenStaking.sol";

contract PayAsYouGo is ReentrancyGuardUpgradeable, IAnkrProtocol, ITransportLayer {

    uint256 internal constant BALANCE_COMPACT_PRECISION = 1e8;
    uint256 internal constant DEPOSIT_WITHDRAW_PRECISION = 1e15;

    event MinWithdrawAmountSet(uint256 amount);
    event InstantlyChargeCollectedFee(uint256 amount);
    event ManuallyFeedCollectedFee(uint256 amount);

    struct UserBalance {
        uint80 available;
        uint80 pending;
    }

    IERC20Upgradeable internal _ankrToken;
    IEarnConfig internal _earnConfig;
    mapping(address => UserBalance) internal _userDeposits;
    mapping(address => uint64) internal _requestNonce;
    uint256 internal _collectedFee;
    uint256 internal _minWithdrawAmount;

    function initialize(IEarnConfig earnConfig, IERC20Upgradeable ankrToken) external initializer {
        __ReentrancyGuard_init();
        __AnkrProtocol_init(earnConfig, ankrToken);
    }

    function __AnkrProtocol_init(IEarnConfig earnConfig, IERC20Upgradeable ankrToken) internal {
        _ankrToken = ankrToken;
        _earnConfig = earnConfig;
    }

    modifier onlyGovernance() {
        require(msg.sender == address(_earnConfig.getGovernanceAddress()), "PayAsYouGo: only governance");
        _;
    }

    modifier onlyConsensus() {
        require(msg.sender == address(_earnConfig.getConsensusAddress()), "PayAsYouGo: only consensus");
        _;
    }

    modifier onlyTreasury() {
        require(msg.sender == address(_earnConfig.getTreasuryAddress()), "PayAsYouGo: only treasury");
        _;
    }

    function getUserBalance(address user) external view returns (
        uint256 available,
        uint256 pending
    ) {
        UserBalance memory userDeposit = _userDeposits[user];
        return (
        uint256(userDeposit.available) * BALANCE_COMPACT_PRECISION,
        uint256(userDeposit.pending) * BALANCE_COMPACT_PRECISION
        );
    }

    function deposit(uint256 amount, uint64 timeout, bytes32 publicKey) external nonReentrant override {
        require(amount % BALANCE_COMPACT_PRECISION == 0, "PayAsYouGo: remainder is not allowed");
        require(amount % DEPOSIT_WITHDRAW_PRECISION == 0, "PayAsYouGo: too high precision");
        _lockDepositForUser(msg.sender, amount, timeout, msg.sender, publicKey);
    }

    function depositForUser(uint256 amount, uint64 timeout, address user, bytes32 publicKey) external nonReentrant {
        require(amount % BALANCE_COMPACT_PRECISION == 0, "PayAsYouGo: remainder is not allowed");
        require(amount % DEPOSIT_WITHDRAW_PRECISION == 0, "PayAsYouGo: too high precision");
        _lockDepositForUser(msg.sender, amount, timeout, user, publicKey);
    }

    // function _lockDeposit(address sender, uint256 amount, uint64 timeout, bytes32 publicKey) internal {
    //     if (amount > 0) {
    //         require(_ankrToken.transferFrom(msg.sender, address(this), amount), "PayAsYouGo: can't transfer");
    //     }
    //     // obtain user's lock and match next tier level
    //     UserBalance memory userDeposit = _userDeposits[sender];
    //     userDeposit.available += uint80(amount / BALANCE_COMPACT_PRECISION);
    //     _userDeposits[sender] = userDeposit;
    //     emit FundsLocked(sender, amount);
    //     // emit event for JWT token
    //     emit TierAssigned(sender, amount, 0, 0, uint64(block.timestamp + timeout), publicKey);
    // }

    function _lockDepositForUser(address sender, uint256 amount, uint64 timeout, address user, bytes32 publicKey) internal {
        if (amount > 0) {
            require(_ankrToken.transferFrom(sender, address(this), amount), "PayAsYouGo: can't transfer");
        }
        // obtain user's lock and match next tier level
        UserBalance memory userDeposit = _userDeposits[user];
        userDeposit.available += uint80(amount / BALANCE_COMPACT_PRECISION);
        _userDeposits[user] = userDeposit;
        emit FundsLocked(user, amount);
        // emit event for JWT token
        emit TierAssigned(user, amount, 0, 0, uint64(block.timestamp + timeout), publicKey);
    }

    function withdraw(uint256 amount) external nonReentrant override {
        require(amount >= _minWithdrawAmount, "PayAsYouGo: amount too low");
        require(amount % BALANCE_COMPACT_PRECISION == 0, "PayAsYouGo: remainder is not allowed");
        require(amount % DEPOSIT_WITHDRAW_PRECISION == 0, "PayAsYouGo: too high precision");
        _createWithdrawal(msg.sender, amount);
    }

    function _createWithdrawal(address sender, uint256 amount) internal {
        uint80 amount80 = uint80(amount / BALANCE_COMPACT_PRECISION);
        UserBalance memory userDeposit = _userDeposits[sender];
        require(userDeposit.available >= amount80, "PayAsYouGo: insufficient balance");
        require(userDeposit.pending == 0, "PayAsYouGo: already have pending withdrawal");
        userDeposit.available -= amount80;
        userDeposit.pending += amount80;
        _userDeposits[sender] = userDeposit;
        // trigger withdraw request
        bytes memory input = abi.encodeWithSelector(IRequestFormat.requestWithdrawal.selector, sender, amount);
        _triggerRequestEvent(sender, 0, input);
    }

    function handleChargeFee(address[] calldata users, uint256[] calldata fees) external onlyConsensus override {
        require(users.length == fees.length);
        for (uint256 i = 0; i < users.length; i++) {
            _chargeAnkrFor(users[i], fees[i]);
        }
    }

    function _chargeAnkrFor(address sender, uint256 fee) internal {
        uint80 fee80 = uint80(fee / BALANCE_COMPACT_PRECISION);
        UserBalance memory userDeposit = _userDeposits[sender];
        userDeposit.available -= fee80;
        _userDeposits[sender] = userDeposit;
        _collectedFee += fee;
        emit FeeCharged(sender, fee);
    }

    function handleWithdraw(address[] calldata users, uint256[] calldata amounts, uint256[] calldata fees) external onlyConsensus override {
        require(users.length == amounts.length && amounts.length == fees.length, "PayAsYouGo: corrupted data");
        for (uint256 i = 0; i < users.length; i++) {
            _doWithdraw(users[i], amounts[i], fees[i]);
        }
    }

    function _doWithdraw(address user, uint256 amount, uint256 fee) internal {
        uint80 amount80 = uint80(amount / BALANCE_COMPACT_PRECISION);
        uint80 fee80 = uint80(fee / BALANCE_COMPACT_PRECISION);
        // decrease user's balance
        UserBalance memory userDeposit = _userDeposits[user];
        require(userDeposit.pending >= amount80, "PayAsYouGo: wrong withdraw amount");
        require((userDeposit.pending + userDeposit.available) >= (amount80 + fee80), "PayAsYouGo: insufficient balance");
        userDeposit.available += userDeposit.pending - amount80;
        userDeposit.pending = 0;
        _userDeposits[user] = userDeposit;
        // if we have specified fee then charge it from user's account
        if (fee > 0) {
            _chargeAnkrFor(user, fee);
        }
        // transfer funds to user
        require(_ankrToken.transfer(user, amount), "PayAsYouGo: can't transfer");
        // emit event
        emit FundsUnlocked(user, amount);
    }

    function _triggerRequestEvent(address sender, uint64 lifetime, bytes memory input) internal {
        // increase nonce
        uint64 nonce = _requestNonce[sender];
        _requestNonce[sender]++;
        // calc request id
        bytes32 id = keccak256(abi.encodePacked(sender, nonce, block.chainid, input));
        // request expiration time (default lifetime is 1 week)
        if (lifetime == 0) {
            lifetime = 604800;
        }
        uint64 expires = uint64(block.timestamp) + lifetime;
        // emit as event to provider
        emit ProviderRequest(id, sender, 0, address(this), input, expires);
    }

    function setMinWithdrawAmount(uint256 minWithdrawalAmount) external onlyGovernance {
        require(minWithdrawalAmount % BALANCE_COMPACT_PRECISION == 0, "PayAsYouGo: remainder is not allowed");
        _minWithdrawAmount = minWithdrawalAmount;
        emit MinWithdrawAmountSet(minWithdrawalAmount);
    }

    function getMinWithdrawAmount() external view returns (uint256) {
        return _minWithdrawAmount;
    }

    function getCollectedFee() external view returns (uint256) {
        return _collectedFee;
    }

    function instantlyChargeCollectedFee(uint256 amount) external onlyGovernance {
        _collectedFee -= amount;
        emit InstantlyChargeCollectedFee(amount);
    }

    function manuallyFeedCollectedFee(uint256 amount) external {
        require(_ankrToken.transferFrom(msg.sender, address(this), amount), "PayAsYoGo: failed to transfer");
        _collectedFee += amount;
        emit ManuallyFeedCollectedFee(amount);
    }

    function deliverReward(address stakingContract, address validatorAddress, uint256 amount) external onlyConsensus {
        require(amount <= _collectedFee, "PayAsYouGo: insufficient fee");
        _collectedFee -= amount;
        require(_ankrToken.approve(stakingContract, amount), "PayAsYouGo: can't increase allowance");
        ITokenStaking(stakingContract).distributeRewards(validatorAddress, amount);
    }
}