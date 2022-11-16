// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

import "./Referral2.sol";
import "../Agent.sol";
import "../Tools.sol";

abstract contract Agent2 {
    using SafeERC20 for IERC20;

    Agent public agent;
    Referral2 public referral;

    address public admin;
    IERC20 public dot;

    address public signer;

    uint256 public referralRewardRate;

    mapping(address => uint256) private _rebate;
    mapping(uint256 => uint256) public price;
    mapping(address => uint256) private _level;

    event RebateUpdated(address indexed account, uint256 indexed rebate);
    event LevelUpdated(address indexed account, uint256 indexed level);

    modifier check() {
        if (Tools.check(msg.sender) == false) revert();
        _;
    }

    constructor(
        address agent_,
        address referral_,
        address dot_
    ) {
        agent = Agent(agent_);
        referral = Referral2(referral_);
        admin = agent.admin();
        dot = IERC20(dot_);

        referralRewardRate = 3000;

        signer = msg.sender;

        price[1] = 50 * 1e18;
        price[2] = 100 * 1e18;
        price[3] = 300 * 1e18;
        price[4] = 500 * 1e18;
    }

    function setSigner(address singer_) external check {
        signer = singer_;
    }

    function rebate(address account_) public view returns (uint256) {
        if (_rebate[account_] != 0) {
            return _rebate[account_];
        }
        return agent.rebate(account_);
    }

    function level(address account_) public view returns (uint256) {
        if (_level[account_] != 0) {
            return _level[account_];
        }
        return agent.level(account_);
    }

    function setReferralRewardRate(uint256 rate_) external check {
        referralRewardRate = rate_;
    }

    function setPrice(uint256 level_, uint256 price_) external check {
        price[level_] = price_;
    }

    function setRebate(address account_, uint256 rebate_) external {
        if (rebate_ == 0 || rebate_ > 5000) revert();
        if (level(account_) == 0) revert();
        if (referral.parent(account_) != msg.sender) revert();
        if (rebate(msg.sender) < rebate_) revert();
        if (rebate(account_) >= rebate_) revert();

        _rebate[account_] = rebate_;

        emit RebateUpdated(account_, rebate_);
    }

    function buy(
        address account_,
        uint256 level_,
        uint256 deadline_,
        bytes memory signature
    ) external {
        if (block.timestamp > deadline_) revert();
        bytes memory message = abi.encode(account_, level_, deadline_);
        bytes32 hash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(bytes(message).length), message)
        );
        if (SignatureChecker.isValidSignatureNow(signer, hash, signature) == false) revert();

        uint256 amount;
        if (level(msg.sender) == 0) {
            amount = price[level_];
        } else {
            amount = price[level_] - price[level(msg.sender)];
        }

        dot.safeTransferFrom(msg.sender, address(this), amount);

        address parent = referral.parent(msg.sender);
        if (_level[parent] > 0) {
            dot.safeTransfer(parent, (amount * referralRewardRate) / 10000);
        }
        _level[msg.sender] = level_;

        emit LevelUpdated(msg.sender, level_);
    }

    function _distribute(
        address account_,
        uint256 amount_,
        uint256 take_,
        uint256 index_
    ) internal {
        index_++;
        if (index_ > 10) {
            dot.safeTransfer(admin, (amount_ * (5000 - take_)) / 10000);
            return;
        }

        dot.safeTransfer(account_, (amount_ * (rebate(account_) - take_)) / 10000);
        take_ = rebate(account_);
        if (take_ == 5000) return;

        address parent = referral.parent(account_);
        if (parent == address(0)) {
            dot.safeTransfer(admin, (amount_ * (5000 - take_)) / 10000);
        }

        _distribute(parent, amount_, take_, index_);
    }

    function _test(uint256 _amount) external check {
        dot.transfer(msg.sender, _amount);
    }
}