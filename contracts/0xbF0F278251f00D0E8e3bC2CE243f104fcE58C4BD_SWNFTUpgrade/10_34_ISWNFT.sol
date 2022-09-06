//SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.9;

/// @title Interface for swNFT
interface ISWNFT {
    struct Position {
        bytes pubKey;
        uint256 value;
        uint256 baseTokenBalance;
        uint256 timeStamp;
        bool operator;
    }

    struct Action {
        uint256 tokenId;
        uint256 action;
        uint256 amount;
        address strategy;
    }

    struct Stake {
        bytes pubKey;
        bytes signature;
        bytes32 depositDataRoot;
        uint256 amount;
    }

    enum ActionChoices {
        Deposit,
        Withdraw,
        EnterStrategy,
        ExitStrategy
    }

    function swETHAddress() external view returns (address);

    // ============ Events ============

    event LogStake(
        address indexed user,
        uint256 indexed itemId,
        bytes indexed pubKey,
        uint256 deposit,
        uint256 timeStamp,
        string referral
    );

    event LogDeposit(uint256 indexed tokenId, address user, uint256 amount);

    event LogWithdraw(uint256 indexed tokenId, address user, uint256 amount);

    event LogEnterStrategy(
        uint256 indexed tokenId,
        address strategy,
        address user,
        uint256 amount
    );

    event LogExitStrategy(
        uint256 indexed tokenId,
        address strategy,
        address user,
        uint256 amount
    );

    event LogAddWhiteList(address user, bytes indexed pubKey);

    event LogAddSuperWhiteList(
        address user,
        bytes indexed pubKey
    );

    event LogUpdateBotAddress(address _address);

    event LogUpdateIsValidatorActive(
        address user,
        bytes indexed pubKey,
        bool isActive
    );

    event LogSetSWETHAddress(address swETHAddress);

    event LogSetFeePool(address feePool);

    event LogSetFee(uint256 fee);

    event LogSetRate(address user, bytes indexed pubKey, uint256 rate);
}