// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./IBEP20.sol";
import "./IRewardPool.sol";

contract NftStakingPool is Ownable, ReentrancyGuard, IRewardPool, ERC721Holder {
    using SafeMath for uint256;
    using SafeERC20 for IBEP20;

    struct UserInfo {
        uint256 tokens; // How many staked tokens the user has provided
        uint256 rewardDebt; // Reward debt
    }

    uint256 private constant TOKEN_MULTIPLIER = 1e12;

    // The address of the smart chef factory
    address public immutable POOL_FACTORY;

    // Whether a limit is set for users
    bool public hasUserLimit;

    // Whether it is initialized
    bool public isInitialized;

    // Accrued token per share
    uint256 public accTokenPerShare;

    // The block number when mining ends.
    uint256 public bonusEndBlock;

    // The block number when mining starts.
    uint256 public startBlock;

    // The block number of the last pool update
    uint256 public lastRewardBlock;

    // The pool limit (0 if none)
    uint256 public poolLimitPerUser;

    // tokens reward per block.
    uint256 public rewardPerBlock;

    // The precision factor
    uint256 public PRECISION_FACTOR;

    // Platform Tax applied on deposits
    uint256 public tax;
    address public taxAddress;

    // Project Tax applied on deposits
    uint256 public projectTax;
    address public projectTaxAddress;

    // The reward token
    IBEP20 public rewardToken;

    // The staked token
    IERC721 public stakedToken;

    // Info of each user that stakes tokens (stakedToken)
    mapping(address => UserInfo) public userInfo;
    mapping(uint256 => address) public tokenOwners;

    event AdminTokenRecovery(address tokenRecovered, uint256 tokenId);
    event Deposit(address indexed user, uint256[] tokenIds);
    event EmergencyWithdraw(address indexed user, uint256 tokenId);
    event NewPoolLimit(uint256 poolLimitPerUser);
    event RewardsStop(uint256 blockNumber);
    event Withdraw(address indexed user, uint256[] tokenIds);

    constructor() {
        POOL_FACTORY = msg.sender;
    }

    function vaultAddress() external view override returns (address) {
        return address(this);
    }

    /*
     * @notice Initialize the contract
     */
    function initialize(RewardPoolConfiguration memory config) external {
        require(!isInitialized, "initialized");
        require(msg.sender == POOL_FACTORY, "not factory");
        require(config.tax <= 100, "tax"); // max 10%
        require(config.projectTax <= 100, "project tax"); // max 10%

        // Make this contract initialized
        isInitialized = true;

        stakedToken = IERC721(config.stakedToken);
        rewardToken = IBEP20(config.rewardToken);
        rewardPerBlock = config.rewardPerBlock;
        startBlock = config.startBlock;
        bonusEndBlock = config.bonusEndBlock;
        tax = config.tax;
        taxAddress = config.taxAddress;
        projectTax = config.projectTax;
        projectTaxAddress = config.projectTaxAddress;
        hasUserLimit = config.poolLimitPerUser > 0;
        poolLimitPerUser = config.poolLimitPerUser;

        uint256 decimalsRewardToken = uint256(rewardToken.decimals());
        require(decimalsRewardToken < 30, "decimals");

        PRECISION_FACTOR = uint256(10**(uint256(30).sub(decimalsRewardToken)));

        // Set the lastRewardBlock as the startBlock
        lastRewardBlock = startBlock;

        // Transfer ownership to the admin address who becomes owner of the contract
        transferOwnership(config.admin);
    }

    function _transferRewards(address to, uint256 amount) private {
        if (amount > 0) {
            if (tax > 0) {
                uint256 taxAmount = amount.mul(tax).div(1000);
                rewardToken.safeTransfer(taxAddress, taxAmount);
                amount -= taxAmount;
            }

            rewardToken.safeTransfer(to, amount);
        }
    }

    /*
     * @notice Deposit staked tokens and collect reward tokens (if any)
     */
    function deposit(uint256[] calldata tokenIds) external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];

        if (hasUserLimit) {
            require(tokenIds.length.add(user.tokens) <= poolLimitPerUser, "limit");
        }

        _updatePool();

        if (user.tokens > 0) {
            uint256 pending = user.tokens.mul(TOKEN_MULTIPLIER).mul(accTokenPerShare).div(PRECISION_FACTOR).sub(
                user.rewardDebt
            );
            _transferRewards(address(msg.sender), pending);
        }

        if (tokenIds.length > 0) {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                tokenOwners[tokenIds[i]] = msg.sender;
                stakedToken.safeTransferFrom(msg.sender, address(this), tokenIds[i], "");
            }
            user.tokens = user.tokens.add(tokenIds.length);
        }

        user.rewardDebt = user.tokens.mul(TOKEN_MULTIPLIER).mul(accTokenPerShare).div(PRECISION_FACTOR);

        emit Deposit(msg.sender, tokenIds);
    }

    /*
     * @notice Withdraw staked tokens and collect reward tokens
     */
    function withdraw(uint256[] calldata tokenIds) external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];

        _updatePool();

        uint256 pending = user.tokens.mul(TOKEN_MULTIPLIER).mul(accTokenPerShare).div(PRECISION_FACTOR).sub(
            user.rewardDebt
        );

        if (tokenIds.length > 0) {
            user.tokens = user.tokens.sub(tokenIds.length);
            for (uint256 i = 0; i < tokenIds.length; i++) {
                uint256 tokenId = tokenIds[i];
                require(tokenOwners[tokenId] == msg.sender, "Not owner");
                stakedToken.safeTransferFrom(address(this), msg.sender, tokenId, "");
                tokenOwners[tokenId] = address(0);
            }
        }

        if (pending > 0) {
            _transferRewards(msg.sender, pending);
        }

        user.rewardDebt = user.tokens.mul(TOKEN_MULTIPLIER).mul(accTokenPerShare).div(PRECISION_FACTOR);

        emit Withdraw(msg.sender, tokenIds);
    }

    /*
     * @notice Withdraw staked tokens without caring about rewards rewards
     * @dev Needs to be for emergency.
     */
    function emergencyWithdraw(uint256 tokenId) external nonReentrant {
        require(tokenOwners[tokenId] == msg.sender, "Not owner");

        UserInfo storage user = userInfo[msg.sender];

        user.tokens = user.tokens.sub(1);
        tokenOwners[tokenId] = address(0);
        user.rewardDebt = user.tokens.mul(TOKEN_MULTIPLIER).mul(accTokenPerShare).div(PRECISION_FACTOR);

        stakedToken.safeTransferFrom(address(this), msg.sender, tokenId, "");

        emit EmergencyWithdraw(msg.sender, tokenId);
    }

    /*
     * @notice Stop rewards
     * @dev Only callable by owner. Needs to be for emergency.
     */
    function emergencyRewardWithdraw(uint256 _amount) external onlyOwner {
        rewardToken.safeTransfer(address(msg.sender), _amount);
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of tokens to withdraw
     * @dev This function is only callable by admin.
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        require(_tokenAddress != address(rewardToken), "not reward");

        IBEP20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);

        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }

    /*
     * @notice Stop rewards
     * @dev Only callable by owner
     */
    function stopReward() external onlyOwner {
        bonusEndBlock = block.number;
    }

    /*
     * @notice Update pool limit per user
     * @dev Only callable by owner.
     * @param _hasUserLimit: whether the limit remains forced
     * @param _poolLimitPerUser: new pool limit per user
     */
    function updatePoolLimitPerUser(bool _hasUserLimit, uint256 _poolLimitPerUser) external onlyOwner {
        require(hasUserLimit, "set");
        if (_hasUserLimit) {
            require(_poolLimitPerUser > poolLimitPerUser, "limit");
            poolLimitPerUser = _poolLimitPerUser;
        } else {
            hasUserLimit = _hasUserLimit;
            poolLimitPerUser = 0;
        }
        emit NewPoolLimit(poolLimitPerUser);
    }

    /*
     * @notice View function to see pending reward on frontend.
     * @param _user: user address
     * @return Pending reward for a given user
     */
    function pendingReward(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 stakedTokenSupply = stakedToken.balanceOf(address(this)).mul(TOKEN_MULTIPLIER);
        if (block.number > lastRewardBlock && stakedTokenSupply != 0) {
            uint256 tokenReward = _getMultiplier(lastRewardBlock, block.number).mul(rewardPerBlock);
            uint256 adjustedTokenPerShare = accTokenPerShare.add(
                tokenReward.mul(PRECISION_FACTOR).div(stakedTokenSupply)
            );
            return
                user.tokens.mul(TOKEN_MULTIPLIER).mul(adjustedTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt);
        } else {
            return user.tokens.mul(TOKEN_MULTIPLIER).mul(accTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt);
        }
    }

    /*
     * @notice Update reward variables of the given pool to be up-to-date.
     */
    function _updatePool() internal {
        if (block.number <= lastRewardBlock) {
            return;
        }

        uint256 stakedTokenSupply = stakedToken.balanceOf(address(this)).mul(TOKEN_MULTIPLIER);
        if (stakedTokenSupply == 0) {
            lastRewardBlock = block.number;
            return;
        }

        uint256 tokenReward = _getMultiplier(lastRewardBlock, block.number).mul(rewardPerBlock);
        accTokenPerShare = accTokenPerShare.add(tokenReward.mul(PRECISION_FACTOR).div(stakedTokenSupply));
        lastRewardBlock = block.number;
    }

    /*
     * @notice Return reward multiplier over the given _from to _to block.
     * @param _from: block to start
     * @param _to: block to finish
     */
    function _getMultiplier(uint256 _from, uint256 _to) internal view returns (uint256) {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from);
        } else if (_from >= bonusEndBlock) {
            return 0;
        } else {
            return bonusEndBlock.sub(_from);
        }
    }
}