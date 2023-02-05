// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Contract by technopriest#0760
contract Treasury is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    ERC20 public token;

    Counters.Counter public index;

    uint256 public surplusAmount;

    mapping(address => uint256) public latestPaymentIx;

    address payable wallet;

    struct Stake {
        uint256 index;
        uint256 stake;
    }

    mapping(address => Stake[]) public stakes;

    struct Payment {
        uint256 index;
        uint256 amount;
    }

    Payment[] public payments;

    event StakeAdded(address owner, uint256 stake);

    event StakeWithdrawn(address owner, uint256 stake);

    event PaymentAdded(uint256 amount);

    event RewardClaimed(address owner, uint256 amount);

    constructor(ERC20 token_, address payable wallet_) {
        token = token_;
        wallet = wallet_;
    }

    function setWallet(address payable wallet_) external onlyOwner {
        wallet = wallet_;
    }

    function withdrawSurplus(uint256 amount_) external {
        require(amount_ > 0, "amount = 0");
        require(amount_ <= surplusAmount, "amount <= houseAmount");
        surplusAmount = surplusAmount.sub(amount_);
        Address.sendValue(wallet, amount_);
    }

    function getCurrentStake(address account_) public view returns (uint256) {
        if (stakes[account_].length == 0) {
            return 0;
        }
        return stakes[account_][stakes[account_].length - 1].stake;
    }

    function getStakeAtIndex(address account_, uint256 index_) public view returns (uint256) {
        for (uint256 i = stakes[account_].length; i > 0; i--) {
            if (stakes[account_][i - 1].index < index_) {
                return stakes[account_][i - 1].stake;
            }
        }
        return 0;
    }

    function addStake(uint256 amount_) external nonReentrant {
        require(amount_ > 0, "amount = 0");
        uint256 currentStake = getCurrentStake(msg.sender);
        index.increment();
        stakes[msg.sender].push(Stake(index.current(), currentStake.add(amount_)));
        token.transferFrom(msg.sender, address(this), amount_);
        emit StakeAdded({owner: msg.sender, stake: currentStake.add(amount_)});
    }

    function withdrawStake(uint256 amount_) external nonReentrant {
        require(amount_ > 0, "amount = 0");
        uint256 currentStake = getCurrentStake(msg.sender);
        require(amount_ <= currentStake, "amount <= currentStake");
        index.increment();
        stakes[msg.sender].push(Stake(index.current(), currentStake.sub(amount_)));
        token.transfer(msg.sender, amount_);
        emit StakeWithdrawn({owner: msg.sender, stake: currentStake.sub(amount_)});
    }

    function deposit() external payable {
        uint256 weiAmount = msg.value;
        require(weiAmount != 0);
        index.increment();
        payments.push(Payment(index.current(), weiAmount));
        uint256 payableAmount = weiAmount.mul(token.balanceOf(address(this))).div(token.totalSupply());
        surplusAmount = surplusAmount.add(weiAmount.sub(payableAmount));
        emit PaymentAdded({amount: weiAmount});
    }

    function pendingReward(address account_) public view returns (uint256) {
        uint256 amount = 0;
        for (uint256 i = latestPaymentIx[account_]; i < payments.length; i++) {
            amount = amount.add(
                payments[i].amount.mul(getStakeAtIndex(account_, payments[i].index)).div(token.totalSupply())
            );
        }
        return amount;
    }

    function claimReward(address payable recipient_) external nonReentrant returns (uint256) {
        uint256 amount = pendingReward(recipient_);
        if (amount > 0) {
            latestPaymentIx[recipient_] = payments.length;
            Address.sendValue(recipient_, amount);
            emit RewardClaimed({owner: recipient_, amount: amount});
        }
        return amount;
    }
}