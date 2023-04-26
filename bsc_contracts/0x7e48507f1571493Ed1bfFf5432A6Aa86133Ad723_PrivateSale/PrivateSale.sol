/**
 *Submitted for verification at BscScan.com on 2023-04-26
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC20 {
    function totalSupply() external view returns (uint256 theTotalSupply);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(
        address _to,
        uint256 _value
    ) external returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function approve(
        address _spender,
        uint256 _value
    ) external returns (bool success);

    function allowance(
        address _owner,
        address _spender
    ) external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
}

contract PrivateSale {
    struct Users {
        uint256 tokenBuy;
        uint256 annualBonus;
        uint256 fifteenDaysBonus;
        uint256 dailyBonus;
        uint256 purchaseTime;
        uint256 totalEarn;
    }

    mapping(address => bool) public operator;
    address public owner;
    IERC20 public constant usdtAddress =
        IERC20(0x55d398326f99059fF775485246999027B3197955);

    IERC20 public constant busdAddress =
        IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);

    IERC20 public constant thunderEvAddress =
        IERC20(0x3bee1578598750cb80ddDF0938611D9d3d3d49B2);

    uint256 public buyPrice;
    uint256 public refBonusPercent;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public bnbPriceInUsd;

    mapping(address => mapping(uint256 => Users)) public userPrivateSaleDetails;
    mapping(address => uint256) public userId;
    mapping(address => uint256) public totalTokenBuy;
    mapping(address => bool) public isValidRefAddress;
    mapping(address => uint256) public numberOfRef;
    mapping(address => uint256) public tokenEarnByRef;
    mapping(address => uint256) public remainingEarning;

    event Received(address, uint256);
    event TokensBought(address, uint256);
    event OwnershipTransferred(address);
    event SetEndTime(address, uint256);
    event SetStartTime(address, uint256);
    event SetBonusPercentages(address, uint256);
    event Claim(address, uint256);
    event SetBuyPrice(address, uint256);
    event SetBnbPrice(address, uint256);
    event SetOperator(address, address);

    modifier onlyOwnerOrOperator() {
        require(
            (msg.sender == owner) || (operator[msg.sender]),
            "Sorry! You are not an owner or operator."
        );
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Sorry! You are not an owner.");
        _;
    }

    modifier onlyEnoughFunds(uint256 amount) {
        require(msg.value >= amount, "Sorry! You don't have enough funds.");
        _;
    }

    constructor() {
        owner = msg.sender;
        isValidRefAddress[owner] = true;
    }

    function setOperator(address opp) external onlyOwner returns (bool) {
        operator[opp] = true;
        emit SetOperator(msg.sender, opp);
        return true;
    }

    function setPrivatesaleStartTime(
        uint256 time
    ) external onlyOwner returns (bool) {
        startTime = block.timestamp + time;
        emit SetStartTime(msg.sender, time);
        return true;
    }

    function setPrivatesaleEndTime(
        uint256 time
    ) external onlyOwner returns (bool) {
        endTime = block.timestamp + time;
        emit SetEndTime(msg.sender, time);
        return true;
    }

    function setBnbPrice(uint256 price) external onlyOwner returns (bool) {
        // must be in INT 400, 310, 311,
        bnbPriceInUsd = price;
        emit SetBnbPrice(msg.sender, price);
        return true;
    }

    function setBuyUnitPrice(uint256 price) external onlyOwner returns (bool) {
        // must be in INT eg. 0.95 => 95, 1.20 => 120
        buyPrice = price;
        emit SetBuyPrice(msg.sender, price);
        return true;
    }

    // BUY TOKEN & Referral Reward
    function buyTokenWithUsdt(
        address referer,
        uint256 amount
    )
        external
        payable
        returns (
            uint256 privateSaleId,
            uint256 usdtTransferToRef,
            uint256 thevTransferToUser,
            address userAddress
        )
    {
        require(amount > 0, "Zero value");
        require(buyPrice != 0, "Buy price not set");
        uint256 amountInUsd = (amount * buyPrice * 1 ether) / 100;
        uint256 tokens = (amountInUsd * 100) / buyPrice;
        totalTokenBuy[msg.sender] = totalTokenBuy[msg.sender] + tokens;
        (
            uint256 annualReward,
            uint256 fifteenDaysReward,
            uint256 dailyReward
        ) = getRewardsPlan(tokens / 1 ether);

        require(startTime > 0, "Start time not defined!");
        require(block.timestamp > startTime, "Private Sale not started yet!");
        require(block.timestamp < endTime, "Private Sale finished or stopped!");

        require(
            thunderEvAddress.balanceOf(address(this)) >= tokens,
            "Not enough balance on contract"
        );

        uint256 totalEarning = (tokens * annualReward) / 100;
        remainingEarning[msg.sender] =
            remainingEarning[msg.sender] +
            totalEarning;
        totalTokenBuy[msg.sender] = totalTokenBuy[msg.sender] + tokens;
        isValidRefAddress[msg.sender] = true;
        userId[msg.sender];
        userPrivateSaleDetails[msg.sender][userId[msg.sender]++] = Users({
            tokenBuy: tokens / 1 ether,
            annualBonus: annualReward,
            fifteenDaysBonus: fifteenDaysReward,
            dailyBonus: dailyReward,
            purchaseTime: block.timestamp,
            totalEarn: totalEarning
        });
        uint256 refToken;
        if ((isValidRefAddress[referer]) && (msg.sender != referer)) {
            numberOfRef[referer]++;
            refToken = (((tokens * refBonusPercent)) / 100);
            tokenEarnByRef[referer] = tokenEarnByRef[referer] + refToken;
            require(
                usdtAddress.transfer(referer, refToken),
                "refral transfer fail."
            );
        }

        require(
            usdtAddress.transferFrom(msg.sender, address(this), amountInUsd),
            "Token transfer to contract failed!"
        );
        require(
            thunderEvAddress.transfer(msg.sender, tokens),
            "transfer token to user failed!"
        );

        emit TokensBought(msg.sender, tokens);
        return (userId[msg.sender] - 1, refToken, tokens, msg.sender);
    }

    function buyTokenWithBusd(
        address referer,
        uint256 amount
    )
        external
        payable
        returns (
            uint256 privateSaleId,
            uint256 usdtTransferToRef,
            uint256 thevTransferToUser,
            address userAddress
        )
    {
        require(amount > 0, "Zero value");
        require(buyPrice != 0, "Buy price not set");
        uint256 amountInUsd = (amount * buyPrice * 1 ether) / 100;
        uint256 tokens = (amountInUsd * 100) / buyPrice;
        totalTokenBuy[msg.sender] = totalTokenBuy[msg.sender] + tokens;
        (
            uint256 annualReward,
            uint256 fifteenDaysReward,
            uint256 dailyReward
        ) = getRewardsPlan(tokens / 1 ether);

        require(startTime > 0, "Start time not defined");
        require(block.timestamp > startTime, "Private Sale not started yet!");
        require(block.timestamp < endTime, "Private Sale finished!");
        require(
            thunderEvAddress.balanceOf(address(this)) >= tokens,
            "Not enough balance on contract"
        );

        uint256 totalEarning = (tokens * annualReward) / 100;
        remainingEarning[msg.sender] =
            remainingEarning[msg.sender] +
            totalEarning;

        totalTokenBuy[msg.sender] = totalTokenBuy[msg.sender] + tokens;
        isValidRefAddress[msg.sender] = true;
        userId[msg.sender];
        userPrivateSaleDetails[msg.sender][userId[msg.sender]++] = Users({
            tokenBuy: tokens / 1 ether,
            annualBonus: annualReward,
            fifteenDaysBonus: fifteenDaysReward,
            dailyBonus: dailyReward,
            purchaseTime: block.timestamp,
            totalEarn: totalEarning
        });
        uint256 refToken;
        if ((isValidRefAddress[referer]) && (msg.sender != referer)) {
            numberOfRef[referer]++;
            refToken = ((tokens * refBonusPercent) / 100);
            tokenEarnByRef[referer] = tokenEarnByRef[referer] + refToken;
            require(
                usdtAddress.transfer(referer, refToken),
                "refral transfer fail."
            );
        }

        require(
            busdAddress.transferFrom(msg.sender, address(this), amountInUsd),
            "Token transfer to contract failed!"
        );
        require(
            thunderEvAddress.transfer(msg.sender, tokens),
            "transfer token to user failed!"
        );

        emit TokensBought(msg.sender, tokens);
        return (userId[msg.sender] - 1, refToken, tokens, msg.sender);
    }

    function buyTokenWithBnb(
        address referer,
        uint256 amount
    )
        external
        payable
        onlyEnoughFunds(amount)
        returns (
            uint256 privateSaleId,
            uint256 usdtTransferToRef,
            uint256 thevTransferToUser,
            address userAddress
        )
    {
        require(msg.value > 0, "Zero value");
        require(buyPrice != 0, "Buy price not set");
        require(bnbPriceInUsd != 0, "BNB Price not set");

        uint256 tokens = (msg.value * bnbPriceInUsd * 100) / buyPrice;

        totalTokenBuy[msg.sender] = totalTokenBuy[msg.sender] + tokens;
        (
            uint256 annualReward,
            uint256 fifteenDaysReward,
            uint256 dailyReward
        ) = getRewardsPlan(tokens / 1 ether);

        require(startTime > 0, "Start time not defined");
        require(block.timestamp > startTime, "Private Sale not started yet!");
        require(block.timestamp < endTime, "Private Sale finished!");
        require(
            thunderEvAddress.balanceOf(address(this)) >= tokens,
            "Not enough balance on contract"
        );
        uint256 totalEarning = (tokens * annualReward) / 100;
        remainingEarning[msg.sender] =
            remainingEarning[msg.sender] +
            totalEarning;

        totalTokenBuy[msg.sender] = totalTokenBuy[msg.sender] + tokens;
        isValidRefAddress[msg.sender] = true;
        userId[msg.sender];

        userPrivateSaleDetails[msg.sender][userId[msg.sender]++] = Users({
            tokenBuy: tokens / 1 ether,
            annualBonus: annualReward,
            fifteenDaysBonus: fifteenDaysReward,
            dailyBonus: dailyReward,
            purchaseTime: block.timestamp,
            totalEarn: totalEarning
        });
        uint256 refToken;
        if ((isValidRefAddress[referer]) && (msg.sender != referer)) {
            numberOfRef[referer]++;
            refToken = ((tokens * refBonusPercent) / 100);
            tokenEarnByRef[referer] = tokenEarnByRef[referer] + refToken;
            require(
                usdtAddress.transfer(referer, refToken),
                "refral transfer fail."
            );
        }

        require(
            thunderEvAddress.transfer(msg.sender, tokens),
            "transfer token to user failed!"
        );
        emit TokensBought(msg.sender, tokens);

        return (userId[msg.sender] - 1, refToken, tokens, msg.sender);
    }

    function getRewardsPlan(
        uint256 amount
    )
        internal
        pure
        returns (uint256 annually, uint256 fifteenDays, uint256 daily)
    {
        if (amount < 1000) {
            return (0, 0, 0);
        } else if (amount < 2500) {
            return (18, 75, 5);
        } else if (amount < 5000) {
            return (36, 150, 10);
        } else if (amount < 20000) {
            return (54, 225, 15);
        } else if (amount >= 20000) {
            return (72, 300, 20);
        } else {
            return (1, 1, 1);
        }
    }

    // Set bonus percent
    function setRefBonusPercentage(uint256 bonus) external onlyOwner {
        refBonusPercent = bonus;
        emit SetBonusPercentages(msg.sender, bonus);
    }

    // Owner Token Withdraw
    function withdrawTokenUsdt() external onlyOwner returns (bool) {
        require(
            usdtAddress.transfer(
                msg.sender,
                usdtAddress.balanceOf(address(this))
            ),
            "token withdrawal failed!"
        );
        return true;
    }

    function withdrawTokenBusd() external onlyOwner returns (bool) {
        require(
            busdAddress.transfer(
                msg.sender,
                busdAddress.balanceOf(address(this))
            ),
            "Token withdrawal failed!"
        );
        return true;
    }

    function withdrawTokenThunderev() external onlyOwner returns (bool) {
        require(
            thunderEvAddress.transfer(
                msg.sender,
                thunderEvAddress.balanceOf(address(this))
            ),
            "Token withdrawal failed!"
        );
        return true;
    }

    // Owner BNB Withdraw
    function withdrawBNB() external onlyOwner returns (bool) {
        payable(address(msg.sender)).transfer(address(this).balance);
        return true;
    }

    function rewardDistribution(
        address[] memory accounts,
        uint256[] memory rewards
    ) external onlyOwnerOrOperator {
        require(accounts.length == rewards.length, "wrong input");
        for (uint256 i = 0; i < accounts.length; i++) {
            require(isValidRefAddress[accounts[i]]);
            if (remainingEarning[accounts[i]] >= rewards[i]) {
                remainingEarning[accounts[i]] =
                    remainingEarning[accounts[i]] -
                    rewards[i];
                usdtAddress.transfer(accounts[i], rewards[i]);
            }
        }
    }

    // Ownership Transfer
    function transferOwnership(address to) external onlyOwner returns (bool) {
        require(to != address(0), "Transfer on this address can not be done!");
        owner = to;
        emit OwnershipTransferred(to);
        return true;
    }

    function buyersDetails(
        address buyer
    )
        external
        view
        returns (uint256 noOfTokensBought, uint256 noOfRef, uint256 tokenEarn)
    {
        return (
            totalTokenBuy[buyer],
            numberOfRef[buyer],
            tokenEarnByRef[buyer]
        );
    }

    // Fallback
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}