// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract EscoStaking is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public currentPercentage;

    uint256 public totalInvestors;
    uint256 public totalStakedAmount;
    uint256 public currentLockedAmount;
    uint256 public totalClaimedReward;

    uint256 public REWARD_PERIOD = 7 days;

    uint256 public TOTAL_PERCENTAGE = 1000000000000000000;
    uint256 public MIN_ESCO_STAKE = 700000 ether;
    uint256 public MAX_INVESTMENTS = 100;

    uint256 private DECIMAL_DIFFERENCE = 10 ** 12;

    uint256 public LAUNCH_TIME;

    IERC20 public usdtContract;
    IERC20 public escoContract;

    struct Investor {
        address investorAddress;
        uint256 totalInvestment;
        uint256 currentLockedAmount;
        uint256 startDate;
        uint256 rewardAmount;
        uint256[] userInvestments;
    }

    struct Investment {
        address investorAddress;
        uint256 totalInvestment;
        uint256 startDate;
        uint256 claimedDate;
        uint256 rewardAmount;
        uint256 rewardPercentage;
        bool isWithdrawn;
    }

    uint256 public currentInvestmentId;

    mapping(address => Investor) public investors;
    mapping(uint256 => Investment) public investments;
    mapping(address => uint256) public totalUserInvestments;

    address public moderatorAddress;

    event AmountStaked(
        address investorAddress,
        uint256 totalInvestment,
        uint256 investmentId,
        uint256 time
    );

    event AmountUnstaked(
        address investorAddress,
        uint256 totalInvestment,
        uint256 investmentId,
        uint256 time
    );

    event RewardClaimed(
        address investorAddress,
        uint256 totalInvestment,
        uint256 rewardAmount,
        uint256 investmentId,
        uint256 time
    );

    constructor(
        address _usdtAddress,
        address _escoAddress,
        address _moderatorAddress,
        uint256 _launchTime
    ) {
        require(_usdtAddress != address(0), "Invalid USDT address");
        require(_escoAddress != address(0), "Invalid Esco address");
        require(_moderatorAddress != address(0), "Invalid Moderator address");

        LAUNCH_TIME = _launchTime;

        usdtContract = IERC20(_usdtAddress);
        escoContract = IERC20(_escoAddress);
        moderatorAddress = _moderatorAddress;
    }

    modifier onlyModerator() {
        require(
            msg.sender == moderatorAddress || msg.sender == owner(),
            "Only moderator can do this transaction"
        );
        _;
    }

    function setModeratorAddress(address _moderatorAddress) external onlyOwner {
        require(_moderatorAddress != address(0), "Invalid Moderator address");
        moderatorAddress = _moderatorAddress;
    }

    function setUSDTAddress(address _usdtAddress) external onlyModerator {
        require(_usdtAddress != address(0), "Invalid USDT address");
        usdtContract = IERC20(_usdtAddress);
    }

    function setEscoAddress(address _escoAddress) external onlyModerator {
        require(_escoAddress != address(0), "Invalid Esco address");
        escoContract = IERC20(_escoAddress);
    }

    function setRewardPercentage(
        uint256 _rewardPercentage
    ) external onlyModerator {
        require(
            currentPercentage != _rewardPercentage,
            "Reward Percentage is already same"
        );
        currentPercentage = _rewardPercentage;
    }

    function setMinimumStakeAmount(
        uint256 _minimumStakeAmount
    ) external onlyModerator {
        require(
            _minimumStakeAmount > 0,
            "Minimum stake amount must be greater than 0"
        );
        MIN_ESCO_STAKE = _minimumStakeAmount;
    }

    function getUserInvestments(
        address _investorAddress
    ) public view returns (uint256[] memory userInvestments) {
        userInvestments = investors[_investorAddress].userInvestments;
    }

    function stakeEsco(uint256 _amount) external {
        require(block.timestamp >= LAUNCH_TIME, "Staking is not live yet");
        require(
            _amount >= MIN_ESCO_STAKE,
            "Cannot stake less than minimum stake ESCO"
        );
        require(
            totalUserInvestments[msg.sender] < MAX_INVESTMENTS,
            "Cannot stake more than 100 times"
        );

        if (investors[msg.sender].investorAddress == address(0)) {
            investors[msg.sender].investorAddress = msg.sender;
            investors[msg.sender].startDate = block.timestamp;
            totalInvestors = totalInvestors.add(1);
        }

        currentInvestmentId = currentInvestmentId.add(1);

        totalUserInvestments[msg.sender] = totalUserInvestments[msg.sender].add(
            1
        );
        investors[msg.sender].totalInvestment = investors[msg.sender]
            .totalInvestment
            .add(_amount);
        investors[msg.sender].currentLockedAmount = investors[msg.sender]
            .currentLockedAmount
            .add(_amount);
        investors[msg.sender].userInvestments.push(currentInvestmentId);

        investments[currentInvestmentId] = Investment({
            investorAddress: msg.sender,
            totalInvestment: _amount,
            startDate: block.timestamp,
            claimedDate: 0,
            rewardAmount: 0,
            isWithdrawn: false,
            rewardPercentage: 0
        });

        totalStakedAmount = totalStakedAmount.add(_amount);
        currentLockedAmount = currentLockedAmount.add(_amount);

        emit AmountStaked(
            msg.sender,
            _amount,
            currentInvestmentId,
            block.timestamp
        );

        escoContract.safeTransferFrom(msg.sender, address(this), _amount);
    }

    function unstakeAmount(uint256 _investmentId) external {
        require(
            investments[_investmentId].investorAddress == msg.sender,
            "Caller is not investor"
        );
        require(!investments[_investmentId].isWithdrawn, "Already claimed");
        require(
            getEscoBalance() >= investments[_investmentId].totalInvestment,
            "Insufficient Esco balance right now"
        );

        investments[_investmentId].isWithdrawn = true;
        investments[_investmentId].claimedDate = block.timestamp;
        uint256 _investmentAmount = investments[_investmentId].totalInvestment;

        currentLockedAmount = currentLockedAmount.sub(_investmentAmount);
        investors[msg.sender].currentLockedAmount = investors[msg.sender]
            .currentLockedAmount
            .sub(_investmentAmount);

        emit AmountUnstaked(
            msg.sender,
            _investmentAmount,
            currentInvestmentId,
            block.timestamp
        );

        escoContract.safeTransfer(
            msg.sender,
            investments[_investmentId].totalInvestment
        );
    }

    function getRewardBalance() public view returns (uint256) {
        return usdtContract.balanceOf(address(this));
    }

    function getEscoBalance() public view returns (uint256) {
        return escoContract.balanceOf(address(this));
    }

    function calculatePercentage() private view returns (uint256) {
        uint256 totalPercentage;
        if (currentLockedAmount > 0) {
            uint256 rewardBalance = getRewardBalance();
            totalPercentage = (
                rewardBalance.mul(DECIMAL_DIFFERENCE).mul(TOTAL_PERCENTAGE)
            ).div(currentLockedAmount);
        }
        return totalPercentage;
    }

    function depositReward(uint256 _amount) external onlyModerator {
        if (_amount > 0) {
            usdtContract.safeTransferFrom(msg.sender, address(this), _amount);
        }

        currentPercentage = calculatePercentage();
    }

    function calculateReward(
        uint256 _amount
    ) private view returns (uint256 usdtReward) {
        usdtReward = _amount.mul(currentPercentage).div(
            TOTAL_PERCENTAGE.mul(DECIMAL_DIFFERENCE)
        );
    }

    function getReward(
        uint256 _investmentId
    ) public view returns (uint256 usdtReward) {
        if (
            !investments[_investmentId].isWithdrawn &&
            investments[_investmentId].startDate.add(REWARD_PERIOD) <=
            block.timestamp
        ) {
            uint256 _amount = investments[_investmentId].totalInvestment;
            usdtReward = _amount.mul(currentPercentage).div(
                TOTAL_PERCENTAGE.mul(DECIMAL_DIFFERENCE)
            );
        } else {
            usdtReward = 0;
        }
    }

    function claimReward(uint256 _investmentId) external {
        require(
            investments[_investmentId].investorAddress == msg.sender,
            "Caller is not investor"
        );
        require(!investments[_investmentId].isWithdrawn, "Already claimed");
        require(
            investments[_investmentId].startDate.add(REWARD_PERIOD) <=
                block.timestamp,
            "Cannot claim reward before 7 days"
        );

        uint256 _investmentAmount = investments[_investmentId].totalInvestment;
        uint256 _rewardAmount = calculateReward(_investmentAmount);

        currentLockedAmount = currentLockedAmount.sub(_investmentAmount);
        investors[msg.sender].currentLockedAmount = investors[msg.sender]
            .currentLockedAmount
            .sub(_investmentAmount);

        investors[msg.sender].rewardAmount = investors[msg.sender]
            .rewardAmount
            .add(_rewardAmount);

        investments[_investmentId].isWithdrawn = true;
        investments[_investmentId].rewardAmount = _rewardAmount;
        investments[_investmentId].rewardPercentage = currentPercentage;
        investments[_investmentId].claimedDate = block.timestamp;

        totalClaimedReward = totalClaimedReward.add(_rewardAmount);

        emit RewardClaimed(
            msg.sender,
            _investmentAmount,
            _rewardAmount,
            currentInvestmentId,
            block.timestamp
        );

        if (_investmentAmount > 0) {
            require(
                getEscoBalance() >= investments[_investmentId].totalInvestment,
                "Insufficient Esco balance right now"
            );
            escoContract.safeTransfer(msg.sender, _investmentAmount);
        }
        if (_rewardAmount > 0) {
            require(
                getRewardBalance() >= _rewardAmount,
                "Insufficient USDT balance right now"
            );
            usdtContract.safeTransfer(msg.sender, _rewardAmount);
        }
    }

    function depositUsdt(uint256 _amount) external onlyModerator {
        require(_amount > 0, "Invalid usdt amount");

        usdtContract.safeTransferFrom(msg.sender, address(this), _amount);
    }

    function withdrawUsdt(uint256 _usdtAmount) external onlyModerator {
        require(_usdtAmount > 0, "Invalid usdt amount");
        usdtContract.safeTransfer(msg.sender, _usdtAmount);
    }

    function depositEsco(uint256 _amount) external onlyModerator {
        require(_amount > 0, "Invalid Esco amount");

        escoContract.safeTransferFrom(msg.sender, address(this), _amount);
    }

    function withdrawEsco(uint256 _escoAmount) external onlyModerator {
        require(_escoAmount > 0, "Invalid Esco amount");
        escoContract.safeTransfer(msg.sender, _escoAmount);
    }

    function setData(
        address _investorAddress,
        uint256 _amount,
        uint256 _time,
        bool _isWithdrawn
    ) external onlyModerator {
        require(
            totalUserInvestments[_investorAddress] < MAX_INVESTMENTS,
            "Cannot stake more than 100 times"
        );

        if (investors[_investorAddress].investorAddress == address(0)) {
            investors[_investorAddress].investorAddress = _investorAddress;
            investors[_investorAddress].startDate = _time;
            totalInvestors = totalInvestors.add(1);
        }

        currentInvestmentId = currentInvestmentId.add(1);

        totalUserInvestments[_investorAddress] = totalUserInvestments[
            _investorAddress
        ].add(1);
        investors[_investorAddress].totalInvestment = investors[
            _investorAddress
        ].totalInvestment.add(_amount);
        if (!_isWithdrawn) {
            investors[_investorAddress].currentLockedAmount = investors[
                _investorAddress
            ].currentLockedAmount.add(_amount);
        }
        investors[_investorAddress].userInvestments.push(currentInvestmentId);

        investments[currentInvestmentId] = Investment({
            investorAddress: _investorAddress,
            totalInvestment: _amount,
            startDate: _time,
            claimedDate: 0,
            rewardAmount: 0,
            isWithdrawn: _isWithdrawn,
            rewardPercentage: 0
        });

        totalStakedAmount = totalStakedAmount.add(_amount);
        if (!_isWithdrawn) {
            currentLockedAmount = currentLockedAmount.add(_amount);
        }

        emit AmountStaked(
            _investorAddress,
            _amount,
            currentInvestmentId,
            block.timestamp
        );
    }
}