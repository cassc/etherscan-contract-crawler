// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "./utils/WithdrawableUpgradeable.sol";
import "./interfaces/INFTSales.sol";
import "hardhat/console.sol";

contract PhoenixTraining is
    Initializable,
    OwnableUpgradeable,
    ERC721HolderUpgradeable,
    WithdrawableUpgradeable
{
    struct UserInfo {
        uint256 stakedAmount; // how many Staking Tokens the user has provided.
        uint256[] phoenixIDs;
        uint256 lockPeriodEnd; // when locking period ends for user
    }

    bool public stakingEnabled;

    address public phoenixNFTContract; // NFT contract for phoenix. Used to mint badge nfts
    address public stakingToken; // Staking ERC20 token
    address public treasuryAddress;

    uint32 public badgeNFTType; // nft type for training badge
    uint32 public minimumPhoenixNFTTypeForStaking;
    uint32 public maximumPhoenixNFTTypeForStaking;

    uint256 public stakeLockPeriod; // Period to lock stake; 0 for no lock;
    uint256 public stakingIncrement; // staking amount required per badge
    uint256 public totalPhoenixStaked;
    uint256 public totalStaked; // total amount staked in contract

    mapping(address => UserInfo) public userInfos; // User stake

    event Claim(address indexed user, uint256[] indexed phoenixIDs);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed amount,
        uint256[] indexed phoenixIDs
    );
    event Stake(address indexed user, uint32 indexed badgeID, uint32 indexed phoenixID);
    event Withdraw(address indexed user, uint256 indexed amount);

    error AmountMustBeIncrementOfStakingIncrement();
    error AddressIsZero();
    error InvalidBadgeType();
    error InvalidPhoenixType();
    error NoStake();
    error StakeLocked();
    error StakingDisabled();
    error StakingStarted();
    error UserNotNFTOwner();

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
        uint256 _stakingIncrement,
        uint32 _minimumPhoenixNFTTypeForStaking,
        uint32 _maximumPhoenixNFTTypeForStaking
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
        minimumPhoenixNFTTypeForStaking = _minimumPhoenixNFTTypeForStaking;
        maximumPhoenixNFTTypeForStaking = _maximumPhoenixNFTTypeForStaking;
    }

    function emergencyWithdrawByAdmin(address _user) external onlyOwner {
        UserInfo storage user = userInfos[_user];
        uint256 amount = user.stakedAmount;
        if (amount == 0) revert NoStake();

        uint256[] memory phoenixIDs = user.phoenixIDs;
        delete user.phoenixIDs;
        user.stakedAmount = 0;
        totalStaked -= amount;

        IERC20Upgradeable(stakingToken).transfer(address(_user), amount);

        // transfer phoenix back to user
        INFTSales(phoenixNFTContract).batchSafeTransferFrom(
            address(this),
            _msgSender(),
            phoenixIDs,
            ""
        );

        emit EmergencyWithdraw(_user, amount, phoenixIDs);
    }

    function setPhoenixNFTTypeForStaking(uint32 min, uint32 max)
        external
        onlyOwner
    {
        minimumPhoenixNFTTypeForStaking = min;
        maximumPhoenixNFTTypeForStaking = max;
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

    function stake(uint32 badgeID, uint32 phoenixID) external payable {
        if (!stakingEnabled) revert StakingDisabled();
        uint32[] memory tokenIDs = new uint32[](2);
        tokenIDs[0] = badgeID;
        tokenIDs[1] = phoenixID;

        // ensure sender is NFT owner
        if (
            !INFTSales(phoenixNFTContract).isOwnerOf(
                _msgSender(),
                tokenIDs
            )
        ) revert UserNotNFTOwner();

        // ensure correct badge and phoenix types
        uint32[] memory nftTypes = INFTSales(phoenixNFTContract)
            .getNFTTypesForTokenIDs(tokenIDs);
        if (nftTypes[0] != badgeNFTType) revert InvalidBadgeType();
        if (
            nftTypes[1] > maximumPhoenixNFTTypeForStaking ||
            nftTypes[1] < minimumPhoenixNFTTypeForStaking
        ) revert InvalidPhoenixType();

        // transfer tokens
        IERC20Upgradeable(stakingToken).transferFrom(
            address(_msgSender()),
            address(this),
            stakingIncrement
        );

        // transfer phoenix
        IERC721Upgradeable(phoenixNFTContract).safeTransferFrom(
            _msgSender(),
            address(this),
            phoenixID,
            ""
        );

        // send badge to treasury
        IERC721Upgradeable(phoenixNFTContract).safeTransferFrom(
            _msgSender(),
            treasuryAddress,
            badgeID,
            ""
        );

        UserInfo storage user = userInfos[_msgSender()];
        user.stakedAmount += stakingIncrement;
        user.phoenixIDs.push(phoenixID);
        user.lockPeriodEnd = block.timestamp + stakeLockPeriod;
        totalStaked += stakingIncrement;
        totalPhoenixStaked++;

        emit Stake(_msgSender(), badgeID, phoenixID);
    }

    function withdraw() external {
        UserInfo storage user = userInfos[_msgSender()];
        uint256 amount = user.stakedAmount;
        if (amount == 0) revert NoStake();
        if (block.timestamp < user.lockPeriodEnd) revert StakeLocked();

        user.stakedAmount = 0;
        user.lockPeriodEnd = 0;
        totalStaked -= amount;

        _claim();

        IERC20Upgradeable(stakingToken).transfer(address(_msgSender()), amount);

        emit Withdraw(_msgSender(), amount);
    }

    function _claim() private {
        UserInfo storage user = userInfos[_msgSender()];

        uint32[] memory phoenixIDs = new uint32[](user.phoenixIDs.length);
        for(uint256 x; x < user.phoenixIDs.length; x++) {
            phoenixIDs[x] = uint32(user.phoenixIDs[x]);
        }
        uint256[] memory phoenixIDs256 = user.phoenixIDs;
        delete user.phoenixIDs;

        // upgrade each phoenix
        uint32[] memory nftTypes = INFTSales(phoenixNFTContract)
            .getNFTTypesForTokenIDs(phoenixIDs);
        for (uint256 x; x < nftTypes.length; x++) {
            nftTypes[x]++;
        }
        INFTSales(phoenixNFTContract).evolve(phoenixIDs, nftTypes);

        // transfer phoenix back to user
        INFTSales(phoenixNFTContract).batchSafeTransferFrom(
            address(this),
            _msgSender(),
            phoenixIDs256,
            ""
        );
        emit Claim(_msgSender(), phoenixIDs256);
    }
}