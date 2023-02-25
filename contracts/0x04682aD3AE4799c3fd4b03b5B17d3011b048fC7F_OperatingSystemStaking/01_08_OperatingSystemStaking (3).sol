//SPDX-License-Identifier: Unlicense
pragma solidity = 0.8.9;

import "contracts/access/OracleManaged.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Operating System staking
contract OperatingSystemStaking is OracleManaged {

    using SafeERC20 for IERC20;

    IERC20 public immutable operatingSystem;
    IERC20 public immutable usdt;
    address private constant STAKING_FUND = 0x0a5a1209E93E03a9C341287bf4179944f23C9E5D;
    address private constant OPERATING_SYSTEM = 0x21FfE03cAA6355CF1ca47B898921d2f70e85e423;
    address private constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    // @dev this is used to allow for decimals in the currentRewardValue as well as to convert USDT amount to 18 decimals
    uint private constant REWARD_FACTOR_ACCURACY = 1_000_000_000_000 ether;
    uint private constant BASE_DISTRIBUTION_AMOUNT = 10 ** 6;
    uint private constant MINIMUM_STAKE = 1 ether;
    uint public minimumDistribution = BASE_DISTRIBUTION_AMOUNT;
    uint public allTimeStakedAtDistribution;
    uint public allTimeRewards;
    uint public allTimeRewardsClaimed;
    uint public totalStaked;
    uint public currentRewardFactor;
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
    event Deposit(address user, uint amount);
    event Withdraw(address user, uint amount);
    event Claimed(address user, uint rewards);
    event Distributed(uint rewards, uint totalStaked);

    /// @param _oracle Oracle address
    constructor(address _oracle) {
        _setOracle(_oracle);
        operatingSystem = IERC20(OPERATING_SYSTEM);
        usdt = IERC20(USDT);
    }

    /// @notice Enable depositing
    function enableDepositing() external onlyOwner {
        require(!isDepositingEnabled, "OperatingSystemStaking: Depositing is already enabled");
        isDepositingEnabled = true;
        emit DepositingEnabled();
    }

    /// @notice Disable depositing
    function disableDepositing() external onlyOwner {
        require(isDepositingEnabled, "OperatingSystemStaking: Depositing is already disabled");
        isDepositingEnabled = false;
        emit DepositingDisabled();
    }

    /// @notice Set the minimum distribution amount
    /// @param _minimumDistribution Minimum distribution amount
    function setMinimumDistribution(uint _minimumDistribution) external onlyOwner {
        require(_minimumDistribution >= BASE_DISTRIBUTION_AMOUNT, "OperatingSystemStaking: _minimumDistribution must be greater than the base");
        minimumDistribution = _minimumDistribution;
        emit MinimumDistributionUpdated(_minimumDistribution);
    }

    /// @notice Deposit Operating System
    /// @param _amount OS amount
    function deposit(uint _amount) external {
        require(isDepositingEnabled, "OperatingSystemStaking: Depositing is not allowed at this time");
        require(_amount >= MINIMUM_STAKE, "OperatingSystemStaking: Amount must be greater than 1 OS");
        /// @dev merge rewards prior to updating their staked balance because their rewards are dependant on their stake
        _mergeRewards();
        _users[_msgSender()].staked += _amount;
        totalStaked += _amount;
        operatingSystem.safeTransferFrom(_msgSender(), address(this), _amount);
        emit Deposit(_msgSender(), _amount);
    }

    /// @notice Withdraw Operating System
    /// @param _amount OS amount
    function withdraw(uint _amount) external {
        User storage user = _users[_msgSender()];
        require(_amount > 0, "OperatingSystemStaking: Amount to withdraw must be greater than zero");
        require(_amount <= user.staked, "OperatingSystemStaking: Amount exceeds staked");
        /// @dev merge rewards prior to updating their staked balance because their rewards are dependant on their stake
        _mergeRewards();
        _users[_msgSender()].staked -= _amount;
        totalStaked -= _amount;
        operatingSystem.safeTransfer(_msgSender(), _amount);
        emit Withdraw(_msgSender(), _amount);
    }

    /// @notice Claim rewards
    function claimRewards() external {
        _mergeRewards();
        uint heldRewards = _users[_msgSender()].heldRewards;
        require(heldRewards > 0, "OperatingSystemStaking: No rewards available to claim");
        _users[_msgSender()].heldRewards = 0;
        allTimeRewardsClaimed += heldRewards;
        usdt.safeTransfer(_msgSender(), heldRewards);
        emit Claimed(_msgSender(), heldRewards);
    }

    /// @notice Distribute USDT (from the fund wallet) to staked users
    function distribute() external onlyOwnerOrOracle {
        require(totalStaked >= MINIMUM_STAKE, "OperatingSystemStaking: Total staked must be greater than 1 OS");
        uint amount = usdt.balanceOf(STAKING_FUND);
        require(amount >= minimumDistribution, "OperatingSystemStaking: Insufficient amount");
        require(usdt.allowance(STAKING_FUND, address(this)) >= amount, "OperatingSystemStaking: Insufficient allowance");
        allTimeStakedAtDistribution += totalStaked;
        allTimeRewards += amount;
        currentRewardFactor += REWARD_FACTOR_ACCURACY * amount / totalStaked;
        usdt.safeTransferFrom(STAKING_FUND, address(this), amount);
        emit Distributed(amount, totalStaked);
    }

    /// @notice Get the staked balance for a user
    /// @param _user User address
    /// @return uint Staked balance
    function getStake(address _user) external view returns (uint) {
        return _users[_user].staked;
    }

    /// @notice Get the current rewards for a user
    /// @param _user User address
    /// @return uint Current rewards for _user
    function getReward(address _user) external view returns (uint) {
        return _getHeldRewards(_user) + _getCalculatedRewards(_user);
    }

    /// @param _user User address
    /// @return uint Held rewards
    function _getHeldRewards(address _user) private view returns (uint) {
        return _users[_user].heldRewards;
    }

    /// @param _user User address
    /// @return uint Calculated rewards
    function _getCalculatedRewards(address _user) private view returns (uint) {
        uint balance = _users[_user].staked;
        return balance * (currentRewardFactor - _users[_user].rewardFactor) / REWARD_FACTOR_ACCURACY;
    }

    /// @dev Merge held rewards with calculated rewards
    function _mergeRewards() private {
        _holdCalculatedRewards();
        _users[_msgSender()].rewardFactor = currentRewardFactor;
    }

    /// @dev Convert calculated rewards into held rewards
    /// @dev Used when the user carries out an action that would cause their calculated rewards to change unexpectedly
    function _holdCalculatedRewards() private {
        uint calculatedReward = _getCalculatedRewards(_msgSender());
        if (calculatedReward > 0) {
            _users[_msgSender()].heldRewards += calculatedReward;
        }
    }
}