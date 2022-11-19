// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

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
import "./interfaces/INFTSales.sol";
import "hardhat/console.sol";

// https://docs.synthetix.io/contracts/source/contracts/rewardsdistributionrecipient
abstract contract RewardsDistributionRecipient is OwnableUpgradeable {
    address public rewardsDistribution;

    function notifyRewardAmount(uint256 reward) external virtual;

    modifier onlyRewardsDistribution() {
        require(
            msg.sender == rewardsDistribution,
            "Caller is not RewardsDistribution contract"
        );
        _;
    }

    function setRewardsDistribution(address _rewardsDistribution)
        external
        onlyOwner
    {
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

    /* ========== STATE VARIABLES ========== */

    IERC20Upgradeable public rewardsToken;
    IERC721Upgradeable public stakingToken;
    uint256 public periodFinish;
    uint256 public rewardRate;
    uint256 public rewardsDuration;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    // added mapping to hold balances of ERC721 sent to contract
    // NFT owner -> TokenID
    mapping(address => uint) public _tokenBalances;
    // Account => All NFT ids staked (not updated during withdraw)
    mapping(address => uint32[]) private _tokenIdsStaked;
    // nft id => stake value from BLL
    mapping(uint32 => uint256) public stakedAtValue;

    // total worth value of staked token ids
    uint256 private _totalSupply;
    // Account => total worth value of staked token ids for the account
    mapping(address => uint256) private _balances;

    // all nft ids in smart contract staked (not updated during withdraw)
    uint32[] public allNFTIds;
    // nft id => owner address (not updated during withdraw)
    mapping(uint32 => address) public ownerOfNFT;
    // nft id => bool (updated during withdraw)
    mapping(uint32 => bool) public isStaked;

    IBLL public BLLContract;

    struct StakedNFT {
        address user;
        bool isStaked;
    }
    INFTSales public stakingNFT;

    // Tracks if stake refreshed since contract
    mapping(address => bool) public stakeRefreshed;
    // Mapping from staker to list of staked token IDs
    mapping(address => mapping(uint256 => uint256)) private _stakedTokens;
    // Mapping from token ID to index of the staker tokens list
    mapping(uint256 => uint256) private _stakedTokensIndex;

    /* ========== CONSTRUCTOR ========== */

    function initialize(
        address _rewardsDistribution,
        address _rewardsToken1,
        address _stakingToken, // ERC721 token
        address _BLLContract
    ) public initializer {
        __Ownable_init_unchained();
        rewardsToken = IERC20Upgradeable(_rewardsToken1);
        stakingToken = IERC721Upgradeable(_stakingToken);
        rewardsDistribution = _rewardsDistribution;
        BLLContract = IBLL(_BLLContract);

        require(
            _rewardsDistribution != address(0),
            "_rewardsDistribution cannot be zero address"
        );
        require(
            _rewardsToken1 != address(0),
            "_rewardsToken1 cannot be zero address"
        );
        require(
            _stakingToken != address(0),
            "_stakingToken cannot be zero address"
        );
        require(
            _BLLContract != address(0),
            "_BLLContract cannot be zero address"
        );

        periodFinish = 0;
        rewardRate = 0;
        rewardsDuration = 60 days;
        stakingNFT = INFTSales(_stakingToken);
    }

    /* ========== VIEWS ========== */

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function balanceOfNFT(address account) external view returns (uint256) {
        return _tokenBalances[account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return MathUpgradeable.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        return
            _totalSupply == 0
                ? rewardPerTokenStored
                : rewardPerTokenStored.add(
                    lastTimeRewardApplicable()
                        .sub(lastUpdateTime)
                        .mul(rewardRate)
                        .mul(1e18)
                        .div(_totalSupply)
                );
    }

    function earned(address account) public view returns (uint256) {
        return
            _balances[account]
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    function getRewardToken1APY() external view returns (uint256) {
        //3153600000 = 365*24*60*60
        if (block.timestamp > periodFinish) return 0;
        uint256 rewardForYear = rewardRate.mul(31536000);
        if (_totalSupply <= 1e18) return rewardForYear.div(1e10);
        return rewardForYear.mul(1e8).div(_totalSupply); // put 6 dp
    }

    function getRewardToken1WPY() external view returns (uint256) {
        //60480000 = 7*24*60*60
        if (block.timestamp > periodFinish) return 0;
        uint256 rewardForWeek = rewardRate.mul(604800);
        if (_totalSupply <= 1e18) return rewardForWeek.div(1e10);
        return rewardForWeek.mul(1e8).div(_totalSupply); // put 6 dp
    }

    function tokenIdsStaked(address account)
        external
        view
        returns (uint32[] memory)
    {
        return _getTokenIdsStaked(account);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256[] memory tokenIds, uint32[] memory tokenIdsSm)
        external
        nonReentrant
        whenNotPaused
        updateReward(_msgSender())
    {
        if (_tokenBalances[_msgSender()] == 0)
            stakeRefreshed[_msgSender()] = true;
        if (!stakeRefreshed[_msgSender()]) _refreshStaked(_msgSender());
        stakingNFT.batchTransferFrom(
            _msgSender(),
            address(this),
            tokenIds
        ); // confirms sender owns tokens
        uint256[] memory pointsArray = BLLContract.getPointsForTokenIDs(tokenIdsSm);
        uint points;
        for (uint32 x; x < tokenIds.length; ++x) {
            _addTokenToStakerEnumeration(_msgSender(), tokenIds[x]);
            ++_tokenBalances[_msgSender()];
            points += pointsArray[x];
        }
        _totalSupply += points;
        _balances[_msgSender()] += points;
        emit Staked(_msgSender(), tokenIdsSm);
    }

    function withdraw(uint256[] memory tokenIds, uint32[] memory tokendIdsSm)
        public
        nonReentrant
        updateReward(_msgSender())
    {
        if (!stakeRefreshed[_msgSender()]) _refreshStaked(_msgSender());

        uint256[] memory pointsArray = BLLContract.getPointsForTokenIDs(tokendIdsSm);
        uint points;
        for (uint32 x; x < tokenIds.length; ++x) {
            _removeTokenFromStakerEnumeration(_msgSender(), tokenIds[x]);
            points += pointsArray[x];
        }
        _balances[_msgSender()] -= points;
        _totalSupply -= points;
        _tokenBalances[_msgSender()] -= tokenIds.length;
        stakingNFT.batchTransferFrom(
            address(this),
            _msgSender(),
            tokenIds
        );
        emit Withdrawn(_msgSender(), tokendIdsSm);
    }

    function setBLLContract(IBLL _BLLContract) external onlyOwner {
        BLLContract = _BLLContract;
    }

    function getReward() public nonReentrant updateReward(_msgSender()) {
        uint256 reward = rewards[_msgSender()];
        if (reward == 0) return;
        rewards[_msgSender()] = 0;
        rewardsToken.transfer(_msgSender(), reward);
        emit RewardPaid(_msgSender(), reward);
    }

    function exit(uint256[] memory tokenIds, uint32[] memory tokendIdsSm) external {
        withdraw(tokenIds, tokendIdsSm);
        getReward();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount(uint256 reward)
        external
        override
        onlyRewardsDistribution
        updateReward(address(0))
    {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint balance = rewardsToken.balanceOf(address(this));
        require(
            rewardRate <= balance.div(rewardsDuration),
            "Provided reward too high"
        );

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
        require(
            block.timestamp > periodFinish,
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _id,
        bytes calldata _data
    ) external returns (bytes4) {
        return 0x150b7a02;
    }

    // can only be called once per account
    function refreshStaked(address[] calldata accounts) external onlyOwner {
        for (uint32 x; x < accounts.length; ++x) {
            _refreshStaked(accounts[x]);
        }
    }

    function _refreshStaked(address account) private {
        if (stakeRefreshed[account]) return;
        _tokenBalances[account] = 0;
        uint256 bal;
        uint32[] memory arrStaked = _tokenIdsStaked[account];
        for (uint32 y; y < arrStaked.length; ++y) {
            uint32 tokenId = arrStaked[y];
            if (!isStaked[tokenId] || ownerOfNFT[tokenId] != account) continue;
            _addTokenToStakerEnumeration(account, tokenId);
            ++_tokenBalances[account];
            ++bal;
        }
        stakeRefreshed[account] = true;
    }

    function refreshTokenIdsStaked(address account) external onlyOwner {
        if (!stakeRefreshed[account]) _refreshStaked(account);
        _tokenIdsStaked[account] = _getTokenIdsStaked(account);
    }

    function setStakingNFT(address value) external onlyOwner {
        stakingNFT = INFTSales(value);
    }

    function _getTokenIdsStaked(address account)
        private
        view
        returns (uint32[] memory)
    {
        if (stakeRefreshed[account]) {
            uint256 bal = _tokenBalances[account];
            uint32[] memory returnVal = new uint32[](bal);
            for (uint256 x; x < bal; x++) {
                returnVal[x] = uint32(_tokenOfStakerByIndex(account, x));
            }
            return returnVal;
        }

        uint32[] memory arrStaked = _tokenIdsStaked[account];
        uint32 newArrSize;
        // find size of new arr
        for (uint32 i = 0; i < arrStaked.length; ++i)
            if (isStaked[arrStaked[i]]) ++newArrSize;

        uint32[] memory newArr = new uint32[](newArrSize);
        uint32 k;
        for (uint32 i; i < arrStaked.length; ++i) {
            if (isStaked[arrStaked[i]]) {
                newArr[k] = arrStaked[i];
                ++k;
            }
        }

        return newArr;
    }

    /* ========== ENUMERABLE ========== */

    function _tokenOfStakerByIndex(address account, uint256 index)
        private
        view
        returns (uint256)
    {
        require(index < _tokenBalances[account], "index out of bounds");
        return _stakedTokens[account][index];
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param account address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToStakerEnumeration(address account, uint256 tokenId)
        private
    {
        uint256 length = _tokenBalances[account];
        _stakedTokens[account][length] = tokenId;
        _stakedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to remove a token from the ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_stakedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _stakedTokens array.
     * @param account address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromStakerEnumeration(address account, uint256 tokenId)
        private
    {
        // To prevent a gap in account's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _tokenBalances[account] - 1;
        uint256 tokenIndex = _stakedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _stakedTokens[account][lastTokenIndex];

            _stakedTokens[account][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _stakedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _stakedTokensIndex[tokenId];
        delete _stakedTokens[account][lastTokenIndex];
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint32[] tokenIds);
    event Withdrawn(address indexed user, uint32[] tokenIds);
    event WithdrawnAll(address indexed user);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event RefreshedAllNFTids();
}