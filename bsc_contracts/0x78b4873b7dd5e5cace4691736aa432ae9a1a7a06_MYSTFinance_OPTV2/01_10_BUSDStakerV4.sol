// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract MYSTFinance_OPTV2 is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 public developerFee; // 300 : 3 %. 10000 : 100 %
    uint256 public rewardPeriod;
    uint256 public withdrawPeriod;
    uint256 public apr;
    uint256 public percentRate;
    address private devWallet;
    address public BUSDContract;
    uint256 public _currentDepositID;

    uint256 public totalInvestors;
    uint256 public totalReward;
    uint256 public totalInvested;

    uint256 public startDate;

    struct DepositStruct {
        address investor;
        uint256 depositAmount;
        uint256 depositAt; // deposit timestamp
        uint256 claimedAmount; // claimed busd amount
        bool state; // withdraw capital state. false if withdraw capital
    }

    struct InvestorStruct {
        address investor;
        uint256 totalLocked;
        uint256 startTime;
        uint256 lastCalculationDate;
        uint256 maxClaimableAmount;
        uint256 claimableAmount;
        uint256 claimedAmount;
    }

    // mapping from depost Id to DepositStruct
    mapping(uint256 => DepositStruct) public depositState;
    // mapping form investor to deposit IDs
    mapping(address => uint256[]) public ownedDeposits;

    //mapping from address to investor
    mapping(address => InvestorStruct) public investors;

    function initialize(
        address _devWallet,
        address _busdContract,
        uint256 _startDate
    ) public initializer {
        require(
            _devWallet != address(0),
            "Please provide a valid dev wallet address"
        );
        require(
            _busdContract != address(0),
            "Please provide a valid busd contract address"
        );
        __Ownable_init();
        __ReentrancyGuard_init();

        devWallet = _devWallet;
        BUSDContract = _busdContract;
        startDate = _startDate;

        developerFee = 300; // 300 : 3 %. 10000 : 100 %
        rewardPeriod = 1 days;
        withdrawPeriod = 4 weeks;
        apr = 50; // 150 : 0.5 %. 10000 : 100 %
        percentRate = 10000;
    }

    function resetContract(address _devWallet) public onlyOwner {
        require(_devWallet != address(0), "Please provide a valid address");
        devWallet = _devWallet;
    }

    function changeBUSDContractAddress(address _busdContract) public onlyOwner {
        require(_busdContract != address(0), "Please provide a valid address");
        BUSDContract = _busdContract;
    }

    function _getNextDepositID() private view returns (uint256) {
        return _currentDepositID + 1;
    }

    function _incrementDepositID() private {
        _currentDepositID++;
    }

    function deposit(uint256 _amount) external {
        require(block.timestamp >= startDate, "Cannot deposit at this moment");
        require(_amount > 0, "you can deposit more than 0 busd");

        IERC20Upgradeable(BUSDContract).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );

        _deposit(_amount);
    }

    function _deposit(uint256 _amount) internal {
        uint256 _id = _getNextDepositID();
        _incrementDepositID();

        uint256 depositFee = (_amount * developerFee).div(percentRate);
        // transfer 3% fee to dev wallet
        IERC20Upgradeable(BUSDContract).safeTransfer(devWallet, depositFee);

        depositState[_id].investor = msg.sender;
        depositState[_id].depositAmount = _amount - depositFee;
        depositState[_id].depositAt = block.timestamp;
        depositState[_id].state = true;

        if (investors[msg.sender].investor == address(0)) {
            totalInvestors = totalInvestors.add(1);

            investors[msg.sender].investor = msg.sender;
            investors[msg.sender].startTime = block.timestamp;
            investors[msg.sender].lastCalculationDate = block.timestamp;
        }

        // uint256 lastRoiTime = block.timestamp -
        //     investors[msg.sender].lastCalculationDate;
        uint256 maxAmount = (withdrawPeriod * (_amount - depositFee) * apr).div(
            percentRate * rewardPeriod
        );
        // uint256 allClaimableAmount = (lastRoiTime *
        //     investors[msg.sender].totalLocked *
        //     apr).div(percentRate * rewardPeriod);
        // investors[msg.sender].claimableAmount = investors[msg.sender]
        //     .claimableAmount
        //     .add(allClaimableAmount);

        investors[msg.sender].maxClaimableAmount = investors[msg.sender]
            .maxClaimableAmount
            .add(maxAmount);
        investors[msg.sender].totalLocked = investors[msg.sender]
            .totalLocked
            .add(_amount - depositFee);
        // investors[msg.sender].lastCalculationDate = block.timestamp;

        totalInvested = totalInvested.add(_amount);

        ownedDeposits[msg.sender].push(_id);
    }

    // claim all rewards of user
    function claimAllReward() public nonReentrant {
        require(
            ownedDeposits[msg.sender].length > 0,
            "you can deposit once at least"
        );

        uint256 lastRoiTime = block.timestamp -
            investors[msg.sender].lastCalculationDate;
        uint256 allClaimableAmount = (lastRoiTime *
            investors[msg.sender].totalLocked *
            apr).div(percentRate * rewardPeriod);
        // investors[msg.sender].claimableAmount = investors[msg.sender]
        //     .claimableAmount
        //     .add(allClaimableAmount);

        uint256 amountToSend = allClaimableAmount;

        if (getBalance() < amountToSend) {
            amountToSend = getBalance();
        }

        // check for if reward exceed max reward.
        if (
            investors[msg.sender].claimedAmount + amountToSend >
            investors[msg.sender].maxClaimableAmount
        ) {
            amountToSend = investors[msg.sender].maxClaimableAmount.sub(
                investors[msg.sender].claimedAmount
            );
        }

        // investors[msg.sender].claimableAmount = investors[msg.sender]
        //     .claimableAmount
        //     .sub(amountToSend);
        investors[msg.sender].claimedAmount = investors[msg.sender]
            .claimedAmount
            .add(amountToSend);
        investors[msg.sender].lastCalculationDate = block.timestamp;
        IERC20Upgradeable(BUSDContract).safeTransfer(msg.sender, amountToSend);
        totalReward = totalReward.add(amountToSend);
    }

    // claim all rewards of user
    function compoundAllReward() public nonReentrant {
        require(
            ownedDeposits[msg.sender].length > 0,
            "you can deposit once at least"
        );

        uint256 lastRoiTime = block.timestamp -
            investors[msg.sender].lastCalculationDate;
        uint256 allClaimableAmount = (lastRoiTime *
            investors[msg.sender].totalLocked *
            apr).div(percentRate * rewardPeriod);
        // investors[msg.sender].claimableAmount = investors[msg.sender]
        //     .claimableAmount
        //     .add(allClaimableAmount);

        uint256 amountToSend = allClaimableAmount;

        if (getBalance() < amountToSend) {
            amountToSend = getBalance();
        }

        // investors[msg.sender].claimableAmount = investors[msg.sender]
        //     .claimableAmount
        //     .sub(amountToSend);

        // check for if reward exceed max reward.
        if (
            investors[msg.sender].claimedAmount + amountToSend >
            investors[msg.sender].maxClaimableAmount
        ) {
            amountToSend = investors[msg.sender].maxClaimableAmount.sub(
                investors[msg.sender].claimedAmount
            );
        }

        require(amountToSend != 0, "Insufficient Reward!");

        investors[msg.sender].claimedAmount = investors[msg.sender]
            .claimedAmount
            .add(amountToSend);
        investors[msg.sender].lastCalculationDate = block.timestamp;

        _deposit(amountToSend);
        totalReward = totalReward.add(amountToSend);
    }

    // Redeposit Capital
    function redepositCapital(uint256 id) public nonReentrant {
        require(
            depositState[id].investor == msg.sender,
            "only investor of this id can redeposit"
        );
        require(
            depositState[id].depositAt + withdrawPeriod < block.timestamp,
            "withdraw lock time is not finished yet"
        );
        require(depositState[id].state, "you already withdrawed capital");
        require(
            depositState[id].depositAmount <= getBalance(),
            "no enough busd in pool"
        );

        investors[msg.sender].totalLocked = investors[msg.sender]
            .totalLocked
            .sub(depositState[id].depositAmount);

        uint256 amountToSend = depositState[id].depositAmount;

        // transfer capital to the user
        _deposit(amountToSend);
        depositState[id].state = false;
    }

    // withdraw capital by deposit id
    function withdrawCapital(uint256 id) public nonReentrant {
        require(
            depositState[id].investor == msg.sender,
            "only investor of this id can claim reward"
        );
        require(
            depositState[id].depositAt + withdrawPeriod < block.timestamp,
            "withdraw lock time is not finished yet"
        );
        require(depositState[id].state, "you already withdrawed capital");

        uint256 claimableReward = getAllClaimableReward(msg.sender);

        require(
            depositState[id].depositAmount + claimableReward <= getBalance(),
            "no enough busd in pool"
        );

        // investors[msg.sender].claimableAmount = 0;
        investors[msg.sender].claimedAmount = investors[msg.sender]
            .claimedAmount
            .add(claimableReward);
        investors[msg.sender].lastCalculationDate = block.timestamp;
        investors[msg.sender].totalLocked = investors[msg.sender]
            .totalLocked
            .sub(depositState[id].depositAmount);

        uint256 amountToSend = depositState[id].depositAmount + claimableReward;

        // transfer capital to the user
        IERC20Upgradeable(BUSDContract).safeTransfer(msg.sender, amountToSend);
        totalReward = totalReward.add(claimableReward);

        depositState[id].state = false;
    }

    function getOwnedDeposits(address investor)
        public
        view
        returns (uint256[] memory)
    {
        return ownedDeposits[investor];
    }

    function getAllClaimableReward(address _investor)
        public
        view
        returns (uint256)
    {
        uint256 lastRoiTime = block.timestamp -
            investors[_investor].lastCalculationDate;
        uint256 allClaimableAmount = (lastRoiTime *
            investors[_investor].totalLocked *
            apr).div(percentRate * rewardPeriod);

        // check for if reward exceed max reward.
        if (
            investors[_investor].claimedAmount + allClaimableAmount >
            investors[_investor].maxClaimableAmount
        ) {
            allClaimableAmount = investors[_investor].maxClaimableAmount.sub(
                investors[_investor].claimedAmount
            );
        }
        return allClaimableAmount;
    }

    function depositFunds(uint256 _amount) external onlyOwner returns (bool) {
        require(_amount > 0, "you can deposit more than 0 BUSD");
        IERC20Upgradeable(BUSDContract).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        return true;
    }

    function withdrawFunds(uint256 _amount) external onlyOwner nonReentrant {
        // transfer fund
        IERC20Upgradeable(BUSDContract).safeTransfer(msg.sender, _amount);
    }

    function getBalance() public view returns (uint256) {
        return IERC20Upgradeable(BUSDContract).balanceOf(address(this));
    }

    // calculate total rewards
    function getTotalRewards() public view returns (uint256) {
        return totalReward;
    }

    // calculate total invests
    function getTotalInvests() public view returns (uint256) {
        return totalInvested;
    }

    function updateRewardPeriod(uint256 _duration) external onlyOwner {
        rewardPeriod = _duration;
    }

    function updateWithdrawPeriod(uint256 _duration) external onlyOwner {
        withdrawPeriod = _duration;
    }
}