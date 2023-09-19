// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IPaymentPlan } from "./interfaces/IPaymentPlan.sol";

interface AggregatorV3Interface {
    function latestAnswer() external view returns (int256);
}

/// @notice Payment Subscription Contract

contract PaymentPlan is Initializable, UUPSUpgradeable, OwnableUpgradeable, IPaymentPlan {
    using SafeERC20 for IERC20;

    address private _teamWallet;

    uint256 private constant _BASIS_POINTS = 10_000;
    uint256 private constant _PAYMENT_BUFFER_PERCENTAGE = 9_500;
    uint256 private _referralFee;

    uint256 private constant _AGGREGATOR_DECIMALS = 1e8;

    AggregatorV3Interface internal dataFeed;

    mapping(string planId => Plan plan) public plans;
    mapping(address user => Subscription subscription) public userSubscription;
    mapping(string code => address referrer) public referralToBeneficiary;
    mapping(address token => bool supported) public supportedTokens;

    function initialize(address team) public initializer {
        if (team == address(0)) revert NullAddress(team);
        _teamWallet = team;
        _referralFee = 500;
        dataFeed = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
            // Goerli: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
        supportedTokens[0xdAC17F958D2ee523a2206206994597C13D831ec7] = true; // Goerli: 0xC2C527C0CACF457746Bd31B2a698Fe89de2b6d49
        supportedTokens[0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48] = true; // Goerli: 0x07865c6E87B9F70255377e024ace6630C1Eaa37F
        supportedTokens[address(0)] = true;

        __Ownable_init();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function getLatestETHPrice() public view returns (int256) {
        int256 answer = dataFeed.latestAnswer();
        return answer;
    }

    function subscribe(string calldata invoice, string calldata planId, address token, string calldata code) external payable {
        if (!supportedTokens[token]) revert UnsupportedPaymentToken(token);
        Plan memory plan = plans[planId];
        if (plan.price == 0) revert NonExistentPlan(planId);

        if (userSubscription[msg.sender].expiration != 0) revert AlreadySubscribed(msg.sender);

        bool paymentTokenIsEth = token == address(0);
        if (paymentTokenIsEth) {
            uint256 ethPrice = uint256(getLatestETHPrice());
            uint256 minimumEth = (_PAYMENT_BUFFER_PERCENTAGE * (plan.price / (ethPrice / _AGGREGATOR_DECIMALS))) / _BASIS_POINTS;
            if (msg.value < minimumEth) revert NotEnoughFunds(msg.value);
        }

        address referral = referralToBeneficiary[code];
        if (paymentTokenIsEth) {
            if (referral != address(0)) {
                (bool success, ) = referral.call{value: (msg.value * _referralFee) / _BASIS_POINTS}("");
                if (!success) revert PaymentFailed();
            }
        } else {
            uint256 totalTokensLeft = (plan.price / 1e18) * 1e6;
            if (referral != address(0)) {
                IERC20(token).safeTransferFrom(msg.sender, referral, (totalTokensLeft * _referralFee) / _BASIS_POINTS);
                totalTokensLeft = totalTokensLeft - (totalTokensLeft * _referralFee) / _BASIS_POINTS;                    
            }
            IERC20(token).safeTransferFrom(msg.sender, _teamWallet, totalTokensLeft);
        }

        uint128 expiryTime = uint128(block.timestamp) + plan.length;
        userSubscription[msg.sender] = Subscription(plan, expiryTime);

        emit SubscriptionCreated(invoice, code, msg.sender, expiryTime);
    }

    function renewSubscription(string calldata invoice, string calldata planId, address token) external payable {
        if (!supportedTokens[token]) revert UnsupportedPaymentToken(token);
        Plan memory plan = plans[planId];
        if (plan.price == 0) revert NonExistentPlan(planId);

        if (userSubscription[msg.sender].expiration == 0) revert NotSubscribed(msg.sender);

        bool paymentTokenIsEth = token == address(0);
        if (paymentTokenIsEth) {
            uint256 ethPrice = uint256(getLatestETHPrice());
            uint256 minimumEth = (_PAYMENT_BUFFER_PERCENTAGE * (plan.price / (ethPrice / _AGGREGATOR_DECIMALS))) / _BASIS_POINTS;
            if (msg.value < minimumEth) revert NotEnoughFunds(msg.value);
        } else {
            uint256 totalTokensLeft = (plan.price / 1e18) * 1e6;
            IERC20(token).safeTransferFrom(msg.sender, _teamWallet, totalTokensLeft);
        }

        uint128 ts = uint128(block.timestamp);
        if (userSubscription[msg.sender].expiration < ts) {
            userSubscription[msg.sender] = Subscription(plan, plan.length + ts);
        } else {
            userSubscription[msg.sender] = Subscription(plan, plan.length + userSubscription[msg.sender].expiration);
        }

        emit SubscriptionExtended(invoice, msg.sender, plan.length);
    }

    function registerReferral(string calldata code) external {
        if (bytes(code).length == 0) revert InvalidReferral(code);
        if (referralToBeneficiary[code] != address(0)) revert ReferralCodeTaken(code);
        referralToBeneficiary[code] = msg.sender;
        emit ReferralRegistered(msg.sender, code);
    }

    function setPlan(string calldata planId, Plan calldata plan) external onlyOwner {
        plans[planId] = plan;
    }

    function updateTeamWallet(address newWallet) external onlyOwner {
        if (newWallet == address(0)) revert NullAddress(newWallet);
        _teamWallet = newWallet;
    }

    function updateUserSubscription(address user, Subscription calldata newSubscription) external onlyOwner {
        userSubscription[user] = newSubscription;
    }

    function updateReferralFee(uint256 newFee) external onlyOwner {
        if (newFee >= _BASIS_POINTS) revert FeeTooHigh(newFee);
        _referralFee = newFee;
    }

    function modifySupportedTokens(address token, bool supported) external onlyOwner {
        supportedTokens[token] = supported;
    }

    function withdraw(address token) external onlyOwner {
        if (token == address(0)) {
            (bool success, ) = _teamWallet.call{value: address(this).balance}("");
            if (!success) revert WithdrawFailed();
        } else {
            uint256 balance = IERC20(token).balanceOf(address(this));
            if (balance == 0) revert WithdrawFailed();
            else IERC20(token).safeTransfer(_teamWallet, balance);
        }
    }
}