// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract MYSTFinance_OPTV18 is
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
        uint256 maxAmount;
        uint256 claimedAt;
        uint256 apr;
        bool isFlexible;
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
    // For emergency pause.
    bool public paused;
    uint256 public maxDepositLimit;

    // MXST States
    address public MXSTContract;
    uint256 public totalStakers;
    uint256 public totalMXSTStaked;

    struct StakeInfo {
        uint256 startTS;
        uint256 endTS;
        uint256 amount;
        bool claimed;
    }

    struct MXSTInfo {
        uint256 count;
        uint256 totalStaked;
        uint256 claimedReward;
        mapping(uint256 => StakeInfo) stakes;
    }

    event Staked(address indexed from, uint256 amount);
    event Claimed(address indexed from, uint256 amount);

    mapping(address => MXSTInfo) public stakeInfos;

    // MXST States End
    mapping(address => bool) public isBlacklisted;
    bool public isDevFeeDisabled;
    uint256 public perDayPenalty;
    bool public isRewardDisabled;
    uint256 public rewardCalcFrom;

    uint256 public cycleEndAt;
    uint256 public currentClaimCycle;
    struct InitialClaimRecord {
        uint256 claimedAt;
        uint256 claimedAmount;
        uint256 totalClaimable;
        uint256 totalDeposited;
        uint256 lastClaimedCycle;
    }
    mapping(address => InitialClaimRecord) public initialClaimRecords;

    modifier checkForPause() {
        require(!paused, "Withdraw paused!!!");
        _;
    }

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
        require(
            investors[msg.sender].totalLocked + _amount <= maxDepositLimit,
            "Deposit: Limit Exceed"
        );

        IERC20Upgradeable(BUSDContract).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );

        (uint256 _apr, uint256 _devFee) = getCurrentUserFees(msg.sender);
        _deposit(_amount, _apr, _devFee);
    }

    function _deposit(
        uint256 _amount,
        uint256 _apr,
        uint256 _developerFee
    ) internal {
        uint256 _id = _getNextDepositID();
        _incrementDepositID();

        uint256 depositFee = (_amount * _developerFee).div(percentRate);
        // transfer 3% fee to dev wallet
        IERC20Upgradeable(BUSDContract).safeTransfer(devWallet, depositFee);

        depositState[_id].depositAmount = _amount - depositFee;
        depositState[_id].depositAt = block.timestamp;
        depositState[_id].claimedAt = block.timestamp;
        depositState[_id].investor = msg.sender;
        depositState[_id].isFlexible = true;
        depositState[_id].state = true;

        if (investors[msg.sender].investor == address(0)) {
            totalInvestors = totalInvestors.add(1);

            investors[msg.sender].investor = msg.sender;
            investors[msg.sender].startTime = block.timestamp;
            investors[msg.sender].lastCalculationDate = block.timestamp;
        }

        uint256 maxAmount = (withdrawPeriod * (_amount - depositFee) * _apr)
            .div(percentRate * rewardPeriod);
        depositState[_id].maxAmount = maxAmount;

        investors[msg.sender].maxClaimableAmount = investors[msg.sender]
            .maxClaimableAmount
            .add(maxAmount);
        investors[msg.sender].totalLocked = investors[msg.sender]
            .totalLocked
            .add(_amount - depositFee);

        totalInvested = totalInvested.add(_amount);
        ownedDeposits[msg.sender].push(_id);
    }

    // claim all rewards of user according to mxst stake apr
    function claimAllReward() public nonReentrant {
        require(!isBlacklisted[msg.sender], "Address Blacklisted!!!");
        require(
            ownedDeposits[msg.sender].length > 0,
            "you can deposit once at least"
        );
        (uint256 _apr, ) = getCurrentTierUserFees(msg.sender);
        claim(msg.sender, _apr);
    }

    function claim(address investor, uint256 _apr) internal checkForPause {
        uint256 prevLockedAmount;
        uint256 allClaimableAmount;
        uint256[] memory userDeposits = ownedDeposits[investor];
        for (uint256 i = 0; i < userDeposits.length; i++) {
            DepositStruct memory _depState = depositState[userDeposits[i]];
            if (_depState.maxAmount != 0 && _depState.claimedAt != 0) {
                uint256 _curReward = updateDepositState(
                    investor,
                    userDeposits[i]
                );
                allClaimableAmount = allClaimableAmount.add(_curReward);
            } else if (_depState.state) {
                prevLockedAmount = prevLockedAmount.add(
                    _depState.depositAmount
                );
            }
        }
        uint256 lastRoiTime = block.timestamp -
            investors[investor].lastCalculationDate;
        uint256 prevReward = (lastRoiTime * prevLockedAmount * _apr).div(
            percentRate * rewardPeriod
        );
        allClaimableAmount = allClaimableAmount.add(prevReward);
        // check for if reward exceed max reward.
        if (
            investors[investor].claimedAmount + allClaimableAmount >
            investors[investor].maxClaimableAmount
        ) {
            allClaimableAmount = investors[investor].maxClaimableAmount.sub(
                investors[investor].claimedAmount
            );
        }

        require(allClaimableAmount <= getBalance(), "no enough busd in pool");

        investors[investor].claimedAmount = investors[investor]
            .claimedAmount
            .add(allClaimableAmount);
        investors[investor].lastCalculationDate = block.timestamp;
        IERC20Upgradeable(BUSDContract).safeTransfer(
            investor,
            allClaimableAmount
        );
        // If user is on tier 3,4,5 reward mxst tokens.
        if (stakeInfos[investor].totalStaked >= 500000e18) {
            if (allClaimableAmount > 0) {
                IERC20Upgradeable(MXSTContract).safeTransfer(
                    investor,
                    allClaimableAmount
                );
            }
        }
        totalReward = totalReward.add(allClaimableAmount);
    }

    // Compound all rewards of user
    function compoundAllReward() public nonReentrant checkForPause {
        require(
            ownedDeposits[msg.sender].length > 0,
            "you can deposit once at least"
        );
        (uint256 _apr, uint256 _devFee) = getCurrentUserFees(msg.sender);
        (uint256 _rApr, ) = getCurrentTierUserFees(msg.sender);

        uint256 prevLockedAmount;
        uint256 allClaimableAmount;
        uint256[] memory userDeposits = ownedDeposits[msg.sender];
        for (uint256 i = 0; i < userDeposits.length; i++) {
            DepositStruct memory _depState = depositState[userDeposits[i]];
            if (_depState.maxAmount != 0 && _depState.claimedAt != 0) {
                uint256 _curReward = updateDepositState(
                    msg.sender,
                    userDeposits[i]
                );
                allClaimableAmount = allClaimableAmount.add(_curReward);
            } else if (_depState.state) {
                prevLockedAmount = prevLockedAmount.add(
                    _depState.depositAmount
                );
            }
        }

        uint256 lastRoiTime = block.timestamp -
            investors[msg.sender].lastCalculationDate;
        uint256 prevReward = (lastRoiTime * prevLockedAmount * _rApr).div(
            percentRate * rewardPeriod
        );
        allClaimableAmount = allClaimableAmount.add(prevReward);

        // check for if reward exceed max reward.
        if (
            investors[msg.sender].claimedAmount + allClaimableAmount >
            investors[msg.sender].maxClaimableAmount
        ) {
            allClaimableAmount = investors[msg.sender].maxClaimableAmount.sub(
                investors[msg.sender].claimedAmount
            );
        }
        require(allClaimableAmount != 0, "Insufficient Reward!");

        investors[msg.sender].claimedAmount = investors[msg.sender]
            .claimedAmount
            .add(allClaimableAmount);
        investors[msg.sender].lastCalculationDate = block.timestamp;

        _deposit(allClaimableAmount, _apr, _devFee);
        if (stakeInfos[msg.sender].totalStaked >= 500000e18) {
            if (allClaimableAmount > 0) {
                IERC20Upgradeable(MXSTContract).safeTransfer(
                    msg.sender,
                    allClaimableAmount
                );
            }
        }
        totalReward = totalReward.add(allClaimableAmount);
    }

    // Redeposit Capital
    function redepositCapital(uint256 id) public nonReentrant checkForPause {
        require(
            depositState[id].investor == msg.sender,
            "only investor of this id can redeposit"
        );
        require(
            depositState[id].depositAt + withdrawPeriod < block.timestamp,
            "withdraw lock time is not finished yet"
        );
        require(depositState[id].state, "you already withdrawed capital");

        // Withdraw previous reward
        (uint256 _apr, uint256 _devFee) = getCurrentUserFees(msg.sender);
        (uint256 _rApr, ) = getCurrentTierUserFees(msg.sender);
        uint256 prevLockedAmount;
        uint256 claimableReward;
        uint256[] memory userDeposits = ownedDeposits[msg.sender];
        for (uint256 i = 0; i < userDeposits.length; i++) {
            DepositStruct memory _depState = depositState[userDeposits[i]];
            if (_depState.maxAmount != 0 && _depState.claimedAt != 0) {
                uint256 _curReward = updateDepositState(
                    msg.sender,
                    userDeposits[i]
                );
                claimableReward = claimableReward.add(_curReward);
            } else if (_depState.state) {
                prevLockedAmount = prevLockedAmount.add(
                    _depState.depositAmount
                );
            }
        }
        uint256 lastRoiTime = block.timestamp -
            investors[msg.sender].lastCalculationDate;
        uint256 prevReward = (lastRoiTime * prevLockedAmount * _rApr).div(
            percentRate * rewardPeriod
        );
        claimableReward = claimableReward.add(prevReward);
        // check for if reward exceed max reward.
        if (
            investors[msg.sender].claimedAmount + claimableReward >
            investors[msg.sender].maxClaimableAmount
        ) {
            claimableReward = investors[msg.sender].maxClaimableAmount.sub(
                investors[msg.sender].claimedAmount
            );
        }

        require(claimableReward <= getBalance(), "no enough busd in pool");

        investors[msg.sender].claimedAmount = investors[msg.sender]
            .claimedAmount
            .add(claimableReward);
        investors[msg.sender].lastCalculationDate = block.timestamp;
        investors[msg.sender].totalLocked = investors[msg.sender]
            .totalLocked
            .sub(depositState[id].depositAmount);

        uint256 amountToSend = depositState[id].depositAmount;

        // transfer reward to the user
        IERC20Upgradeable(BUSDContract).safeTransfer(
            msg.sender,
            claimableReward
        );
        if (stakeInfos[msg.sender].totalStaked >= 500000e18) {
            if (claimableReward > 0) {
                IERC20Upgradeable(MXSTContract).safeTransfer(
                    msg.sender,
                    claimableReward
                );
            }
        }
        totalReward = totalReward.add(claimableReward);

        // transfer capital to the user
        _deposit(amountToSend, _apr, _devFee);
        depositState[id].state = false;
    }

    // withdraw capital by deposit id
    function withdrawCapital(uint256 id) public nonReentrant checkForPause {
        require(!isBlacklisted[msg.sender], "Address Blacklisted!!!");
        require(
            depositState[id].investor == msg.sender,
            "only investor of this id can claim reward"
        );
        if (!depositState[id].isFlexible) {
            require(
                depositState[id].depositAt + withdrawPeriod < block.timestamp,
                "withdraw lock time is not finished yet"
            );
        }
        require(depositState[id].state, "you already withdrawed capital");

        distributeCapital(msg.sender, id);
    }

    function distributeCapital(address _investor, uint256 id) internal {
        (uint256 _apr, ) = getCurrentTierUserFees(_investor);
        uint256 prevLockedAmount;
        uint256 claimableReward;

        // Calculating Reward.
        uint256[] memory userDeposits = ownedDeposits[_investor];
        for (uint256 i = 0; i < userDeposits.length; i++) {
            DepositStruct memory _depState = depositState[userDeposits[i]];
            if (_depState.maxAmount != 0 && _depState.claimedAt != 0) {
                uint256 _curReward = updateDepositState(
                    _investor,
                    userDeposits[i]
                );
                claimableReward = claimableReward.add(_curReward);
            } else if (_depState.state) {
                prevLockedAmount = prevLockedAmount.add(
                    _depState.depositAmount
                );
            }
        }
        uint256 lastRoiTime = block.timestamp -
            investors[_investor].lastCalculationDate;
        uint256 prevReward = (lastRoiTime * prevLockedAmount * _apr).div(
            percentRate * rewardPeriod
        );
        claimableReward = claimableReward.add(prevReward);
        // check for if reward exceed max reward.
        if (
            investors[_investor].claimedAmount + claimableReward >
            investors[_investor].maxClaimableAmount
        ) {
            claimableReward = investors[_investor].maxClaimableAmount.sub(
                investors[_investor].claimedAmount
            );
        }

        require(
            depositState[id].depositAmount + claimableReward <= getBalance(),
            "no enough busd in pool"
        );
        // Calculating Reward.

        investors[_investor].claimedAmount = investors[_investor]
            .claimedAmount
            .add(claimableReward);
        investors[_investor].lastCalculationDate = block.timestamp;
        investors[_investor].totalLocked = investors[_investor].totalLocked.sub(
            depositState[id].depositAmount
        );
        // uint256 amountToSend = depositState[id].depositAmount + claimableReward;

        // Calcualte Penalty & adjust reward
        uint256 penaltyAmount = adjustReward(_investor, id);

        // transfer capital to the user
        IERC20Upgradeable(BUSDContract).safeTransfer(
            _investor,
            depositState[id].depositAmount.sub(penaltyAmount)
        );
        IERC20Upgradeable(BUSDContract).safeTransfer(
            _investor,
            claimableReward
        );
        if (stakeInfos[_investor].totalStaked >= 500000e18) {
            if (claimableReward > 0) {
                IERC20Upgradeable(MXSTContract).safeTransfer(
                    _investor,
                    claimableReward
                );
            }
        }
        totalReward = totalReward.add(claimableReward);
        depositState[id].state = false;
    }

    function adjustReward(address _investor, uint256 _depostiID)
        internal
        returns (uint256 penaltyAmount)
    {
        if (
            block.timestamp <
            depositState[_depostiID].depositAt + withdrawPeriod
        ) {
            {
                uint256 penaltyDays = (
                    (depositState[_depostiID].depositAt + withdrawPeriod).sub(
                        block.timestamp
                    )
                ).div(rewardPeriod);
                penaltyAmount = (
                    depositState[_depostiID]
                        .depositAmount
                        .mul(perDayPenalty)
                        .div(percentRate)
                ).mul(penaltyDays);
            }

            // Adjust max reward.
            {
                DepositStruct storage depState = depositState[_depostiID];
                uint256 remainingReward = depState.maxAmount.sub(
                    depState.claimedAmount
                );
                depState.maxAmount = depState.maxAmount.sub(remainingReward);
                investors[_investor].maxClaimableAmount = investors[_investor]
                    .maxClaimableAmount
                    .sub(remainingReward);
            }
        }
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
        (uint256 _apr, ) = getCurrentTierUserFees(_investor);
        uint256 prevLockedAmount;
        uint256 allClaimableAmount;
        uint256[] memory userDeposits = ownedDeposits[_investor];
        for (uint256 i = 0; i < userDeposits.length; i++) {
            DepositStruct memory _depState = depositState[userDeposits[i]];
            if (_depState.maxAmount != 0 && _depState.claimedAt != 0) {
                (uint256 _curReward, ) = getClaimableReward(
                    _investor,
                    userDeposits[i]
                );
                allClaimableAmount = allClaimableAmount.add(_curReward);
            } else if (_depState.state) {
                prevLockedAmount = prevLockedAmount.add(
                    _depState.depositAmount
                );
            }
        }
        uint256 lastRoiTime = block.timestamp -
            investors[_investor].lastCalculationDate;
        uint256 prevReward = (lastRoiTime * prevLockedAmount * _apr).div(
            percentRate * rewardPeriod
        );
        allClaimableAmount = allClaimableAmount.add(prevReward);

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

    function getClaimableReward(address _user, uint256 _depositId)
        public
        view
        returns (uint256 _tAmount, uint256 _maxAmount)
    {
        DepositStruct memory depState = depositState[_depositId];
        (uint256 _apr, ) = getCurrentTierUserFees(_user);

        // set last claim time if user deposit before upgrade or after
        uint256 lastClaimTime = investors[_user].lastCalculationDate;
        if (depState.claimedAt == 0) {
            if (lastClaimTime < depState.depositAt) {
                lastClaimTime = depState.depositAt;
            }
        } else {
            lastClaimTime = depState.claimedAt;
        }

        uint256 lastRoiTime = block.timestamp - lastClaimTime;
        _maxAmount = depState.maxAmount;
        if (_maxAmount == 0) {
            _maxAmount = (withdrawPeriod * depState.depositAmount * _apr).div(
                percentRate * rewardPeriod
            );
        }
        _tAmount = (lastRoiTime * depState.depositAmount * _apr).div(
            percentRate * rewardPeriod
        );

        // check for if reward exceed max reward.
        if (depState.claimedAmount + _tAmount > _maxAmount) {
            _tAmount = _maxAmount.sub(depState.claimedAmount);
        }
    }

    function updateDepositState(address _user, uint256 _depositId)
        internal
        returns (uint256)
    {
        DepositStruct storage depState = depositState[_depositId];
        (uint256 _curReward, ) = getClaimableReward(_user, _depositId);
        depState.claimedAmount = depState.claimedAmount.add(_curReward);
        depState.claimedAt = block.timestamp;
        return _curReward;
    }

    function emergencyPause(bool _state) external onlyOwner {
        paused = _state;
    }

    function setMaxDepositLimit(uint256 _amount) external onlyOwner {
        maxDepositLimit = _amount;
    }

    // MXST Stake
    function stakeMXSTToken(uint256 stakeAmount) external {
        require(stakeAmount > 0, "Stake amount should be correct");
        IERC20Upgradeable(MXSTContract).transferFrom(
            _msgSender(),
            address(this),
            stakeAmount
        );

        uint256 counter = ++stakeInfos[msg.sender].count;
        StakeInfo storage _info = stakeInfos[msg.sender].stakes[counter];
        uint256 msxstAmount = getLockedMXST(msg.sender) + stakeAmount;
        uint256 _apr;

        if (msxstAmount >= 50000e18 && msxstAmount < 500000e18) {
            _apr = 75;
        } else if (msxstAmount >= 500000e18 && msxstAmount < 2500000e18) {
            _apr = 100;
        } else if (msxstAmount >= 2500000e18 && msxstAmount < 15000000e18) {
            _apr = 125;
        } else if (msxstAmount >= 15000000e18) {
            _apr = 150;
        } else {
            _apr = 50;
        }

        if (ownedDeposits[msg.sender].length > 0) {
            // Function Called for Claiming
            (uint256 _curApr, ) = getCurrentTierUserFees(msg.sender);
            claim(msg.sender, _curApr);
            // update their apr
            updateAprbyMXST(msg.sender, _apr);
        }

        if (counter == 1) {
            totalStakers++;
        }
        _info.amount = stakeAmount;
        _info.startTS = block.timestamp;
        _info.endTS = block.timestamp + withdrawPeriod;
        stakeInfos[msg.sender].totalStaked = stakeInfos[msg.sender]
            .totalStaked
            .add(stakeAmount);
        totalMXSTStaked = totalMXSTStaked.add(stakeAmount);
        // it return previous claim and add next remainig days claim according to new APR

        emit Staked(_msgSender(), stakeAmount);
    }

    function withdrawMxst(uint256 _stakeId) external {
        require(!isBlacklisted[msg.sender], "Address Blacklisted!!!");
        uint256 counter = stakeInfos[msg.sender].count;
        require(_stakeId <= counter && _stakeId != 0, "Invalid Id");

        StakeInfo storage _info = stakeInfos[msg.sender].stakes[_stakeId];
        require(_info.endTS < block.timestamp, "Stake Time is not over yet");
        require(!_info.claimed, "Already claimed");

        _info.claimed = true;
        uint256 curStakedMxst = getLockedMXST(msg.sender);

        // Adjust APR if applicable
        uint256 _apr;
        if (curStakedMxst >= 50000e18 && curStakedMxst < 500000e18) {
            _apr = 75;
        } else if (curStakedMxst >= 500000e18 && curStakedMxst < 2500000e18) {
            _apr = 100;
        } else if (curStakedMxst >= 2500000e18 && curStakedMxst < 15000000e18) {
            _apr = 125;
        } else if (curStakedMxst >= 15000000e18) {
            _apr = 150;
        } else {
            _apr = 50;
        }

        if (ownedDeposits[msg.sender].length > 0) {
            // Function Called for Claiming
            (uint256 _curApr, ) = getCurrentTierUserFees(msg.sender);
            claim(msg.sender, _curApr);
            // update their apr
            updateAprbyMXST(msg.sender, _apr);
        }

        stakeInfos[msg.sender].totalStaked = stakeInfos[msg.sender]
            .totalStaked
            .sub(_info.amount);
        totalMXSTStaked = totalMXSTStaked.sub(_info.amount);

        IERC20Upgradeable(MXSTContract).transfer(_msgSender(), _info.amount);
        emit Claimed(_msgSender(), _info.amount);
    }

    function getMxstStakeDetail(address _user, uint256 _stakeId)
        external
        view
        returns (StakeInfo memory _info)
    {
        uint256 counter = stakeInfos[_user].count;
        require(_stakeId <= counter && _stakeId != 0, "Invalid Id");
        _info = stakeInfos[_user].stakes[_stakeId];
    }

    function updateAprbyMXST(address _user, uint256 _apr) internal {
        uint256 endTime;
        uint256 maxAmount;
        uint256 totalTime;
        uint256 allClaimableAmount;
        uint256[] memory userDeposits = ownedDeposits[_user];
        for (uint256 i = 0; i < userDeposits.length; i++) {
            DepositStruct storage _depState = depositState[userDeposits[i]];
            if (_depState.maxAmount != 0 && _depState.claimedAt != 0) {
                endTime = _depState.depositAt + withdrawPeriod;
                if (endTime > _depState.claimedAt) {
                    totalTime = endTime - _depState.claimedAt;
                    // calculate next remaing period with new APR
                    maxAmount = (totalTime * _depState.depositAmount * _apr)
                        .div(percentRate * rewardPeriod);
                    uint256 maxCurClaimable = _depState.claimedAmount +
                        maxAmount;
                    _depState.maxAmount = maxCurClaimable;
                    allClaimableAmount = allClaimableAmount.add(maxAmount);
                    if (_depState.claimedAmount > _depState.maxAmount) {
                        _depState.maxAmount = _depState.claimedAmount;
                    }
                }
            } else if (_depState.state) {
                endTime = _depState.depositAt + withdrawPeriod;
                if (endTime > investors[_user].lastCalculationDate) {
                    totalTime = endTime - investors[_user].lastCalculationDate;
                    // calculate next remaing period with new APR
                    maxAmount = (totalTime * _depState.depositAmount * _apr)
                        .div(percentRate * rewardPeriod);
                    allClaimableAmount = allClaimableAmount.add(maxAmount);
                }
            }
        }

        // Set max reward if available
        if (allClaimableAmount != 0) {
            investors[_user].maxClaimableAmount = investors[_user]
                .claimedAmount
                .add(allClaimableAmount);
        }
    }

    function setMXST(address _mxst) public onlyOwner {
        MXSTContract = _mxst;
    }

    // ENDING STAKING

    function getCurrentUserFees(address _user)
        public
        view
        returns (uint256 _apr, uint256 _devFee)
    {
        uint256 stakedAmnt = getLockedMXST(_user);
        if (stakedAmnt >= 50000e18 && stakedAmnt < 500000e18) {
            _apr = 75;
            _devFee = 300;
        } else if (stakedAmnt >= 500000e18 && stakedAmnt < 2500000e18) {
            _apr = 100;
            _devFee = 300;
        } else if (stakedAmnt >= 2500000e18 && stakedAmnt < 15000000e18) {
            _apr = 125;
            _devFee = 250;
        } else if (stakedAmnt >= 15000000e18) {
            _apr = 150;
            _devFee = 200;
        } else {
            _apr = 50;
            _devFee = 300;
        }

        if (isDevFeeDisabled) {
            _devFee = 0;
        }
    }

    function getActiveDeposit(address _investor)
        public
        view
        returns (uint256[] memory, uint256)
    {
        uint256 counter;
        uint256[] memory userDeposits = ownedDeposits[_investor];
        uint256[] memory _ids = new uint256[](userDeposits.length);
        for (uint256 i = 0; i < userDeposits.length; i++) {
            DepositStruct memory depState = depositState[userDeposits[i]];
            if (
                depState.state &&
                block.timestamp > depState.depositAt + withdrawPeriod
            ) {
                _ids[counter] = userDeposits[i];
                counter++;
            }
        }
        return (_ids, counter);
    }

    function redepositAllCapital() external checkForPause {
        require(!isBlacklisted[msg.sender], "Address Blacklisted!!!");
        (uint256[] memory activeDeposits, uint256 idsLen) = getActiveDeposit(
            msg.sender
        );
        require(idsLen != 0, "No deposit available");

        // Withdraw claimable reward
        (uint256 _apr, uint256 _devFee) = getCurrentUserFees(msg.sender);
        (uint256 _rApr, ) = getCurrentTierUserFees(msg.sender);
        uint256 prevLockedAmount;
        uint256 claimableReward;
        uint256[] memory userDeposits = ownedDeposits[msg.sender];
        for (uint256 i = 0; i < userDeposits.length; i++) {
            DepositStruct memory _depState = depositState[userDeposits[i]];
            if (_depState.maxAmount != 0 && _depState.claimedAt != 0) {
                uint256 _curReward = updateDepositState(
                    msg.sender,
                    userDeposits[i]
                );
                claimableReward = claimableReward.add(_curReward);
            } else if (_depState.state) {
                prevLockedAmount = prevLockedAmount.add(
                    _depState.depositAmount
                );
            }
        }
        uint256 lastRoiTime = block.timestamp -
            investors[msg.sender].lastCalculationDate;
        uint256 prevReward = (lastRoiTime * prevLockedAmount * _rApr).div(
            percentRate * rewardPeriod
        );
        claimableReward = claimableReward.add(prevReward);
        // check for if reward exceed max reward.
        if (
            investors[msg.sender].claimedAmount + claimableReward >
            investors[msg.sender].maxClaimableAmount
        ) {
            claimableReward = investors[msg.sender].maxClaimableAmount.sub(
                investors[msg.sender].claimedAmount
            );
        }
        require(claimableReward <= getBalance(), "no enough busd in pool");

        investors[msg.sender].claimedAmount = investors[msg.sender]
            .claimedAmount
            .add(claimableReward);
        investors[msg.sender].lastCalculationDate = block.timestamp;

        uint256 amountToSend;
        for (uint256 i; i < idsLen; i++) {
            DepositStruct memory depState = depositState[activeDeposits[i]];
            amountToSend = amountToSend.add(depState.depositAmount);

            depositState[activeDeposits[i]].state = false;
            investors[msg.sender].totalLocked = investors[msg.sender]
                .totalLocked
                .sub(depState.depositAmount);
        }

        // transfer reward to the user
        IERC20Upgradeable(BUSDContract).safeTransfer(
            msg.sender,
            claimableReward
        );
        if (stakeInfos[msg.sender].totalStaked >= 500000e18) {
            if (claimableReward > 0) {
                IERC20Upgradeable(MXSTContract).safeTransfer(
                    msg.sender,
                    claimableReward
                );
            }
        }
        totalReward = totalReward.add(claimableReward);

        // transfer capital to the user
        _deposit(amountToSend, _apr, _devFee);
    }

    function getLockedMXST(address _investor)
        public
        view
        returns (uint256 lockedAmount)
    {
        uint256 counter = stakeInfos[_investor].count;
        for (uint256 i = 1; i <= counter; i++) {
            StakeInfo memory _info = stakeInfos[msg.sender].stakes[i];
            if (block.timestamp < _info.endTS) {
                lockedAmount = lockedAmount.add(_info.amount);
            }
        }
    }

    function getCurrentTierUserFees(address _user)
        internal
        view
        returns (uint256 _apr, uint256 _devFee)
    {
        uint256 stakedAmnt = stakeInfos[_user].totalStaked;
        if (stakedAmnt >= 50000e18 && stakedAmnt < 500000e18) {
            _apr = 75;
            _devFee = 300;
        } else if (stakedAmnt >= 500000e18 && stakedAmnt < 2500000e18) {
            _apr = 100;
            _devFee = 300;
        } else if (stakedAmnt >= 2500000e18 && stakedAmnt < 15000000e18) {
            _apr = 125;
            _devFee = 250;
        } else if (stakedAmnt >= 15000000e18) {
            _apr = 150;
            _devFee = 200;
        } else {
            _apr = 50;
            _devFee = 300;
        }

        if (isDevFeeDisabled) {
            _devFee = 0;
        }
    }

    function updateUserStatus(address _user, bool _status) external onlyOwner {
        isBlacklisted[_user] = _status;
    }

    function updateFeeDisableStatus(bool _status) external onlyOwner {
        isDevFeeDisabled = _status;
    }

    function setPerDayPenalty(uint256 _penalty) external onlyOwner {
        perDayPenalty = _penalty;
    }

    function tempPause() external onlyOwner {
        paused = true;
    }

    function tempUnpause() external onlyOwner {
        paused = false;
    }

    function disableReward() external onlyOwner {
        isRewardDisabled = true;
    }

    function enableReward() external onlyOwner {
        isRewardDisabled = false;
    }

    function setRewards(bool _off, uint256 _from) external onlyOwner {
        isRewardDisabled = _off;
        rewardCalcFrom = _from;
    }

    function withdrawWhitelisted() external checkForPause {
        require(!isBlacklisted[msg.sender], "Address Blacklisted!!!");
        InitialClaimRecord memory _claimRecord = initialClaimRecords[
            msg.sender
        ];
        require(currentClaimCycle != 0, "Claim not initiated yet!");
        require(block.timestamp < cycleEndAt, "Time expired.");
        require(
            _claimRecord.lastClaimedCycle != currentClaimCycle,
            "Already claimed in current cycle."
        );
        // Get Locked and unlocked capital
        uint256 totalUnlocked;
        uint256 totalWithdrawn;
        uint256 totalDeposited;
        uint256[] memory userDeposits = ownedDeposits[msg.sender];
        require(userDeposits.length != 0, "Dont have any deposits");

        for (uint256 i = 0; i < userDeposits.length; i++) {
            DepositStruct memory depState = depositState[userDeposits[i]];
            if (
                depState.state &&
                block.timestamp > depState.depositAt + withdrawPeriod
            ) {
                totalUnlocked = totalUnlocked.add(depState.depositAmount);
                investors[msg.sender].totalLocked = investors[msg.sender]
                    .totalLocked
                    .sub(depState.depositAmount);
                depositState[userDeposits[i]].state = false;
            } else if (!depState.state) {
                totalWithdrawn = totalWithdrawn.add(depState.depositAmount);
            }
            totalDeposited = totalDeposited.add(depState.depositAmount);
        }

        uint256 claimableAmount = (
            totalDeposited.sub(
                investors[msg.sender].claimedAmount,
                "Already filled"
            )
        ).sub(totalWithdrawn, "Already filled");

        initialClaimRecords[msg.sender].totalDeposited = totalDeposited;
        initialClaimRecords[msg.sender].totalClaimable = claimableAmount;

        require(claimableAmount >= totalUnlocked, "Amount cannot be claimed");
        require(totalUnlocked <= getBalance(), "no enough busd in pool");
        IERC20Upgradeable(BUSDContract).safeTransfer(msg.sender, totalUnlocked);
    }

    function reInitialiseClaim(uint256 _duration) external onlyOwner {
        currentClaimCycle++;
        cycleEndAt = block.timestamp + _duration;
    }
}