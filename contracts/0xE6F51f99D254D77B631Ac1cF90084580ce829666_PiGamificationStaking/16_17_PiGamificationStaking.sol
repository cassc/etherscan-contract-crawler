// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "./TokensRecoverable.sol";
import "./interfaces/IBLL.sol";
import "./interfaces/INFT.sol";

// https://docs.synthetix.io/contracts/source/contracts/rewardsdistributionrecipient
abstract contract RewardsDistributionRecipient is OwnableUpgradeable {
    address public rewardsDistribution;

    error CallerNotRewardsDistribution();

    modifier onlyRewardsDistribution() {
        if (_msgSender() != rewardsDistribution)
            revert CallerNotRewardsDistribution();
        _;
    }

    function notifyRewardAmount(uint256 reward) external virtual;

    function setRewardsDistribution(
        address _rewardsDistribution
    ) external onlyOwner {
        require(
            _rewardsDistribution != address(0),
            "_rewardsDistribution cannot be zero address"
        );
        rewardsDistribution = _rewardsDistribution;
    }
}

// https://docs.synthetix.io/contracts/source/contracts/stakingrewards
contract PiGamificationStaking is
    Initializable,
    OwnableUpgradeable,
    RewardsDistributionRecipient,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    TokensRecoverable
{
    using SafeMathUpgradeable for uint256;

    IBLL public BLLContract;
    IERC20Upgradeable public rewardsToken;
    INFT public stakingToken;

    uint256 public lastUpdateTime;
    uint256 public periodFinish;
    uint256 public rewardPerTokenStored;
    uint256 public rewardRate;
    uint256 public rewardsDuration;

    uint256 private totalPointsStaked;

    mapping(address => uint) public _tokenBalances; // NFT owner -> TokenID
    mapping(uint32 => address) public ownerOfNFT; // nft id => owner address
    mapping(address => uint256) public rewards;
    mapping(uint32 => uint) public tokenPointsFromBll; // synced from BLL
    mapping(address => uint256) public userRewardPerTokenPaid;

    mapping(address => uint32[]) public nftOwnerToStakedIds;
    mapping(address => uint256) public nftOwnerToStakedPoints;

    error AddressIsZero();
    error NotNFTOwner();
    error PreviousRewardPeriodIncomplete();
    error RewardTooHigh();

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint32[] tokenIds);
    event Withdraw(address indexed user, uint32[] tokenIds);
    event WithdrawAll(address indexed user, uint32[] tokenIds);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event UpdatedPoints(uint32[] nftIDs);
    event RefreshedTokenIdsStaked(address indexed user);

    modifier notZeroAddress(address value) {
        if (value == address(0)) revert AddressIsZero();
        _;
    }
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function initialize(
        address _rewardsDistribution,
        address _rewardsToken1,
        address _stakingToken, // ERC721 token
        address _BLLContract
    )
        public
        initializer
        notZeroAddress(_rewardsDistribution)
        notZeroAddress(_rewardsToken1)
        notZeroAddress(_stakingToken)
        notZeroAddress(_BLLContract)
    {
        __Ownable_init_unchained();
        rewardsToken = IERC20Upgradeable(_rewardsToken1);
        stakingToken = INFT(_stakingToken);
        rewardsDistribution = _rewardsDistribution;
        BLLContract = IBLL(_BLLContract);

        periodFinish = 0;
        rewardRate = 0;
        rewardsDuration = 60 days;
    }

    function balanceOf(address account) external view returns (uint256) {
        return nftOwnerToStakedPoints[account];
    }

    function balanceOfNFT(address account) external view returns (uint256) {
        return _tokenBalances[account];
    }

    function exit() external {
        _withdraw(tokenIdsStaked(_msgSender()));
        getReward();
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate / rewardsDuration;
    }

    function getRewardToken1APY() external view returns (uint256) {
        //3153600000 = 365*24*60*60
        if (block.timestamp > periodFinish) return 0;
        uint256 rewardForYear = rewardRate * 31536000;
        if (totalPointsStaked <= 1e18) return rewardForYear / 1e10;
        return (rewardForYear * 1e8) / totalPointsStaked; // put 6 dp
    }

    function getRewardToken1WPY() external view returns (uint256) {
        //60480000 = 7*24*60*60
        if (block.timestamp > periodFinish) return 0;
        uint256 rewardForWeek = rewardRate * 604800;
        if (totalPointsStaked <= 1e18) return rewardForWeek / 1e10;
        return (rewardForWeek * 1e8) / totalPointsStaked; // put 6 dp
    }

    function notifyRewardAmount(
        uint256 reward
    ) external override onlyRewardsDistribution updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward / rewardsDuration;
        } else {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            rewardRate = reward + leftover / rewardsDuration;
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint balance = rewardsToken.balanceOf(address(this));
        if (rewardRate > balance / rewardsDuration) revert RewardTooHigh();

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + rewardsDuration;
        emit RewardAdded(reward);
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _id,
        bytes calldata _data
    ) external returns (bytes4) {
        return 0x150b7a02;
    }

    function setBLLContract(IBLL bllContract) external onlyOwner {
        BLLContract = bllContract;
    }

    function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
        if (block.timestamp <= periodFinish)
            revert PreviousRewardPeriodIncomplete();
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    function stake(
        uint32[] memory tokenIds
    ) external nonReentrant whenNotPaused updateReward(_msgSender()) {
        // bulk transfer available, then uncomment below and comment safeTransferFrom in loop?
        stakingToken.batchTransferFromSmallInt(
            _msgSender(),
            address(this),
            tokenIds
        );

        uint totValue;
        for (uint i; i < tokenIds.length; ++i) {
            // need to get value 1 by 1 for each tokenId so that we know "stakedAtValue[tokenIds[i]]" for each tokenId.
            uint32 tokenId = tokenIds[i];
            totValue += tokenPointsFromBll[tokenId];
            ownerOfNFT[tokenId] = _msgSender();
            nftOwnerToStakedIds[_msgSender()].push(tokenId);
        }
        _stakeValue(_msgSender(), totValue);
        _tokenBalances[_msgSender()] += tokenIds.length;
        emit Staked(_msgSender(), tokenIds);
    }

    function syncPointsForTokenIDs(
        uint32[] memory nftIDs
    ) external returns (bool) {
        for (uint i; i < nftIDs.length; ++i) {
            uint32 tokenId = nftIDs[i];
            uint256 prevValue = tokenPointsFromBll[tokenId];
            uint256 value = BLLContract.getPointsForTokenID(tokenId) * 1e18;
            tokenPointsFromBll[tokenId] = value;
            _updatePointsForID(tokenId, prevValue, value);
        }
        return true;
    }

    function _updatePointsForID(
        uint32 tokenId,
        uint256 prevValue,
        uint256 newValue
    ) private onlyOwner {
        if (ownerOfNFT[tokenId] == address(0)) return;
        address account = ownerOfNFT[tokenId];
        _refreshReward(account);
        _unstakeValue(
            account,
            prevValue > newValue ? prevValue - newValue : newValue - prevValue
        );
    }

    function syncPointsForTokenIDsRange(
        uint32 startNFTID,
        uint32 endNFTID
    ) external returns (bool) {
        for (uint32 i = startNFTID; i <= endNFTID; ++i) {
            uint256 prevValue = tokenPointsFromBll[i];
            uint256 value = BLLContract.getPointsForTokenID(i) * 1e18;
            tokenPointsFromBll[i] = value;
            _updatePointsForID(i, prevValue, value);
        }
        return true;
    }

    function totalSupply() external view returns (uint256) {
        return totalPointsStaked;
    }

    function earned(address account) public view returns (uint256) {
        return
            (nftOwnerToStakedPoints[account] *
                (rewardPerToken() - userRewardPerTokenPaid[account])) /
            1e18 +
            rewards[account];
    }

    function getReward() public nonReentrant updateReward(_msgSender()) {
        uint256 reward = rewards[_msgSender()];
        if (reward > 0) {
            rewards[_msgSender()] = 0;
            rewardsToken.transfer(_msgSender(), reward);
            emit RewardPaid(_msgSender(), reward);
        }
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return MathUpgradeable.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalPointsStaked == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(totalPointsStaked)
            );
    }

    function tokenIdsStaked(
        address account
    ) public view returns (uint32[] memory) {
        uint32[] memory arrStaked = nftOwnerToStakedIds[account];

        uint32 newArrSize;
        // find size of new arr
        for (uint32 x; x < arrStaked.length; ++x) {
            if (ownerOfNFT[arrStaked[x]] != account) continue;
            ++newArrSize;
        }

        uint32[] memory result = new uint32[](newArrSize);
        uint32 j;
        for (uint32 x; x < arrStaked.length; ++x) {
            if (ownerOfNFT[arrStaked[x]] != account) continue;
            result[j] = arrStaked[x];
            ++j;
        }

        return result;
    }

    function withdraw(
        uint32[] memory tokenIds
    ) public nonReentrant updateReward(_msgSender()) {
        _withdraw(tokenIds);
    }

    function _stakeValue(address account, uint delta) internal {
        totalPointsStaked += delta;
        nftOwnerToStakedPoints[account] += delta;
    }

    function _unstakeValue(address account, uint delta) internal {
        totalPointsStaked -= delta;
        nftOwnerToStakedPoints[account] -= delta;
    }

    function _withdraw(
        uint32[] memory tokenIds
    ) internal updateReward(_msgSender()) {
        _tokenBalances[_msgSender()] -= tokenIds.length;

        uint256 value;
        for (uint32 i = 0; i < tokenIds.length; ++i) {
            if (ownerOfNFT[tokenIds[i]] != _msgSender()) revert NotNFTOwner();
            value += tokenPointsFromBll[tokenIds[i]];
            ownerOfNFT[tokenIds[i]] = address(0);
        }
        totalPointsStaked -= value;
        nftOwnerToStakedPoints[_msgSender()] -= value;

        stakingToken.batchTransferFromSmallInt(
            address(this),
            _msgSender(),
            tokenIds
        );
        emit Withdraw(_msgSender(), tokenIds);
    }

    function _refreshReward(address account) internal updateReward(account) {}
}