/**
 * @author Musket
 */
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@positionex/posi-token/contracts/VestingScheduleBase.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@positionex/matching-engine/contracts/interfaces/IMatchingEngineAMM.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../interfaces/IPositionNondisperseLiquidity.sol";
import "../libraries/helper/U128Math.sol";
import "../libraries/liquidity/Liquidity.sol";
import "../libraries/types/PositionStakingDexManagerStorage.sol";

contract PositionStakingDexManager is
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    VestingScheduleBase,
    PositionStakingDexManagerStorage
{
    using SafeMath for uint256;
    using U128Math for uint128;

    event Deposit(address indexed user, address indexed pid, uint256 amount);
    event Withdraw(address indexed user, address indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        address indexed pid,
        uint256 amount
    );
    event EmissionRateUpdated(
        address indexed caller,
        uint256 previousAmount,
        uint256 newAmount
    );
    event ReferralCommissionPaid(
        address indexed user,
        address indexed referrer,
        uint256 commissionAmount
    );
    event RewardLockedUp(
        address indexed user,
        address indexed pid,
        uint256 amountLockedUp
    );
    event NFTReceived(
        address operator,
        address from,
        uint256 tokenId,
        bytes data
    );

    function initialize(
        IERC20 _position,
        IPositionNondisperseLiquidity _positionLiquidityManager,
        uint256 _startBlock
    ) external initializer {
        __ReentrancyGuard_init();
        __Ownable_init();

        position = _position;
        startBlock = _startBlock;

        positionNondisperseLiquidity = _positionLiquidityManager;

        devAddress = _msgSender();
        feeAddress = _msgSender();

        referralCommissionRate = 100;
        MAXIMUM_REFERRAL_COMMISSION_RATE = 1000;

        harvestFeeShareRate = 1;

        BONUS_MULTIPLIER = 1;

        MAXIMUM_HARVEST_INTERVAL = 14 days;

        totalAllocPoint = 0;
    }

    function poolLength() external view returns (uint256) {
        return pools.length;
    }

    //    // get position per block form the staking manager share to the contract

    function getPlayerIds(address owner, address pid)
        public
        view
        returns (uint256[] memory)
    {
        return userNft[owner][pid];
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public returns (bytes4) {
        emit NFTReceived(operator, from, tokenId, data);
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

    //------------------------------------------------------------------------------------------------------------------
    // ONLY_OWNER FUNCTIONS
    //------------------------------------------------------------------------------------------------------------------

    function setPositionPerBlock(uint256 _positionPerBlock) public onlyOwner {
        massUpdatePools();
        positionPerBlock = _positionPerBlock;
    }

    function setPositionTreasury(IPosiTreasury _posiTreasury) public onlyOwner {
        posiTreasury = _posiTreasury;
    }

    function setPositionEarningToken(IERC20 _positionEarningToken)
        public
        onlyOwner
    {
        position = _positionEarningToken;
    }

    function updatePositionLiquidityPool(address _newLiquidityPool)
        public
        onlyOwner
    {
        positionNondisperseLiquidity = IPositionNondisperseLiquidity(
            _newLiquidityPool
        );
    }

    function updateHarvestFeeShareRate(uint16 newRate) public onlyOwner {
        // max share 10%
        require(newRate <= 1000, "!F");
        harvestFeeShareRate = newRate;
    }

    function setPosiStakingPid(uint256 _posiStakingPid) public onlyOwner {
        posiStakingPid = _posiStakingPid;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        address _poolId,
        uint256 _allocPoint,
        uint16 _depositFeeBP,
        uint128 _harvestInterval,
        bool _withUpdate
    ) public onlyOwner {
        require(
            _depositFeeBP <= 10000,
            "add: invalid deposit fee basis points"
        );
        require(
            _harvestInterval <= MAXIMUM_HARVEST_INTERVAL,
            "add: invalid harvest interval"
        );
        require(poolInfo[_poolId].poolId == address(0x00), "pool created");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        pools.push(_poolId);
        poolInfo[_poolId] = PoolInfo({
            poolId: _poolId,
            totalStaked: 0,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accPositionPerShare: 0,
            depositFeeBP: _depositFeeBP,
            harvestInterval: _harvestInterval
        });
    }

    // Update the given pool's Position allocation point and deposit fee. Can only be called by the owner.
    function set(
        address _pid,
        uint256 _allocPoint,
        uint16 _depositFeeBP,
        uint128 _harvestInterval,
        bool _withUpdate
    ) public onlyOwner {
        require(
            _depositFeeBP <= 10000,
            "set: invalid deposit fee basis points"
        );
        require(
            _harvestInterval <= MAXIMUM_HARVEST_INTERVAL,
            "set: invalid harvest interval"
        );
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
        poolInfo[_pid].harvestInterval = _harvestInterval;
    }

    // Update dev address by the previous dev.
    function setDevAddress(address _devAddress) public onlyOwner {
        require(_msgSender() == devAddress, "setDevAddress: FORBIDDEN");
        require(_devAddress != address(0), "setDevAddress: ZERO");
        devAddress = _devAddress;
    }

    function setFeeAddress(address _feeAddress) public onlyOwner {
        require(_msgSender() == feeAddress, "setFeeAddress: FORBIDDEN");
        require(_feeAddress != address(0), "setFeeAddress: ZERO");
        feeAddress = _feeAddress;
    }

    // Update the position referral contract address by the owner
    function setPositionReferral(IPositionReferral _positionReferral)
        public
        onlyOwner
    {
        positionReferral = _positionReferral;
    }

    // Update referral commission rate by the owner
    function setReferralCommissionRate(uint16 _referralCommissionRate)
        public
        onlyOwner
    {
        require(
            _referralCommissionRate <= MAXIMUM_REFERRAL_COMMISSION_RATE,
            "setReferralCommissionRate: invalid referral commission rate basis points"
        );
        referralCommissionRate = _referralCommissionRate;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending Positions on frontend.
    function pendingPosition(address _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];
        uint256 accPositionPerShare = pool.accPositionPerShare;
        uint256 lpSupply = pool.totalStaked;
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                block.number
            );
            uint256 positionReward = multiplier
                .mul(positionPerBlock)
                .mul(pool.allocPoint)
                .div(totalAllocPoint);
            accPositionPerShare = accPositionPerShare.add(
                positionReward.mul(1e12).div(lpSupply)
            );
        }
        uint256 pending = user.amount.mul(accPositionPerShare).div(1e12).sub(
            user.rewardDebt
        );
        return pending.add(user.rewardLockedUp);
    }

    // View function to see if user can harvest Positions.
    function canHarvest(address _pid, address _user)
        public
        view
        returns (bool)
    {
        UserInfo memory user = userInfo[_pid][_user];
        return block.timestamp >= user.nextHarvestUntil;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = pools.length;
        for (uint256 i = 0; i < length; ++i) {
            updatePool(pools[i]);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(address _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        // SLOAD
        PoolInfo memory _pool = pool;
        if (block.number <= _pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = _pool.totalStaked;
        if (lpSupply == 0 || _pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 positionReward = multiplier
            .mul(positionPerBlock)
            .mul(pool.allocPoint)
            .div(totalAllocPoint);

        stakingMinted = stakingMinted.add(
            positionReward.add(positionReward.div(10))
        );
        posiTreasury.mint(address(this), positionReward);
        // transfer 10% to the dev wallet
        posiTreasury.mint(devAddress, positionReward.div(10));
        pool.accPositionPerShare = pool.accPositionPerShare.add(
            positionReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    function stakeAfterMigrate(uint256 nftId, address user ) public {
        _stake(nftId, address(0), user);
    }

    // Deposit LP tokens to PosiStakingManager for Position allocation.
    function stake(uint256 _nftId) public nonReentrant {
        _stake(_nftId, address(0), _msgSender());
    }

    function stakeWithReferral(uint256 _nftId, address _referrer)
        public
        nonReentrant
    {
        _stake(_nftId, _referrer, _msgSender());
    }

    // Withdraw LP tokens from PosiStakingManager.
    function unstake(uint256 _nftId) public nonReentrant {
        _unstake(_nftId, _msgSender());
    }

    function withdraw(address pid) public nonReentrant {
        _withdraw(pid, _msgSender());
    }

    function harvest(address pid) public nonReentrant {
        _harvest(pid, _msgSender());
    }

    function exit(address pid) external nonReentrant {
        _withdraw(pid, _msgSender());
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(address _pid) public nonReentrant {
        UserInfo storage user = userInfo[_pid][_msgSender()];
        user.amount = 0;
        user.rewardDebt = 0;
        user.rewardLockedUp = 0;
        user.nextHarvestUntil = 0;
        uint256[] memory nfts = userNft[_msgSender()][_pid];
        for (uint8 index = 1; index < nfts.length; index++) {
            uint256 _nftId = nfts[index];
            if (_nftId > 0) {
                _transferNFTOut(_nftId);
                emit EmergencyWithdraw(_msgSender(), _pid, _nftId);
            }
        }
    }

    function _stake(
        uint256 _nftId,
        address _referrer,
        address userAddress
    ) internal {
        UserLiquidity.Data memory nftData = _getLiquidityData(_nftId);
        address poolAddress = address(nftData.pool);
        require(
            poolInfo[poolAddress].poolId != address(0x00),
            "pool not created"
        );
        require(poolAddress != address(0x0), "invalid liquidity pool");

        PoolInfo storage pool = poolInfo[poolAddress];
        UserInfo storage user = userInfo[poolAddress][userAddress];
        updatePool(poolAddress);
        if (
            nftData.liquidity > 0 &&
            address(positionReferral) != address(0) &&
            _referrer != address(0) &&
            _referrer != userAddress
        ) {
            positionReferral.recordReferral(userAddress, _referrer);
        }
        _payOrLockupPendingPosition(poolAddress, _msgSender());
        _transferNFTIn(_nftId);
        uint128 power = _calculatePower(
            nftData.indexedPipRange,
            uint32(nftData.pool.currentIndexedPipRange()),
            nftData.liquidity
        );

        user.amount = user.amount.add(power);
        user.rewardDebt = uint128(
            user.amount.mul(pool.accPositionPerShare).div(1e12)
        );
        pool.totalStaked += power;

        uint256[] storage nftIds = userNft[userAddress][poolAddress];
        if (nftIds.length == 0) {
            nftIds.push(0);
            nftOwnedIndex[0][poolAddress] = 0;
        }
        nftIds.push(_nftId);
        nftOwnedIndex[_nftId][poolAddress] = nftIds.length - 1;
        emit Deposit(userAddress, poolAddress, _nftId);
    }

    function _unstake(uint256 _nftId, address _userAddress) internal {
        UserLiquidity.Data memory nftData = _getLiquidityData(_nftId);
        address poolAddress = address(nftData.pool);

        PoolInfo storage pool = poolInfo[poolAddress];
        UserInfo storage user = userInfo[poolAddress][_userAddress];

        //        require(user.amount >= nftData.liquidity, "withdraw: not good");

        updatePool(poolAddress);

        _payOrLockupPendingPosition(poolAddress, _userAddress);

        uint128 power = _calculatePower(
            nftData.indexedPipRange,
            uint32(nftData.pool.currentIndexedPipRange()),
            nftData.liquidity
        );
        user.amount = user.amount.sub(power);
        _transferNFTOut(_nftId);

        user.rewardDebt = uint128(
            user.amount.mul(pool.accPositionPerShare).div(1e12)
        );
        pool.totalStaked -= power;
        _removeNftFromUser(_nftId, poolAddress, _userAddress);

        emit Withdraw(_userAddress, poolAddress, _nftId);
    }

    function _withdraw(address pid, address _userAddress) internal {
        uint256[] memory nfts = userNft[_userAddress][pid];

        for (uint8 index = 1; index < nfts.length; index++) {
            if (nfts[index] > 0) {
                _unstake(nfts[index], _userAddress);
            }
        }
    }

    function _harvest(address pid, address _userAddress) internal {
        UserInfo storage user = userInfo[pid][_userAddress];
        require(user.amount > 0, "No nft staked");
        updatePool(pid);
        _payOrLockupPendingPosition(pid, _userAddress);
        user.rewardDebt = uint128(
            user.amount.mul(poolInfo[pid].accPositionPerShare).div(1e12)
        );
    }

    // Pay or lockup pending Positions.
    function _payOrLockupPendingPosition(address _pid, address _user) internal {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        if (user.nextHarvestUntil == 0) {
            user.nextHarvestUntil =
                uint128(block.timestamp) +
                pool.harvestInterval;
        }

        uint256 pending = user
            .amount
            .mul(pool.accPositionPerShare)
            .div(1e12)
            .sub(user.rewardDebt);
        if (canHarvest(_pid, _user)) {
            if (pending > 0 || user.rewardLockedUp > 0) {
                uint256 totalRewards = pending.add(user.rewardLockedUp);

                // reset lockup
                totalLockedUpRewards = totalLockedUpRewards.sub(
                    user.rewardLockedUp
                );
                user.rewardLockedUp = 0;
                user.nextHarvestUntil =
                    uint128(block.timestamp) +
                    pool.harvestInterval;

                // send rewards
                _safePositionTransfer(_user, totalRewards);
                _payReferralCommission(_user, totalRewards);
            }
        } else if (pending > 0) {
            user.rewardLockedUp = uint128(
                user.rewardLockedUp.add(uint128(pending))
            );
            totalLockedUpRewards = totalLockedUpRewards.add(pending);
            emit RewardLockedUp(_user, _pid, pending);
        }
        _updatePower(_user, _pid);
    }

    function _removeNftFromUser(
        uint256 _nftId,
        address _pid,
        address _userAddress
    ) internal {
        uint256[] memory _nftIds = userNft[_userAddress][_pid];
        uint256 nftIndex = nftOwnedIndex[_nftId][_pid];
        require(_nftIds[nftIndex] == _nftId, "not gegoId owner");
        uint256 _nftArrLength = _nftIds.length - 1;
        uint256 tailId = _nftIds[_nftArrLength];
        userNft[_userAddress][_pid][nftIndex] = tailId;
        userNft[_userAddress][_pid][_nftArrLength] = 0;
        userNft[_userAddress][_pid].pop();
        nftOwnedIndex[tailId][_pid] = nftIndex;
        nftOwnedIndex[_nftId][_pid] = 0;
    }

    // Safe position transfer function, just in case if rounding error causes pool to not have enough Positions.
    function _safePositionTransfer(address _to, uint256 _amount) internal {
        uint256 positionBal = position.balanceOf(address(this));
        if (_amount > positionBal) {
            _amount = positionBal;
        }
        if (_isWhitelistVesting(_msgSender())) {
            position.transfer(_to, _amount);
        } else {
            // receive 5%
            position.transfer(_to, (_amount * 5) / 100);
            _addSchedules(_to, _amount);
        }
    }

    function isOwnerWhenStaking(address user, uint256 nftId)
        external
        view
        returns (bool, address)
    {
        UserLiquidity.Data memory nftData = _getLiquidityData(nftId);
        uint256 indexNftId = nftOwnedIndex[nftId][address(nftData.pool)];
        return (
            userNft[user][address(nftData.pool)][indexNftId] == nftId,
            _msgSender()
        );
    }

    function updateStakingLiquidity(
        address user,
        uint256 tokenId,
        address poolId,
        uint128 deltaLiquidityModify,
        IPositionNondisperseLiquidity.ModifyType modifyType
    ) external returns (address caller) {
        require(
            _msgSender() == address(positionNondisperseLiquidity),
            "only concentrated liquidity"
        );
        updatePool(poolId);
        _payOrLockupPendingPosition(poolId, user);
        userInfo[poolId][user].rewardDebt = uint128(
            userInfo[poolId][user]
                .amount
                .mul(poolInfo[poolId].accPositionPerShare)
                .div(1e12)
        );
        if (positionNondisperseLiquidity.ownerOf(tokenId) == address(this)) {}
        return _msgSender();
    }

    // Pay referral commission to the referrer who referred this user.
    function _payReferralCommission(address _user, uint256 _pending) internal {
        if (
            address(positionReferral) != address(0) &&
            referralCommissionRate > 0
        ) {
            address referrer = positionReferral.getReferrer(_user);
            uint256 commissionAmount = _pending.mul(referralCommissionRate).div(
                10000
            );

            if (referrer != address(0) && commissionAmount > 0) {
                if (position.balanceOf(address(this)) < commissionAmount) {
                    posiTreasury.mint(address(this), commissionAmount);
                }
                position.transfer(referrer, commissionAmount);
                positionReferral.recordReferralCommission(
                    referrer,
                    commissionAmount
                );
                emit ReferralCommissionPaid(_user, referrer, commissionAmount);
            }
        }
    }

    function _transferNFTOut(uint256 id) internal {
        positionNondisperseLiquidity.safeTransferFrom(
            address(this),
            _msgSender(),
            id
        );
    }

    function _transferNFTIn(uint256 id) internal {
        positionNondisperseLiquidity.safeTransferFrom(
            _msgSender(),
            address(this),
            id
        );
    }

    function _transferLockedToken(address _to, uint192 _amount)
        internal
        override
    {
        position.transfer(_to, _amount);
    }

    function _getLiquidityData(uint256 tokenId)
        internal
        view
        returns (UserLiquidity.Data memory data)
    {
        (
            data.liquidity,
            data.indexedPipRange,
            data.feeGrowthBase,
            data.feeGrowthQuote,
            data.pool
        ) = positionNondisperseLiquidity.concentratedLiquidity(tokenId);
    }

    function _calculatePower(
        uint32 indexedPipRangeNft,
        uint32 currentIndexedPipRange,
        uint256 liquidity
    ) internal pure returns (uint128 power) {
        if (indexedPipRangeNft > currentIndexedPipRange) {
            power = uint128(
                liquidity / ((indexedPipRangeNft - currentIndexedPipRange) + 1)
            );
        } else {
            power = uint128(
                liquidity / ((currentIndexedPipRange - indexedPipRangeNft) + 1)
            );
        }
    }

    function _updatePower(address user, address pid)
        internal
        returns (uint128 totalPower)
    {
        uint256[] memory _userNfts = userNft[user][pid];

        UserLiquidity.Data memory nftData;
        uint32 currentIndexedPipRange = uint32(
            IMatchingEngineAMM(pid).currentIndexedPipRange()
        );
        poolInfo[pid].totalStaked -= userInfo[pid][user].amount;

        for (uint256 i = 0; i < _userNfts.length; i++) {
            nftData = _getLiquidityData(_userNfts[i]);
            totalPower += _calculatePower(
                nftData.indexedPipRange,
                currentIndexedPipRange,
                nftData.liquidity
            );
        }
        userInfo[pid][user].amount = totalPower;
        poolInfo[pid].totalStaked += totalPower;
    }
}