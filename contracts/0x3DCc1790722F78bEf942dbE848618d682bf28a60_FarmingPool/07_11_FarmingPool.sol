// SPDX-License-Identifier: MIT

pragma solidity =0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IFungibleToken.sol";
import "./interfaces/IAffiliateProgram.sol";
import "./interfaces/ITokenStorage.sol";
import "./interfaces/IFarmingPool.sol";

// @title FarmingPool - staking contract simplified MasterChef.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once XXX is sufficiently
// distributed and the community can show to govern itself.
//
// Please disable mining in two steps first remove MINTER_ROLE rights, then through
// some time set multiplier value 0.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract FarmingPool is Ownable, IFarmingPool {
    using SafeERC20 for IERC20;
    using SafeERC20 for IFungibleToken;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 lockedTo; // Amount locked to.
    }
    // Info of each pool.
    struct PoolInfo {
        IERC20 stakingToken; // Address of LP token contract.
        uint256 lastRewardBlock; // Last block number that XXXes distribution occurs.
        uint256 accTokensPerShare; // Accumulated XXXes per share, times 1e12. See below.
        uint256 totalDeposited; // Total deposited tokens amount.
    }
    // Initialization storage.
    bool internal _initialized;
    // The XXX TOKEN!
    IFungibleToken public rewardToken;
    // Reward token storage.
    address public mintFromWallet;
    // XXX tokens created per block.
    uint256 public tokensPerBlock;
    // Bonus muliplier for early rewardToken makers.
    uint256 public rewardMultiplier;
    // The block number when XXX mining starts.
    uint256 public startBlock;
    // Deposit locked for that time.
    uint256 public lockPeriod;
    // Affiliate percent, added to referral reward.
    uint256 public affiliatePercent;
    // Affiliate program.
    address public affiliateProgram;
    // Info of each pool.
    PoolInfo public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(address => UserInfo) public userInfo;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event MintError(string);
    event MintToAffiliateError(string);
    event TokenPerBlockSet(uint256 amount);
    event RewardMultiplierSet(uint256 multiplier);
    event LockPeriodSet(uint256 secs);
    event AffiliateReward(address affiliate, uint256 reward);
    event AffiliatePercentSet(uint256 value);
    event AffiliateProgramSet(address addr);
    event MintWalletSet(address addr);

    function initialize(
        IFungibleToken _depositToken,
        IFungibleToken _rewardToken,
        address _mintFromWallet,
        address _admin,
        uint256 _tokensPerBlock,
        uint256 _startBlock
    ) public {
        require(!_initialized, "Initialized");
        require(address(_depositToken) != address(0), "Staking: constructor deposit token");

        _initialized = true;
        _transferOwnership(_admin);

        rewardToken = _rewardToken;
        tokensPerBlock = _tokensPerBlock;
        startBlock = _startBlock;

        if (_mintFromWallet != address(0)) {
            require(_rewardToken == ITokenStorage(_mintFromWallet).token(), "Reward token");
            mintFromWallet = _mintFromWallet;
        }

        rewardMultiplier = 1;

        // staking pool
        poolInfo = PoolInfo({
            stakingToken: _depositToken,
            lastRewardBlock: startBlock,
            accTokensPerShare: 0,
            totalDeposited: 0
        });
    }

    /**
     * @dev Set tokens per block. Zero set disable mining.
     */
    function setTokensPerBlock(uint256 _amount) external onlyOwner {
        updatePool();
        tokensPerBlock = _amount;
        emit TokenPerBlockSet(_amount);
    }

    /**
     * @dev Set reward multiplier. Zero set disable mining.
     */
    function setRewardMultiplier(uint256 _multiplier) external onlyOwner {
        updatePool();
        rewardMultiplier = _multiplier;
        emit RewardMultiplierSet(_multiplier);
    }

    /**
     * @dev Set lock period.
     */
    function setLockPeriod(uint256 _seconds) external onlyOwner {
        lockPeriod = _seconds;
        emit LockPeriodSet(_seconds);
    }

    /**
     * @dev Set affiliate percent period.
     */
    function setAffiliatePercent(uint256 _percent) external onlyOwner {
        affiliatePercent = _percent;
        emit AffiliatePercentSet(_percent);
    }

    /**
     * @dev Set lock period.
     */
    function setAffiliateProgram(address _addr) external onlyOwner {
        affiliateProgram = _addr;
        emit AffiliateProgramSet(_addr);
    }

    /**
     * @dev Set mint wallet. address(0) - disable feature
     */
    function setMintWallet(address _addr) external onlyOwner {
        if (_addr != address(0)) {
            require(rewardToken == ITokenStorage(_addr).token(), "Reward token");
            mintFromWallet = _addr;
        }
        emit MintWalletSet(_addr);
    }

    /**
     * @dev Deposit token.
     *      Send `_amount` as 0 for claim effect.
     */
    function deposit(uint256 _amount) external {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[msg.sender];
        updatePool();
        if (user.amount > 0) {
            uint256 pending = ((user.amount * pool.accTokensPerShare) / 1e12) - user.rewardDebt;
            if (pending > 0) {
                if (user.lockedTo != 0 && user.lockedTo > block.timestamp) {
                    _safeTransfer(owner(), pending);
                } else {
                    _safeTransfer(msg.sender, pending);
                    _mintAffiliateReward(msg.sender, pending);
                }
            }
        }
        if (_amount != 0) {
            pool.stakingToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount + _amount;
            user.lockedTo = block.timestamp + lockPeriod;
            pool.totalDeposited += _amount;
        }
        user.rewardDebt = (user.amount * pool.accTokensPerShare) / 1e12;
        emit Deposit(msg.sender, _amount);
    }

    /**
     * @dev Withdraw tokens with reward.
     */
    function withdraw(uint256 _amount) external {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "Withdraw insufficient balance");
        updatePool();
        uint256 pending = ((user.amount * pool.accTokensPerShare) / 1e12) - user.rewardDebt;
        if (pending > 0) {
            if (user.lockedTo != 0 && user.lockedTo > block.timestamp) {
                _safeTransfer(owner(), pending);
            } else {
                _safeTransfer(msg.sender, pending);
                _mintAffiliateReward(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            user.amount = user.amount - _amount;
            pool.totalDeposited -= _amount;
            pool.stakingToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = (user.amount * pool.accTokensPerShare) / 1e12;
        emit Withdraw(msg.sender, _amount);
    }

    /**
     * @dev Withdraw without caring about rewards. EMERGENCY ONLY. ONLY OWNER.
     */
    function emergencyWithdraw(address _account) external onlyOwner {
        PoolInfo storage pool = poolInfo;
        UserInfo storage user = userInfo[_account];
        pool.totalDeposited -= user.amount;
        pool.stakingToken.safeTransfer(_account, user.amount);
        emit EmergencyWithdraw(_account, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
        user.lockedTo = 0;
    }

    /**
     * @dev View function to see pending XXXes on frontend.
     */
    function pendingReward(address _user) external view returns (uint256 reward) {
        PoolInfo memory pool = poolInfo;
        UserInfo memory user = userInfo[_user];
        uint256 accTokensPerShare = pool.accTokensPerShare;
        uint256 lpSupply = pool.totalDeposited;
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 tokenReward = multiplier * tokensPerBlock;
            accTokensPerShare = accTokensPerShare + ((tokenReward * 1e12) / lpSupply);
        }
        reward = (user.amount * accTokensPerShare) / 1e12 - user.rewardDebt;
    }

    /**
     * @dev View function to see available XXXes on frontend.
     */
    function availableReward(address _user) external view returns (uint256 reward) {
        PoolInfo memory pool = poolInfo;
        UserInfo memory user = userInfo[_user];
        uint256 accTokensPerShare = pool.accTokensPerShare;
        uint256 lpSupply = pool.totalDeposited;
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 tokenReward = multiplier * tokensPerBlock;
            accTokensPerShare = accTokensPerShare + ((tokenReward * 1e12) / lpSupply);
        }
        if (user.lockedTo < block.timestamp) {
            reward = (user.amount * accTokensPerShare) / 1e12 - user.rewardDebt;
        }
    }

    /**
     * @dev Update reward variables of the given pool to be up-to-date.
     */
    function updatePool() public {
        PoolInfo storage pool = poolInfo;
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.totalDeposited;
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 tokenReward = multiplier * tokensPerBlock;
        if (tokenReward == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        if (mintFromWallet != address(0)) {
            try ITokenStorage(mintFromWallet).charge(address(this), tokenReward) {
                //
            } catch Error(string memory reason) {
                emit MintError(reason);
            }
        } else {
            try rewardToken.mint(address(this), tokenReward) {
                //
            } catch Error(string memory reason) {
                emit MintError(reason);
            }
        }

        pool.accTokensPerShare = pool.accTokensPerShare + ((tokenReward * 1e12) / lpSupply);
        pool.lastRewardBlock = block.number;
    }

    /**
     * @dev Return reward multiplier over the given _from to _to block.
     */
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256 multiplier) {
        multiplier = (_to - _from) * rewardMultiplier;
    }

    function _mintAffiliateReward(address _user, uint256 _pendingReward) internal {
        if (affiliateProgram == address(0)) {
            return;
        }
        address affiliate = IAffiliateProgram(affiliateProgram).getAffiliate(_user);
        if (affiliate != address(0)) {
            _pendingReward = (_pendingReward * affiliatePercent) / 100;
            if (mintFromWallet != address(0)) {
                try ITokenStorage(mintFromWallet).charge(affiliate, _pendingReward) {
                    //
                } catch Error(string memory reason) {
                    emit MintToAffiliateError(reason);
                }
            } else {
                try rewardToken.mint(affiliate, _pendingReward) {
                    //
                } catch Error(string memory reason) {
                    emit MintToAffiliateError(reason);
                }
            }
        }
    }

    /**
     * @dev Safe rewardToken transfer function, just in case
     * if rounding error causes pool to not have enough XXXes.
     */
    function _safeTransfer(address _to, uint256 _amount) internal {
        uint256 xxxBalance = (rewardToken == poolInfo.stakingToken)
            ? rewardToken.balanceOf(address(this)) - poolInfo.totalDeposited
            : rewardToken.balanceOf(address(this));
        if (_amount > xxxBalance) {
            rewardToken.safeTransfer(_to, xxxBalance);
        } else {
            rewardToken.safeTransfer(_to, _amount);
        }
    }
}