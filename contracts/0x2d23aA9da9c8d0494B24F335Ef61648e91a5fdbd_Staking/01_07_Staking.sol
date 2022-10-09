pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IMintableERC20.sol";
import "./Initializable.sol";

contract Staking is Ownable, ReentrancyGuard, Initializable {

    event Deposited(
        address indexed sender,
        address indexed owner,
        uint256 amount
    );

    event DepositedPresale(
        address indexed owner,
        uint256 ethSupplied
    );

    event Withdrawal(
        address indexed sender,
        uint256 amount
    );

    event RewardReceived(
        address indexed owner,
        uint256 rewardAmount
    );

    struct Deposit {
        bool isPresaled;
        uint256 startTime;
        uint256 deposited;
        uint256 rewardTaken;
    }

    struct PresaleDeposit {
        uint256 startTime;
        uint128 ethDeposited;
        uint128 rewardTaken;
    }

    modifier onlyPresale() {
        require(msg.sender == presale, "Not Presale");
        _;
    }

    uint256 public constant BASIS_POINTS = 10000;
    uint256 public constant BASIS_POINTS_USDT = 1e18 * 10000;
    uint256 public constant REWARD_PERCENTAGE = 28;
    uint256 public constant REWARD_PERCENTAGE_USDT = 6 * 1e18;
    uint256 public publicStakeStartTime;

    address public presale;
    IMintableERC20 public token;
    IERC20 public usdt;

    mapping(address => mapping(uint256 => Deposit)) public userInfos;
    mapping(address => uint256) public userInfosLength;

    mapping(address => mapping(uint256 => PresaleDeposit)) public userInfosPresale;
    mapping(address => uint256) public userInfosPresaleLength;

    constructor() {

    }

    function init(address _presale, address _token, address _usdt) external onlyOwner {
        presale = _presale;
        token = IMintableERC20(_token);
        usdt = IERC20(_usdt);
    }

    function stakePresale(address _to, uint256 _amount, uint256 _ethDeposited) external onlyPresale {
        uint256 nextDepositId = userInfosLength[_to];
        Deposit memory freshDeposit = Deposit(
            true,
            block.timestamp,
            _amount,
            0
        );

        userInfos[_to][nextDepositId] = freshDeposit;
        userInfosLength[_to]++;

        PresaleDeposit memory freshPresaleDeposit = PresaleDeposit(
            block.timestamp,
            uint128(_ethDeposited),
            0
        );

        userInfosPresale[_to][nextDepositId] = freshPresaleDeposit;
        userInfosPresaleLength[_to]++;

        emit Deposited(
            msg.sender,
            _to,
            _amount
        );

        emit DepositedPresale(
            msg.sender,
            _ethDeposited
        );
    }

    function stake(uint256 _amount) external {
        token.transferFrom(msg.sender, address(this), _amount);

        Deposit memory freshDeposit = Deposit(
            false,
            block.timestamp,
            _amount,
            0
        );

        userInfos[msg.sender][userInfosLength[msg.sender]] = freshDeposit;
        userInfosLength[msg.sender]++;

        emit Deposited(
            msg.sender,
            msg.sender,
            _amount
        );
    }

    function receiveRewards() external nonReentrant {
        uint256 rewardAmount = 0;

        uint256 userDepositsLength = userInfosLength[msg.sender];

        for(uint256 i = 0; i < userDepositsLength; i++) {
            Deposit memory deposit = userInfos[msg.sender][i];
            uint256 daysSinceStart = (block.timestamp - deposit.startTime) / 86400;
            uint8 rewardMultiplier = deposit.isPresaled ? 2 : 1;
            uint256 availableReward = ((deposit.deposited * REWARD_PERCENTAGE * rewardMultiplier * daysSinceStart) / BASIS_POINTS) - deposit.rewardTaken;

            userInfos[msg.sender][i].rewardTaken += availableReward;

            rewardAmount += availableReward;
            emit RewardReceived(msg.sender, availableReward);
        }

        token.mint(msg.sender, rewardAmount);

        emit RewardReceived(
            msg.sender,
            rewardAmount
        );
    }

    function receiveRewardsUsdt() external {
        uint256 rewardAmount = 0;

        uint256 userDepositsLength = userInfosPresaleLength[msg.sender];

        for(uint256 i = 0; i < userDepositsLength; i++) {
            PresaleDeposit memory deposit = userInfosPresale[msg.sender][i];
            uint256 daysSinceStart = (block.timestamp - deposit.startTime) / 86400;
            uint256 availableReward = ((deposit.ethDeposited * REWARD_PERCENTAGE_USDT * daysSinceStart) / BASIS_POINTS_USDT) - deposit.rewardTaken;

            userInfosPresale[msg.sender][i].rewardTaken += uint128(availableReward);

            rewardAmount += availableReward;
        }

        usdt.transfer(msg.sender, rewardAmount);
    }

    function receiveReward(uint256 _depositIndex) external nonReentrant {
        require(_depositIndex <= userInfosLength[msg.sender], "Too high index");

        Deposit memory deposit = userInfos[msg.sender][_depositIndex];
        uint256 daysSinceStart = (block.timestamp - deposit.startTime) / 86400;
        uint8 rewardMultiplier = deposit.isPresaled ? 2 : 1;
        uint256 availableReward = ((deposit.deposited * REWARD_PERCENTAGE * rewardMultiplier * daysSinceStart) / BASIS_POINTS) - deposit.rewardTaken;
        userInfos[msg.sender][_depositIndex].rewardTaken += availableReward;

        token.mint(msg.sender, availableReward);

        emit RewardReceived(msg.sender, availableReward);
    }

    function withdraw(uint256 _depositIndex) external nonReentrant {
        Deposit memory deposit = userInfos[msg.sender][_depositIndex];

        uint8 rewardMultiplier = deposit.isPresaled ? 2 : 1;
        uint256 daysSinceStart = (block.timestamp - deposit.startTime) / 86400;

        uint256 rewardsAvailable = ((deposit.deposited * REWARD_PERCENTAGE * rewardMultiplier * daysSinceStart) / BASIS_POINTS) - deposit.rewardTaken;

        token.mint(address(this), rewardsAvailable);
        token.transfer(msg.sender, deposit.deposited + rewardsAvailable);

        userInfos[msg.sender][_depositIndex].deposited = 0;
        userInfos[msg.sender][_depositIndex].rewardTaken += rewardsAvailable;

        if(_depositIndex < userInfosPresaleLength[msg.sender]) {
            PresaleDeposit memory deposit2 = userInfosPresale[msg.sender][_depositIndex];
            uint256 daysSinceStart2 = (block.timestamp - deposit.startTime) / 86400;
            uint256 availableReward = ((deposit2.ethDeposited * REWARD_PERCENTAGE_USDT * daysSinceStart2) / BASIS_POINTS_USDT) - deposit2.rewardTaken;

            userInfosPresale[msg.sender][_depositIndex].rewardTaken += uint128(availableReward);
            userInfosPresale[msg.sender][_depositIndex].ethDeposited = 0;

            usdt.transfer(msg.sender, availableReward);
        }

        emit Withdrawal(msg.sender, deposit.deposited);
    }

    function getAllDeposits(address _to) external view returns(Deposit[] memory) {
        uint256 depositsLength = userInfosLength[_to];
        Deposit[] memory result = new Deposit[](depositsLength);

        for(uint256 i = 0; i < depositsLength; i++) {
            result[i] = userInfos[_to][i];
        }

        return result;
    }

    function getAvailableRewards(address _to) external view returns(uint256[] memory) {
        uint256 userRewardsLength = userInfosLength[_to];

        uint256[] memory result = new uint256[](userRewardsLength);

        for(uint256 i = 0; i < userRewardsLength; i++) {
            Deposit memory deposit = userInfos[_to][i];
            uint256 daysSinceStart = (block.timestamp - deposit.startTime) / 86400;

            uint8 rewardMultiplier = deposit.isPresaled ? 2 : 1;
            result[i] = (deposit.deposited * REWARD_PERCENTAGE * daysSinceStart * rewardMultiplier) / BASIS_POINTS - deposit.rewardTaken;
        }

        return result;
    }

    function getAvailableRewardsUsdt(address _to) external view returns(uint256) {
        uint256 rewardAmount = 0;

        uint256 userDepositsLength = userInfosPresaleLength[_to];

        for(uint256 i = 0; i < userDepositsLength; i++) {
            PresaleDeposit memory deposit = userInfosPresale[_to][i];
            uint256 daysSinceStart = (block.timestamp - deposit.startTime) / 86400;
            uint256 availableReward = ((deposit.ethDeposited * REWARD_PERCENTAGE_USDT * daysSinceStart) / BASIS_POINTS_USDT) - deposit.rewardTaken;

            rewardAmount += availableReward;
        }

        return rewardAmount;
    }

    function addUSDTSupply(uint256 _amount) external {
        usdt.transferFrom(msg.sender, address(this), _amount);
    }
}