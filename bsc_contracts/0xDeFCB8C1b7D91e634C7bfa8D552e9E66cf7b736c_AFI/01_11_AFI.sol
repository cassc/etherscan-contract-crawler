// SPDX-License-Identifier: MIT

library Math {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function pow(uint256 a, uint256 b) internal pure returns (uint256) {
        return a ** b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AFI is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    ///@dev no constructor in upgradable contracts. Instead we have initializers
    function initialize() public initializer {
        ///@dev as there is no constructor, we need to initialise the OwnableUpgradeable explicitly
        __Ownable_init();
        PROJECT_OWNER_ADDRESS = 0x3458699B3A27C5c0662DfD405BeFdCd6a191c661;
        CONTRACT_DEV_ADDRESS = 0xbab5B268bBa1E1ED488e5C91b6df3966bC8d8EeE;
        REVENUE_ADDRESS = 0x0C6d20b8358d0Cc52d94E7B64c49881C3cBf5CBB;
        OWNER_ADDRESS = _msgSender();
        TOKEN_ADDRESS = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
        _projectOwner = payable(PROJECT_OWNER_ADDRESS);
        _contractDev = payable(CONTRACT_DEV_ADDRESS);
        _revenue = payable(REVENUE_ADDRESS);
        _owner = payable(OWNER_ADDRESS);
        SECONDS_PER_DAY = 86400;
        DEPOSIT_FEE = 1;
        CLAIMREWARDS_FEE = 1;
        UNSTAKING_FEE = 1;
        REF_BONUS = 2;
        MIN_DEPOSIT = 1000000000000000000; // 1 token
        MAX_DEPOSIT = 15000000000000000000000; // 15000 tokens

        _token = IERC20(TOKEN_ADDRESS);

        _NOT_ENTERED = 1;
        _ENTERED = 2;
        _status = _NOT_ENTERED;
    }

    ///@dev required by the OZ UUPS module
    function _authorizeUpgrade(address) internal override onlyOwner {}

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    modifier onlyProjectOwner() {
        require(msg.sender == PROJECT_OWNER_ADDRESS);
        _;
    }

    using Math for uint256;

    IERC20 public _token;
    uint256 public CONTRACT_INITIATED_AT;
    bool public CONTRACT_LIVE;
    bool public DEPOSITS_DISABLED;
    bool public UNSTAKING_DISABLED;
    uint256 public UNSTAKING_DISABLED_AT;

    address private PROJECT_OWNER_ADDRESS;
    address private CONTRACT_DEV_ADDRESS;
    address private REVENUE_ADDRESS;
    address private OWNER_ADDRESS;
    address private TOKEN_ADDRESS;
    address payable internal _projectOwner;
    address payable internal _contractDev;
    address payable internal _revenue;
    address payable internal _owner;

    uint256 private SECONDS_PER_DAY;
    uint8 private DEPOSIT_FEE;
    uint8 private CLAIMREWARDS_FEE;
    uint8 private UNSTAKING_FEE;
    uint8 private REF_BONUS;
    uint256 private MIN_DEPOSIT;
    uint256 private MAX_DEPOSIT;

    uint256 public totalUsers;
    uint256 public totalCurrentInvested;
    uint256 public totalRewardPayouts;

    uint256 private _NOT_ENTERED;
    uint256 private _ENTERED;
    uint256 private _status;

    struct Deposit {
        uint256 amount;
        uint256 start;
    }

    struct User {
        uint256 lastClaimAt;
        Deposit[] deposits;
        uint256 firstDeposit;
        uint256 totalDeposit;
        uint256 totalPayout;
        uint256 pendingRefRewards;
        address upline;
        address[] referrals;
        uint256 totalRefRewardsReceived;
    }

    mapping(address => User) internal users;

    event EmitDeposited(
        address indexed adr,
        address indexed ref,
        uint256 tokenAmount,
        uint256 tokensFrom,
        uint256 tokensTo
    );
    event EmitUnstaked(
        uint8 index,
        address indexed adr,
        uint256 tokensToClaim,
        uint256 tokensBeforeFee,
        uint256 pendingRewardsBeforeFee
    );

    event EmitClaimedRewards(
        address indexed adr,
        uint256 tokensToClaim,
        uint256 tokensBeforeFee
    );
    event EmitRevenueOwnerDeposit(uint256 tokenAmount);
    event EmitInjection(uint256 injected);

    function intitate() public onlyProjectOwner {
        CONTRACT_INITIATED_AT = block.timestamp;
        CONTRACT_LIVE = true;
    }

    function disableUnstaking(bool disable) public onlyProjectOwner {
        UNSTAKING_DISABLED = disable;
        if (disable == true) {
            UNSTAKING_DISABLED_AT = block.timestamp;
        }
    }

    function disableDeposits(bool disable) public onlyProjectOwner {
        DEPOSITS_DISABLED = disable;
    }

    function toggleContract(bool live) public onlyProjectOwner {
        CONTRACT_LIVE = live;
    }

    function revenueOwnerDeposit(uint256 tokens) public onlyProjectOwner {
        bool revSuccess = _token.transferFrom(
            address(msg.sender),
            address(this),
            tokens
        );
        if (revSuccess == false) {
            revert("Owner deposit token transfer failed");
        }
        emit EmitRevenueOwnerDeposit(tokens);
    }

    function user(address adr) public view returns (User memory) {
        return users[adr];
    }

    function inject(uint256 tokens) public onlyProjectOwner {
        bool success = _token.transferFrom(
            address(msg.sender),
            address(this),
            tokens
        );
        if (success == false) {
            revert("Contract token transfer failed");
        }
        emit EmitInjection(tokens);
    }

    function deposit(uint256 tokens, address ref) public nonReentrant {
        require(CONTRACT_LIVE == true, "Contract not live");
        require(DEPOSITS_DISABLED == false, "Deposits have been disabled");
        require(
            tokens >= MIN_DEPOSIT,
            "Deposit doesn't meet the minimum requirements"
        );
        require(
            tokens.add(users[msg.sender].totalDeposit) <=
                MAX_DEPOSIT,
            "Max deposit reached"
        );
        require(users[msg.sender].deposits.length < 10, "Max deposits made");

        uint256 totalFee = percentFromAmount(tokens, DEPOSIT_FEE);
        uint256 tokensAfterFee = Math.sub(tokens, totalFee);

        bool success = _token.transferFrom(
            address(msg.sender),
            address(this),
            tokens
        );
        if (success == false) {
            revert("Contract token transfer failed");
        }

        uint256 revenueDeposit = percentFromAmount(tokens, 55);
        bool revSuccess = _token.transfer(_revenue, revenueDeposit);
        if (revSuccess == false) {
            revert("Revenue token transfer failed");
        }

        if (
            ref != msg.sender &&
            ref != address(0) &&
            users[msg.sender].upline == address(0)
        ) {
            users[msg.sender].upline = ref;
            users[ref].referrals.push(msg.sender);

            uint256 refBonus = percentFromAmount(tokens, REF_BONUS);
            users[ref].pendingRefRewards = users[ref].pendingRefRewards.add(
                refBonus
            );
            users[ref].totalRefRewardsReceived = users[ref].totalRefRewardsReceived.add(refBonus);
        }

        if (hasInvested(msg.sender) == false) {
            users[msg.sender].firstDeposit = block.timestamp;
            totalUsers++;
        }

        users[msg.sender].deposits.push(Deposit(tokens, block.timestamp));
        users[msg.sender].totalDeposit = Math.add(users[msg.sender].totalDeposit, tokens);

        totalCurrentInvested = totalCurrentInvested.add(tokens);

        sendFees(totalFee);

        emit EmitDeposited(msg.sender, ref, tokens, users[msg.sender].totalDeposit, tokensAfterFee);
    }

    function sendFees(uint256 totalFee) private {
        uint256 projectOwner = percentFromAmount(totalFee, 50);
        uint256 contractDev = percentFromAmount(totalFee, 50);

        _token.transfer(_projectOwner, projectOwner);
        _token.transfer(_contractDev, contractDev);
    }

    function claimRewards() public nonReentrant {
        require(CONTRACT_LIVE == true, "Contract not live");
        require(
            hasInvested(msg.sender) || users[msg.sender].pendingRefRewards > 0,
            "Must be invested or have pending ref rewards to claim"
        );
        require(
            daysSinceLastClaim(msg.sender) >= 10,
            "Must wait 10 days between each claim"
        );

        uint256 tokensBeforeFee = allPendingRewards(msg.sender);
        uint256 totalFee = 0;
        uint256 tokensAfterFee = tokensBeforeFee;

        if (CLAIMREWARDS_FEE > 0) {
            totalFee = percentFromAmount(tokensBeforeFee, CLAIMREWARDS_FEE);
            tokensAfterFee = Math.sub(tokensAfterFee, totalFee);
        }

        users[msg.sender].totalPayout = Math.add(users[msg.sender].totalPayout, tokensBeforeFee);

        users[msg.sender].lastClaimAt = block.timestamp;
        users[msg.sender].pendingRefRewards = 0;

        totalRewardPayouts = totalRewardPayouts.add(tokensBeforeFee);

        _token.transfer(msg.sender, tokensAfterFee);

        emit EmitClaimedRewards(msg.sender, tokensAfterFee, tokensBeforeFee);
    }

    function unstake(uint8 index) public nonReentrant {
        require(CONTRACT_LIVE == true, "Contract not live");
        require(UNSTAKING_DISABLED == false, "Unstaking disabled");
        require(hasInvested(msg.sender), "Must be invested to claim");
        require(index < users[msg.sender].deposits.length, "Index must be in range of active deposits");

        require(
            block.timestamp.sub(users[msg.sender].deposits[index].start) >= 60 days,
            "You can't unstake until after 60 days"
        );

        uint256 totalFee = percentFromAmount(
            users[msg.sender].deposits[index].amount,
            UNSTAKING_FEE
        );
        uint256 tokensAfterFee = Math.sub(users[msg.sender].deposits[index].amount, totalFee);
        uint256 pendingRewards = rewardedTokens(msg.sender, index);
        tokensAfterFee = tokensAfterFee.add(pendingRewards);

        users[msg.sender].totalDeposit = Math.sub(
            users[msg.sender].totalDeposit,
            users[msg.sender].deposits[index].amount
        );

        totalCurrentInvested = totalCurrentInvested.sub(users[msg.sender].deposits[index].amount);
        uint256 unstakedAmount = users[msg.sender].deposits[index].amount;

        removeDeposit(msg.sender, index);

        _token.transfer(msg.sender, tokensAfterFee);

        emit EmitUnstaked(
            index,
            msg.sender,
            tokensAfterFee,
            unstakedAmount,
            pendingRewards
        );
    }

    function removeDeposit(address adr, uint index) private {
        if (index >= users[adr].deposits.length) return;

        for (uint i = index; i < users[adr].deposits.length - 1; i++) {
            users[adr].deposits[i] = users[adr].deposits[i + 1];
        }

        users[adr].deposits.pop();
    }

    function contractBalance() public view returns (uint256) {
        return _token.balanceOf(address(this));
    }

    function secondsSinceLastClaim(address adr) public view returns (uint256) {
        uint256 lastClaimOrFirstDeposit = users[adr].lastClaimAt;
        if (users[adr].lastClaimAt == 0) {
            lastClaimOrFirstDeposit = users[adr].firstDeposit;
        }
        if (lastClaimOrFirstDeposit == 0) {
            lastClaimOrFirstDeposit = CONTRACT_INITIATED_AT;
        }
        uint256 secondsPassed = Math.sub(
            block.timestamp,
            lastClaimOrFirstDeposit
        );
        return secondsPassed;
    }

    function setMaxDeposit(uint256 newMaxDeposit) public onlyProjectOwner {
        MAX_DEPOSIT = newMaxDeposit;
    }

    function setClaimRewardsFee(uint8 newFee) public onlyProjectOwner {
        CLAIMREWARDS_FEE = newFee;
    }

    function daysSinceLastClaim(address adr) private view returns (uint256) {
        uint256 secondsPassed = secondsSinceLastClaim(adr);
        return Math.div(secondsPassed, SECONDS_PER_DAY);
    }

    function hasInvested(address adr) public view returns (bool) {
        return users[adr].firstDeposit != 0;
    }

    function percentFromAmount(
        uint256 amount,
        uint256 fee
    ) private pure returns (uint256) {
        return Math.div(Math.mul(amount, fee), 100);
    }

    function allPendingRewards(address adr) public view returns (uint256) {
        uint256 tokensBeforeFee = 0;
        for (uint8 i = 0; i < users[adr].deposits.length; i++) {
            uint256 depositRewards = rewardedTokens(adr, i);
            tokensBeforeFee = tokensBeforeFee.add(depositRewards);
        }
        tokensBeforeFee = tokensBeforeFee.add(users[adr].pendingRefRewards);
        return tokensBeforeFee;
    }

    function rewardedTokens(
        address adr,
        uint8 index
    ) public view returns (uint256) {
        if (index >= users[msg.sender].deposits.length) {
            return 0;
        }
        uint256 lastClaimOrStart = users[adr].deposits[index].start;
        if (users[adr].lastClaimAt > lastClaimOrStart) {
            lastClaimOrStart = users[adr].lastClaimAt;
        }

        uint256 stakeEndingAt = users[adr].deposits[index].start.add(SECONDS_PER_DAY.mul(60));
        bool continueAfterStakeEnded = false;
        if (
            UNSTAKING_DISABLED_AT > 0 &&
            UNSTAKING_DISABLED_AT < stakeEndingAt
        ) {
            continueAfterStakeEnded = true;
        }

        uint256 secondsPassed = block.timestamp.sub(lastClaimOrStart);
        if (lastClaimOrStart > stakeEndingAt) {
            return 0;
        }
        if (block.timestamp > stakeEndingAt && stakeEndingAt > lastClaimOrStart) {
            secondsPassed = stakeEndingAt.sub(lastClaimOrStart);
        }

        if (continueAfterStakeEnded) {
            secondsPassed = block.timestamp.sub(lastClaimOrStart);
        }

        secondsPassed = Math.min(SECONDS_PER_DAY.mul(12), secondsPassed);
        if (secondsPassed == 0) {
            return 0;
        }

        uint256 rewards = calcReward(secondsPassed, adr, index);

        return rewards;
    }

    function calcReward(
        uint256 secondsPassed,
        address adr,
        uint8 index
    ) private view returns (uint256) {
        uint256 rewardsPerDay = percentFromAmount(
            Math.mul(users[adr].deposits[index].amount, 10000000000),
            500000
        );
        uint256 rewardsPerSecond = Math.div(rewardsPerDay, SECONDS_PER_DAY);
        uint256 rewards = Math.mul(rewardsPerSecond, secondsPassed);
        rewards = Math.div(rewards, 10000000000000000);
        return rewards;
    }
}