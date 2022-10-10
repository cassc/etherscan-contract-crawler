// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./utils/WithdrawableUpgradeable.sol";
import "./interfaces/INFTSales.sol";
import "hardhat/console.sol";

contract PhoenixBadgeStaking is
    Initializable,
    OwnableUpgradeable,
    WithdrawableUpgradeable
{
    struct UserInfo {
        uint256 stakedAmount; // how many Staking Tokens the user has provided.
        uint256 lockPeriodEnd; // when locking period ends for user
    }

    bool public stakingEnabled;

    address public phoenixNFTContract; // NFT contract for phoenix. Used to mint badge nfts
    address public stakingToken; // Staking ERC20 token
    address public treasuryAddress;

    uint32 public badgeNFTType; // nft type for reward badge for this staking

    uint256 public stakeLockPeriod; // Period to lock stake; 0 for no lock;
    uint256 public stakingIncrement; // staking amount required per badge
    uint256 public totalStaked; // total amount staked in contract

    mapping(address => UserInfo) public userInfos; // User stake

    event Claim(address indexed user, uint256 indexed pending);
    event EmergencyWithdraw(address indexed user, uint256 indexed nativeAmount);
    event Stake(address indexed user, uint256 indexed nativeAmount);
    event Withdraw(address indexed user, uint256 indexed nativeAmount);

    error AmountMustBeIncrementOfStakingIncrement();
    error AddressIsZero();
    error NoStake();
    error StakeLocked();
    error StakingDisabled();
    error StakingStarted();

    modifier notZeroAddress(address _address) {
        if (_address == address(0)) revert AddressIsZero();
        _;
    }

    modifier stakingNotStarted() {
        if (totalStaked > 0) revert StakingStarted();
        _;
    }

    function initialize(
        address _stakingToken,
        address _treasuryAddress,
        address _phoenixNFTContract,
        uint32 _badgeNFTType,
        uint256 _stakeLockPeriod,
        uint256 _stakingIncrement
    )
        public
        notZeroAddress(_stakingToken)
        notZeroAddress(_treasuryAddress)
        notZeroAddress(_phoenixNFTContract)
        initializer
    {
        OwnableUpgradeable.__Ownable_init();
        stakingToken = _stakingToken;
        treasuryAddress = _treasuryAddress;
        phoenixNFTContract = _phoenixNFTContract;
        badgeNFTType = _badgeNFTType;
        stakeLockPeriod = _stakeLockPeriod;
        stakingIncrement = _stakingIncrement;
    }

    function emergencyWithdrawByAdmin(address _user) external onlyOwner {
        UserInfo storage user = userInfos[_user];
        uint256 amount = user.stakedAmount;
        if (amount == 0) revert NoStake();
        user.stakedAmount = 0;
        totalStaked -= amount;

        IERC20Upgradeable(stakingToken).transfer(address(_user), amount);
        emit EmergencyWithdraw(_user, amount);
    }

    function getPending(address _user) external view returns (uint256) {
        UserInfo memory user = userInfos[_user];
        return user.stakedAmount / stakingIncrement;
    }

    function setPhoenixNFTContract(address value)
        external
        onlyOwner
        notZeroAddress(value)
        stakingNotStarted
    {
        phoenixNFTContract = value;
    }

    function setStakeLockPeriod(uint256 value) external onlyOwner {
        stakeLockPeriod = value;
    }

    function setStakingEnabled(bool enabled) external onlyOwner {
        stakingEnabled = enabled;
    }

    function setStakingIncrement(uint256 value)
        external
        onlyOwner
        stakingNotStarted
    {
        stakingIncrement = value;
    }

    function setTreasuryAddress(address addr) external onlyOwner {
        treasuryAddress = addr;
    }

    function stake(uint256 amount) external payable {
        if (!stakingEnabled) revert StakingDisabled();
        if (amount % stakingIncrement > 0)
            revert AmountMustBeIncrementOfStakingIncrement();

        IERC20Upgradeable(stakingToken).transferFrom(
            address(_msgSender()),
            address(this),
            amount
        );

        UserInfo storage user = userInfos[_msgSender()];
        user.stakedAmount += amount;
        user.lockPeriodEnd = block.timestamp + stakeLockPeriod;
        totalStaked += amount;

        emit Stake(_msgSender(), amount);
    }

    function withdraw() external {
        UserInfo storage user = userInfos[_msgSender()];
        uint256 amount = user.stakedAmount;
        if (amount == 0) revert NoStake();
        if (block.timestamp < user.lockPeriodEnd) revert StakeLocked();

        claim();
        user.stakedAmount = 0;
        user.lockPeriodEnd = 0;
        totalStaked -= amount;

        IERC20Upgradeable(stakingToken).transfer(address(_msgSender()), amount);

        emit Withdraw(_msgSender(), amount);
    }

    function claim() public {
        UserInfo storage user = userInfos[_msgSender()];
        uint256 amount = user.stakedAmount;
        if (amount == 0) revert NoStake();
        if (block.timestamp < user.lockPeriodEnd) revert StakeLocked();

        uint256 pending = amount / stakingIncrement;
        if (pending > 0) {
            // reset timelock for user
            user.lockPeriodEnd = block.timestamp + stakeLockPeriod;
            // mint the badges to the user
            uint32[] memory badgeArray = new uint32[](pending);
            for (uint32 x; x < pending; x++) {
                badgeArray[x] = badgeNFTType;
            }
            INFTSales(phoenixNFTContract).batchMint(msg.sender, badgeArray);
        }
        emit Claim(_msgSender(), pending);
    }
}