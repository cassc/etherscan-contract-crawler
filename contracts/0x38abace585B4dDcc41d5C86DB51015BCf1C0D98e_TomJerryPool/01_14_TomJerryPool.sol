/*

88888888888                           .d8888b.            888888                                   
    888                              d88P  "88b             "88b                                   
    888                              Y88b. d88P              888                                   
    888   .d88b.  88888b.d88b.        "Y8888P"               888  .d88b.  888d888 888d888 888  888 
    888  d88""88b 888 "888 "88b      .d88P88K.d88P           888 d8P  Y8b 888P"   888P"   888  888 
    888  888  888 888  888  888      888"  Y888P"            888 88888888 888     888     888  888 
    888  Y88..88P 888  888  888      Y88b .d8888b            88P Y8b.     888     888     Y88b 888 
    888   "Y88P"  888  888  888       "Y8888P" Y88b          888  "Y8888  888     888      "Y88888 
                                                           .d88P                               888 
                                                         .d88P"                           Y8b d88P 
                                                        888P"                              "Y88P"  

Website: https://tomjerryeth.com
Telegram: https://t.me/TomJerryETH
Twitter: https://twitter.com/TomJerryETH

*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract TomJerryPool is AccessControl {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");

    IERC20 public immutable poolToken;
    IERC20 public immutable usdt;

    address private immutable admin;
    address private immutable rewardFund;

    uint private constant REWARD_FACTOR_ACCURACY = 1_000_000_000_000 ether;
    uint private constant BASE_DISTRIBUTION_AMOUNT = 10 ** 6;
    uint private constant PERCENTAGE_DENOMINATOR = 10 ** 3;
    uint private constant MINIMUM_STAKE = 1 ether;

    uint public minimumDistribution = BASE_DISTRIBUTION_AMOUNT;
    uint public allTimeStakedAtDistribution;
    uint public allTimeRewards;
    uint public allTimeRewardsClaimed;
    uint public totalStaked;
    uint public currentRewardFactor;
    uint public rewardFundPercentage = 100;
    bool public isDepositingEnabled;

    struct User {
        uint rewardFactor;
        uint heldRewards;
        uint staked;
    }

    mapping(address => User) private _users;

    event DepositingEnabled();
    event DepositingDisabled();
    event MinimumDistributionUpdated(uint minimumDistribution);
    event RewardFundPercentageUpdated(uint rewardFundPercentage);
    event Deposit(address user, uint amount);
    event Withdraw(address user, uint amount);
    event Claimed(address user, uint rewards);
    event Distributed(uint rewards, uint totalStaked);

    constructor(
        address _poolToken,
        address _usdt,
        address _rewardFund
    ) {
        poolToken = IERC20(_poolToken);
        usdt = IERC20(_usdt);

        admin = _msgSender();
        rewardFund = _rewardFund;

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MANAGER_ROLE, admin);
        _grantRole(ORACLE_ROLE, admin);
    }

    /** PUBLIC FUNCTIONS */

    function deposit(uint _amount) external {
        require(isDepositingEnabled, "Depositing is not allowed at this time");
        require(_amount >= MINIMUM_STAKE, "Amount must be greater than minimum");
        _mergeRewards(_msgSender());
        _users[_msgSender()].staked += _amount;
        totalStaked += _amount;
        poolToken.safeTransferFrom(_msgSender(), address(this), _amount);
        emit Deposit(_msgSender(), _amount);
    }

    function withdraw(uint _amount) external {
        User storage user = _users[_msgSender()];
        require(_amount > 0, "Amount to withdraw must be greater than zero");
        require(_amount <= user.staked, "Amount exceeds staked");
        _mergeRewards(_msgSender());
        _users[_msgSender()].staked -= _amount;
        totalStaked -= _amount;
        poolToken.safeTransfer(_msgSender(), _amount);
        emit Withdraw(_msgSender(), _amount);
    }

    function claim(address _account) external onlyRole(MANAGER_ROLE) {
        _mergeRewards(_account);
        uint heldRewards = _users[_account].heldRewards;
        if (heldRewards > 0) {
            _users[_account].heldRewards = 0;
            allTimeRewardsClaimed += heldRewards;
            usdt.safeTransfer(_account, heldRewards);
            emit Claimed(_account, heldRewards);
        }
    }

    /** VIEW FUNCTIONS */

    function getStake(address _user) external view returns (uint) {
        return _users[_user].staked;
    }

    function getReward(address _user) external view returns (uint) {
        return _getHeldRewards(_user) + _getCalculatedRewards(_user);
    }

    function _getHeldRewards(address _user) private view returns (uint) {
        return _users[_user].heldRewards;
    }

    function _getCalculatedRewards(address _user) private view returns (uint) {
        uint balance = _users[_user].staked;
        return balance * (currentRewardFactor - _users[_user].rewardFactor) / REWARD_FACTOR_ACCURACY;
    }

    function _mergeRewards(address _account) private {
        _holdCalculatedRewards(_account);
        _users[_account].rewardFactor = currentRewardFactor;
    }

    function _holdCalculatedRewards(address _account) private {
        uint calculatedReward = _getCalculatedRewards(_account);
        if (calculatedReward > 0) {
            _users[_account].heldRewards += calculatedReward;
        }
    }

    /** RESTRICTED FUNCTIONS */

    function enableDepositing() external onlyRole(MANAGER_ROLE) {
        require(!isDepositingEnabled, "Depositing is already enabled");
        isDepositingEnabled = true;
        emit DepositingEnabled();
    }

    function disableDepositing() external onlyRole(MANAGER_ROLE) {
        require(isDepositingEnabled, "Depositing is already disabled");
        isDepositingEnabled = false;
        emit DepositingDisabled();
    }

    function setMinimumDistribution(uint _minimumDistribution) external onlyRole(MANAGER_ROLE) {
        require(_minimumDistribution >= BASE_DISTRIBUTION_AMOUNT, "_minimumDistribution must be greater than the base");
        minimumDistribution = _minimumDistribution;
        emit MinimumDistributionUpdated(_minimumDistribution);
    }

    function setRewardFundPercentage(uint _rewardFundPercentage) external onlyRole(MANAGER_ROLE) {
        require(_rewardFundPercentage > 0, "_rewardFundPercentage must be greater than zero");
        rewardFundPercentage = _rewardFundPercentage;
        emit RewardFundPercentageUpdated(_rewardFundPercentage);
    }

    /** ORACLE FUNCTIONS */

    function distribute() external onlyRole(ORACLE_ROLE) {
        require(totalStaked >= MINIMUM_STAKE, "Total staked must be greater than minimum");
        uint amount = usdt.balanceOf(rewardFund) * rewardFundPercentage / PERCENTAGE_DENOMINATOR;
        require(amount >= minimumDistribution, "Insufficient amount");
        require(usdt.allowance(rewardFund, address(this)) >= amount, "Insufficient allowance");
        allTimeStakedAtDistribution += totalStaked;
        allTimeRewards += amount;
        currentRewardFactor += REWARD_FACTOR_ACCURACY * amount / totalStaked;
        usdt.safeTransferFrom(rewardFund, address(this), amount);
        emit Distributed(amount, totalStaked);
    }
}