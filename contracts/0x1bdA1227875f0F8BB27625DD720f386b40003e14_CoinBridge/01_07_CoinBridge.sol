// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./AbstractBridge.sol";
import "./mint/IMint.sol";
import "../Mutex.sol";

contract CoinBridge is AbstractBridge, Mutex {
    uint256 constant DIVIDER = 10 ** 12;

    mapping(uint128 => BindingInfo) public bindings;
    uint256 public fees;
    uint256 public balance;

    event LockTokens(
        uint16 feeChainId,
        uint256 amount,
        string recipient,
        uint256 gaslessReward,
        string referrer,
        uint256 referrerFee,
        uint256 fee
    );
    event ReleaseTokens(
        uint256 amount,
        address recipient,
        uint256 gaslessReward,
        address caller
    );
    event Fee(uint16 feeChainId, uint256 amount, string recipient);

    function lockTokens(
        uint16 executionChainId_,
        string calldata recipient_,
        string calldata referrer_,
        uint256 gaslessReward_
    ) external payable mutex whenNotPaused whenInitialized {
        require(chains[executionChainId_], "execution chain is disable");
        BindingInfo memory binding = bindings[executionChainId_];
        require(binding.enabled, "token is disabled");
        require(msg.value >= binding.minAmount, "less than min amount");
        uint128 percent = msg.value > binding.thresholdFee
            ? binding.afterPercentFee
            : binding.beforePercentFee;
        uint256 fee = binding.minFee + (msg.value * percent) / PERCENT_FACTOR;
        require(msg.value > fee, "fee more than amount");
        uint256 amount;
        unchecked {
            amount = msg.value - fee;
        }
        require(amount > gaslessReward_, "gassless reward more than amount");
        uint256 referrerFee = (fee *
            referrersFeeInPercent[executionChainId_][referrer_]) /
            PERCENT_FACTOR;
        fees += fee - referrerFee;
        balance += amount + referrerFee;
        emit LockTokens(
            executionChainId_,
            amount,
            recipient_,
            gaslessReward_,
            referrer_,
            referrerFee,
            fee - referrerFee
        );
        IMint(adapter).mintTokens(
            executionChainId_,
            binding.executionAsset,
            amount / DIVIDER,
            recipient_,
            gaslessReward_ / DIVIDER,
            referrer_,
            referrerFee / DIVIDER
        );
    }

    function releaseTokens(
        bytes32 callerContract_,
        address payable recipient_,
        uint256 amount_,
        uint256 gaslessReward_
    ) external mutex whenNotPaused whenInitialized onlyExecutor {
        require(callerContract == callerContract_, "only caller contract");

        uint256 balance_ = balance;
        amount_ *= DIVIDER;
        gaslessReward_ *= DIVIDER;
        require(balance_ >= amount_, "insufficient funds");
        unchecked {
            balance = balance_ - amount_;
        }

        // slither-disable-start tx-origin
        emit ReleaseTokens(amount_, recipient_, gaslessReward_, tx.origin);
        if (gaslessReward_ > 0 && recipient_ != tx.origin) {
            recipient_.transfer(amount_ - gaslessReward_);
            payable(tx.origin).transfer(gaslessReward_);
        } else {
            recipient_.transfer(amount_);
        }
        // slither-disable-end tx-origin
    }

    function transferFee() external mutex whenNotPaused whenInitialized {
        uint16 feeChainId_ = feeChainId;
        require(chains[feeChainId_], "chain is disable");
        BindingInfo memory binding = bindings[feeChainId_];
        require(binding.enabled, "token is disabled");
        uint256 fee_ = fees;
        require(fee_ >= binding.minAmount, "less than min amount");
        balance += fee_;
        fees = 0;
        fee_ /= DIVIDER;
        string memory feeRecipient_ = feeRecipient;

        emit Fee(feeChainId_, fee_, feeRecipient_);
        IMint(adapter).mintTokens(
            feeChainId_,
            binding.executionAsset,
            fee_,
            feeRecipient_,
            0,
            "",
            0
        );
    }

    function updateBindingInfo(
        uint16 executionChainId_,
        string calldata executionAsset_,
        uint256 minAmount_,
        uint256 minFee_,
        uint256 thresholdFee_,
        uint128 beforePercentFee_,
        uint128 afterPercentFee_,
        bool enabled_
    ) external onlyAdmin {
        bindings[executionChainId_] = BindingInfo(
            executionAsset_,
            minAmount_,
            minFee_,
            thresholdFee_,
            beforePercentFee_,
            afterPercentFee_,
            enabled_
        );
    }

    receive() external payable {}
}