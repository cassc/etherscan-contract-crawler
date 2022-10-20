/************************************************************
 *
 * Autor: BotPlanet
 *
 * 446576656c6f7065723a20416e746f6e20506f6c656e79616b61 ****/

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract BotdexStaking is AccessControl, ReentrancyGuard {
    PoolInfo[] public pools;

    address public token;
    address public rewardKeeper;

    uint256 constant PROCENT_BASE = 1000;
    uint256 constant YEAR = 365 days;

    mapping(address => mapping(uint256 => UserInfo)) public userAtPoolInfo; // UserInfo for address and index

    struct UserInfo {
        uint256 amount; // amount of staked tokens
        uint256 start; // time when user made stake
    }

    struct PoolInfo {
        uint256 amountStaked; // amount staked at this pool
        uint256 timeLockUp; // time of lock up
        uint16 APY; // necessary apy
        bool isDead;
    }

    event StakeTokenForUser(
        address investor,
        uint256 amount,
        uint256 poolId,
        uint256 start
    );

    event GetRewardForUser(
        address investor,
        uint256 poolId,
        uint256 amount,
        uint256 timeGotReward
    );

    modifier onlyForAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Staking: have no rights"
        );
        _;
    }

    constructor(
        address _token,
        address _rewardKeeper,
        uint256[4] memory _timeLockUp,
        uint16[4] memory _APY
    ) {
        require(_token != address(0), "zero address!");
        token = _token;
        rewardKeeper = _rewardKeeper;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        PoolInfo memory _pool;
        for (uint256 i = 0; i < 4; i++) {
            _pool = PoolInfo(0, _timeLockUp[i], _APY[i], false);
            pools.push(_pool);
        }
    }

    function getPoolLength() external view returns (uint256) {
        return pools.length;
    }

    function addStakingPool(uint256 _timeLockUp, uint16 _APY)
        external
        onlyForAdmin
    {
        PoolInfo memory _pool = PoolInfo(0, _timeLockUp, _APY, false);
        pools.push(_pool);
    }

    function changePoolVisability(uint256 _poolId) external onlyForAdmin {
        pools[_poolId].isDead = !pools[_poolId].isDead;
    }

    function enterStaking(uint256 _poolId, uint256 _amount)
        external
        nonReentrant
    {
        require(_poolId <= pools.length - 1, "Staking: wrong pool");
        require(
            pools[_poolId].isDead == false,
            "Staking: this pool is unavailable"
        );
        uint256 reward = _calculateReward(_poolId, _amount);
        require(
            IERC20(token).balanceOf(rewardKeeper) >= reward,
            "Staking: there is no reward for you, sorry. Come back later!"
        );
        IERC20(token).transferFrom(rewardKeeper, address(this), reward);
        address investor = _msgSender();
        PoolInfo storage currentPool = pools[_poolId];
        userAtPoolInfo[investor][_poolId].amount += _amount;
        userAtPoolInfo[investor][_poolId].start = block.timestamp;

        currentPool.amountStaked += _amount;
        require(
            IERC20(token).transferFrom(investor, address(this), _amount),
            "Vesting: tokens didn`t transfer"
        );
        emit StakeTokenForUser(investor, _amount, _poolId, block.timestamp);
    }

    function withdrawReward(uint256 _poolId) external nonReentrant {
        UserInfo storage userInfo = userAtPoolInfo[_msgSender()][_poolId];
        require(userInfo.amount > 0, "Staking: user has no staked tokens");
        require(
            block.timestamp - userInfo.start >= pools[_poolId].timeLockUp,
            "Staking: wait till the end of lock time"
        );
        uint256 amount = _calculateReward(_poolId, userInfo.amount) +
            userInfo.amount;
        userInfo.amount = 0;
        userInfo.start = 0;
        require(
            IERC20(token).transfer(_msgSender(), amount),
            "Staking: tokens didn`t transfer"
        );

        emit GetRewardForUser(_msgSender(), _poolId, amount, block.timestamp);
    }

    function calculateReward(uint256 _poolId, address from)
        public
        view
        returns (uint256 rewardAmount)
    {
        UserInfo storage userInfo = userAtPoolInfo[from][_poolId];
        rewardAmount =
            (userInfo.amount * pools[_poolId].APY * pools[_poolId].timeLockUp) /
            (PROCENT_BASE * YEAR);
    }

    function _calculateReward(uint256 _poolId, uint256 _amount)
        internal
        view
        returns (uint256 rewardAmount)
    {
        rewardAmount =
            (_amount * pools[_poolId].APY * pools[_poolId].timeLockUp) /
            (PROCENT_BASE * YEAR);
    }
}