// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../lib/IBEP20.sol";
import "../lib/SafeBEP20.sol";
import "../lib/IRewarder.sol";
import "../lib/ITBCCMasterChef.sol";
import "../lib/ITFT.sol";
import '../lib/ITBCCDEFIAPES.sol';

interface IMigratorChef {
    function migrate(IBEP20 token) external returns (IBEP20);
}

contract TBCCMasterChef is ITBCCMasterChef, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    /// @notice Address of TFT contract.
    ITFT public tft;
    /// @notice Address of TDA contract.
    ITBCCDEFIAPES public tbccDefiApes;
    bool public claimingPause;
    // TFT tokens created per block.
    uint256 public tftPerBlock;
    // TFT tokens claim per one TBCC TDA
    uint256 public claimAmount;

    /// @notice Info of each TBCCMCV pool.
    PoolInfo[] public poolInfo;
    /// @notice Address of the LP token for each TBCCMCV pool.
    IBEP20[] public lpToken;
    /// @notice Address of each `IRewarder` contract in TBCCMCV.
    IRewarder[] public rewarder;
    // The migrator contract. It has a lot of power. Can only be set through governance (owner).
    IMigratorChef public migrator;

    /// @notice Info for new bonuses
    BonusInfo[] public bonuses;
    /// @notice Info of each pool user.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    /// @dev Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;
    // The block number when TFT mining starts.
    uint256 public startBlock;
    /// @notice Info of TDA claimed
    mapping(uint256 => address) public tdaClaimed;

    uint256 private constant ACC_TFT_PRECISION = 1e12;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount, address indexed to);
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);
    event LogPoolAddition(uint256 indexed pid, uint256 allocPoint, IBEP20 indexed lpToken, IRewarder indexed rewarder);
    event LogSetPool(uint256 indexed pid, uint256 allocPoint, IRewarder indexed rewarder, bool overwrite);
    event LogUpdatePool(uint256 indexed pid, uint256 lastRewardBlock, uint256 lpSupply, uint256 accTFTPerShare);
    event AddNewBonus(uint256 startBlock, uint256 bonus);
    event NFTTDAClaimed(address sender, uint256 tokenId, uint256 amount);
    event NewClaimApesAmount(uint256 newAmount);

    // Modifier for NFT holder
    modifier onlyNFTTDAHolder(address sender, uint256 tokenId) {
        require(sender == tbccDefiApes.ownerOf(tokenId), 'Only TBCC DEFI APES NFT holder');
        _;
    }

    /// @param _tft The TFT token contract address.
    constructor(
        ITFT _tft,
        ITBCCDEFIAPES _tbccDefiApes,
        uint256 _tftPerBlock,
        uint256 _startBlock,
        uint256 _claimAmount
    ) public {
        tft = _tft;
        tftPerBlock = _tftPerBlock;
        startBlock = _startBlock;
        tbccDefiApes = _tbccDefiApes;
        claimAmount = _claimAmount;
        bonuses.push(BonusInfo(_startBlock, 100));
    }

    /**
     * @notice Returns the number of TBCCMCV pools.
     *
     */
    function poolLength() external view returns (uint256 pools) {
        pools = poolInfo.length;
    }

    /**
     * @notice Add a new pool. Can only be called by the owner.
     * DO NOT add the same LP token more than once. Rewards will be messed up if you do.
     * @param _allocPoint: Number of allocation points for the new pool.
     * @param _lpToken: Address of the LP BEP-20 token.
     * @param _rewarder: Address of the rewarder delegate.
     *
     * @dev Callable by owner
     *
     */
    function add(
        uint256 _allocPoint,
        IBEP20 _lpToken,
        IRewarder _rewarder
    ) external onlyOwner {
        require(_lpToken.balanceOf(address(this)) >= 0, "None BEP20 tokens");
        // stake TFT token will cause staked token and reward token mixed up,
        // may cause staked tokens withdraw as reward token,never do it.
        require(address(_lpToken) != address(tft), "TFT token can't be added to farm pools");

        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        lpToken.push(_lpToken);
        rewarder.push(_rewarder);

        poolInfo.push(
            PoolInfo({
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accTFTPerShare: 0
            })
        );
        emit LogPoolAddition(lpToken.length.sub(1), _allocPoint, _lpToken, _rewarder);
    }

    /**
     * @notice Update the given pool's TFT allocation point. Can only be called by the owner.
     * @param _pid: The id of the pool. See `poolInfo`.
     * @param _allocPoint: New number of allocation points for the pool.
     * @param _rewarder: Address of the rewarder delegate.
     * @param _overwrite: True if _rewarder should be `set`. Otherwise `_rewarder` is ignored.
     *
     * @dev Callable by owner
     *
     */
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        IRewarder _rewarder,
        bool _overwrite
    ) external onlyOwner {
        require(_pid < lpToken.length, "TBCCMasterChef: pid is not found");

        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;

        if (_overwrite) {
            rewarder[_pid] = _rewarder;
        }

        emit LogSetPool(_pid, _allocPoint, _overwrite ? _rewarder : rewarder[_pid], _overwrite);
    }

    /**
     * @notice Set the `migrator` contract. Can only be called by the owner.
     * @param _migrator: The contract address to set.
     *
     */
    function setMigrator(
        IMigratorChef _migrator
    ) external onlyOwner {
        migrator = _migrator;
    }

    /**
     * @notice Migrate LP token to another LP contract through the `migrator` contract.
     * @param _pid: The index of the pool. See `poolInfo`.
     *
     */
    function migrate(
        uint256 _pid
    ) external {
        require(address(migrator) != address(0), "TBCCMasterChef: no migrator set");
        require(_pid < lpToken.length, "TBCCMasterChef: pid is not found");

        IBEP20 _lpToken = lpToken[_pid];
        uint256 bal = _lpToken.balanceOf(address(this));
        _lpToken.approve(address(migrator), bal);

        IBEP20 newLpToken = migrator.migrate(_lpToken);
        require(bal == newLpToken.balanceOf(address(this)), "TBCCMasterChef: migrated balance must match");
        lpToken[_pid] = newLpToken;
    }

    /**
     * @notice Return reward multiplier over the given _from to _to block.
     * @param _from: Start block
     * @param _to: End Block
     *
     */
    function getMultiplier(
        uint256 _from,
        uint256 _to
    ) public view returns (uint256) {
        uint256 totalBonus;

        for (uint i; i < bonuses.length; i++) {
            uint256 stageBonus;
            if (i == bonuses.length - 1) {
                if (_from >= bonuses[i].startBlock && _to >= bonuses[i].startBlock) {
                    stageBonus = _to.sub(_from).mul(bonuses[i].bonus).div(100);
                } else if (_from < bonuses[i].startBlock && _to >= bonuses[i].startBlock) {
                    stageBonus = _to.sub(bonuses[i].startBlock).mul(bonuses[i].bonus).div(100);
                } else {
                    stageBonus = 0;
                }
            } else {
                if (_from < bonuses[i].startBlock) {
                    if (_to < bonuses[i].startBlock) {
                        stageBonus = 0;
                    } else if (_to < bonuses[i + 1].startBlock) {
                        stageBonus = _to.sub(bonuses[i].startBlock).mul(bonuses[i].bonus).div(100);
                    } else {
                        stageBonus = bonuses[i + 1].startBlock.sub(bonuses[i].startBlock).mul(bonuses[i].bonus).div(100);
                    }
                } else if (_from >= bonuses[i + 1].startBlock) {
                    stageBonus = 0;
                } else {
                    if (_to < bonuses[i].startBlock) {
                        stageBonus = 0;
                    } else if (_to < bonuses[i + 1].startBlock) {
                        stageBonus = _to.sub(_from).mul(bonuses[i].bonus).div(100);
                    } else {
                        stageBonus = bonuses[i + 1].startBlock.sub(_from).mul(bonuses[i].bonus).div(100);
                    }
                }
            }

            totalBonus = totalBonus.add(stageBonus);
        }

        return totalBonus;
    }

    /**
     * @notice View function for checking pending TFT rewards.
     * @param _pid: The id of the pool. See `poolInfo`.
     * @param _user: Address of the user.
     *
     */
    function pendingReward(
        uint256 _pid,
        address _user
    ) external view returns (uint256 pending) {
        require(_pid < lpToken.length, "TBCCMasterChef: pid is not found");

        PoolInfo memory pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accTFTPerShare = pool.accTFTPerShare;
        uint256 lpSupply = lpToken[_pid].balanceOf(address(this));

        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);

            uint256 tftReward = multiplier.mul(tftPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accTFTPerShare = accTFTPerShare.add(tftReward.mul(ACC_TFT_PRECISION).div(lpSupply));
        }

        pending = user.amount.mul(accTFTPerShare).div(ACC_TFT_PRECISION).sub(user.rewardDebt);
    }

    /**
     * @notice Update reward variables for the given pool.
     * @param _pid: The id of the pool. See `poolInfo`.
     *
     */
    function updatePool(
        uint256 _pid
    ) public returns (PoolInfo memory pool) {
        require(_pid < lpToken.length, "TBCCMasterChef: pid is not found");

        pool = poolInfo[_pid];

        if (block.number > pool.lastRewardBlock) {
            uint256 lpSupply = lpToken[_pid].balanceOf(address(this));
            if (lpSupply > 0) {
                uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
                uint256 tftReward = multiplier.mul(tftPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
                pool.accTFTPerShare = pool.accTFTPerShare.add(
                    tftReward.mul(ACC_TFT_PRECISION).div(lpSupply)
                );
                tft.mint(address(this), tftReward);
            }
            pool.lastRewardBlock = block.number;
            poolInfo[_pid] = pool;
            emit LogUpdatePool(_pid, pool.lastRewardBlock, lpSupply, pool.accTFTPerShare);
        }
    }

    /**
     * @notice Update reward variables for all pools. Be careful of gas spending!
     *
     */
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo memory pool = poolInfo[pid];
            if (pool.allocPoint != 0) {
                updatePool(pid);
            }
        }
    }

    /**
     * @notice Deposit LP tokens to pool.
     * @param _pid: The id of the pool. See `poolInfo`.
     * @param _amount: Amount of LP tokens to deposit.
     * @param _to: The receiver of `amount` deposit benefit.
     *
     */
    function deposit(
        uint256 _pid,
        uint256 _amount,
        address _to
    ) external nonReentrant {
        require(_pid < lpToken.length, "TBCCMasterChef: pid is not found");

        PoolInfo memory pool = updatePool(_pid);
        UserInfo storage user = userInfo[_pid][_to];
        updatePool(_pid);
        // Effects
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.rewardDebt.add(_amount.mul(pool.accTFTPerShare).div(ACC_TFT_PRECISION));

        // Interactions
        IRewarder _rewarder = rewarder[_pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onTFTReward(_pid, _to, _to, 0, user.amount);
        }

        lpToken[_pid].safeTransferFrom(msg.sender, address(this), _amount);

        emit Deposit(msg.sender, _pid, _amount, _to);
    }

    /**
     * @notice Withdraw LP tokens from pool.
     * @param _pid: The id of the pool. See `poolInfo`.
     * @param _amount: Amount of LP tokens to withdraw.
     * @param _to: Receiver of the LP tokens.
     *
     */
    function withdraw(
        uint256 _pid,
        uint256 _amount,
        address _to
    ) external nonReentrant {
        require(_pid < lpToken.length, "TBCCMasterChef: pid is not found");

        PoolInfo memory pool = updatePool(_pid);
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);

        uint256 accumulatedTFT = user.amount.mul(pool.accTFTPerShare).div(ACC_TFT_PRECISION);
        uint256 _pendingTFT = accumulatedTFT.sub(user.rewardDebt);

        // Effects
        user.rewardDebt = accumulatedTFT.sub(_amount.mul(pool.accTFTPerShare).div(ACC_TFT_PRECISION));
        user.amount = user.amount.sub(_amount);

        // Interactions
        tft.transfer(_to, _pendingTFT);

        IRewarder _rewarder = rewarder[_pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onTFTReward(_pid, msg.sender, _to, _pendingTFT, user.amount);
        }

        lpToken[_pid].safeTransfer(_to, _amount);

        emit Withdraw(msg.sender, _pid, _amount, _to);
        emit Harvest(msg.sender, _pid, _pendingTFT);
    }

    /**
     * @notice Harvest proceeds for transaction sender to `to`.
     * @param _pid: The index of the pool. See `poolInfo`.
     * @param _to: Receiver of the TFT rewards.
     *
     */
    function harvest(
        uint256 _pid,
        address _to
    ) external {
        require(_pid < lpToken.length, "TBCCMasterChef: pid is not found");

        PoolInfo memory pool = updatePool(_pid);
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        uint256 accumulatedTFT = user.amount.mul(pool.accTFTPerShare).div(ACC_TFT_PRECISION);
        uint256 _pendingTFT = accumulatedTFT.sub(user.rewardDebt);

        // Effects
        user.rewardDebt = accumulatedTFT;

        // Interactions
        if (_pendingTFT != 0) {
            tft.transfer(_to, _pendingTFT);
        }

        IRewarder _rewarder = rewarder[_pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onTFTReward(_pid, msg.sender, _to, _pendingTFT, user.amount);
        }

        emit Harvest(msg.sender, _pid, _pendingTFT);
    }

    /**
     * @notice Withdraw without caring about the rewards. EMERGENCY ONLY.
     * @param _pid: The id of the pool. See `poolInfo`.
     * @param _to: Receiver of the LP tokens.
     *
     */
    function emergencyWithdraw(
        uint256 _pid,
        address _to
    ) external nonReentrant {
        require(_pid < lpToken.length, "TBCCMasterChef: pid is not found");

        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;

        IRewarder _rewarder = rewarder[_pid];
        if (address(_rewarder) != address(0)) {
            _rewarder.onTFTReward(_pid, msg.sender, _to, 0, 0);
        }

        // Note: transfer can fail or succeed if `amount` is zero.
        lpToken[_pid].safeTransfer(_to, amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount, _to);
    }

    /**
     * @notice Add new bonus
     * @param _startBlock: New TFT per block
     *
     * @dev Callable by owner
     *
     */
    function addNewBonus(
        uint256 _startBlock,
        uint256 _bonus
    ) external onlyOwner {
        bonuses.push(BonusInfo(_startBlock, _bonus));
        massUpdatePools();
        emit AddNewBonus(_startBlock, _bonus);
    }

    /**
     * @notice It transfers the ownership of the TFT contract to a new address.
     * @param _newOwner: New TFT owner
     *
     * @dev Callable by owner
     *
     */
    function changeOwnershipTFTContract(
        address _newOwner
    ) external onlyOwner {
        tft.transferOwnership(_newOwner);
    }

    /**
     * @notice Claiming TFT per TDA
     * @param _tokenId: New TFT owner
     *
     * @dev Callable by NFT TDA Holder
     *
     */
    function apesClaim(
        uint256 _tokenId
    ) external onlyNFTTDAHolder(msg.sender, _tokenId) {
        require(tdaClaimed[_tokenId] == address(0), "TBCCMasterChef: TBCC TDA already claimed");

        // Interactions
        tdaClaimed[_tokenId] = msg.sender;
        tft.mint(msg.sender, claimAmount);
        emit NFTTDAClaimed(msg.sender, _tokenId, claimAmount);
    }

    /**
     * @notice Setting Claim amount for TFT per TDA
     * @param _newAmount: New TFT amount
     *
     * @dev Callable by owner
     *
     */
    function setApesClaimAmount(
        uint256 _newAmount
    ) external onlyOwner {
        claimAmount = _newAmount;
        emit NewClaimApesAmount(_newAmount);
    }
}