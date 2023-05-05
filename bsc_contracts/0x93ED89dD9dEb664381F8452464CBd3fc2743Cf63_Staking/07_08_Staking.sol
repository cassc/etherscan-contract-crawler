// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {ULFX} from "./Token.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

struct Period {
    uint256 start;
    uint256 end;
    mapping(address => uint256) stakes;
    uint256 totalStaked;
}

struct Pool {
    uint256 blockDuration;
    uint256 blockReward;
    Period[] periods;
}

struct UserDeposit {
    uint256 poolId;
    uint256 period;
}

/**
 * @title Staking
 * @dev All error are reverted with custom errors, if not stated otherwise.
 * Staking contract for ULFPAD token.
 *
 * @custom:constructor-param MINTING_CAP Maximum amount of tokens that can be minted in total, during the lifetime of the contract.
 * @custom:constructor-param CLAIM_PERIOD Period in which users can claim their rewards.
 */
contract Staking is Ownable {
    bool initialized = false;
    ULFX internal Token;

    uint256 internal immutable MINTING_CAP;
    uint256 internal immutable CLAIM_PERIOD;

    bool internal DECOMISISONED = false;
    uint256 internal MINTED = 0;

    Pool[] internal pools;
    // save user deposits for easy access, without backend services
    mapping(address => UserDeposit[]) internal userDeposits;

    error NotInitialized();
    error ContractDecomissioned();
    error AlreadyInitialized();
    error NonExistantPool();
    error PeriodNotStarted();
    error TokenTransferFailed();
    error StakingFinished();
    error PoolIsLocked();

    error ClaimBeforePeriodEnd();
    error AlreadyClaimed();
    error ClaimPeriodActive();

    modifier isInitialized() {
        if (!initialized) revert NotInitialized();
        _;
    }

    event PoolCreated(uint256 _id);
    event Deposited(
        uint256 indexed poolId,
        address indexed user,
        uint256 amount
    );
    event Claimed(
        uint256 indexed poolId,
        address indexed user,
        uint256 amount,
        bool indexed expired
    );
    event PeriodStarted(uint256 indexed poolId, uint256 periodId);
    event PeriodEnded(uint256 indexed poolId, uint256 periodId);

    constructor(uint256 _mintingCap, uint256 _claimPeriod) Ownable() {
        MINTING_CAP = _mintingCap;
        CLAIM_PERIOD = _claimPeriod;
    }

    /**
     * @dev Initialize staking contract.
     * @param _token Staking token address.
     */
    function initialize(address _token) external onlyOwner {
        if (initialized) revert AlreadyInitialized();
        initialized = true;
        Token = ULFX(_token);
    }

    function createPool(
        uint256 _blockDuration,
        uint256 _blockReward
    ) external onlyOwner isInitialized {
        if (DECOMISISONED) revert ContractDecomissioned();
        if (MINTED >= MINTING_CAP) revert StakingFinished();

        // create and initialize pool
        uint256 poolId = pools.length;
        pools.push();

        Pool storage pool = pools[poolId];

        pool.blockDuration = _blockDuration;
        pool.blockReward = _blockReward;

        // create and initialize first period
        uint256 periodId = pool.periods.length;
        pool.periods.push();

        Period storage period = pool.periods[periodId];

        period.start = block.timestamp;
        period.end = block.timestamp + _blockDuration;

        emit PeriodStarted(poolId, periodId);
        emit PoolCreated(poolId);
    }

    function deposit(uint256 _poolId, uint256 _amount) external isInitialized {
        if (DECOMISISONED) revert ContractDecomissioned();
        if (MINTED >= MINTING_CAP) revert StakingFinished();
        if (_poolId >= pools.length) revert NonExistantPool();

        Pool storage pool = pools[_poolId];
        Period storage period = pool.periods[pool.periods.length - 1];

        // if period has ended
        if (period.end < block.timestamp) {
            // create and initialize new period
            uint256 periodId = pool.periods.length;
            pool.periods.push();

            Period storage newPeriod = pool.periods[periodId];

            newPeriod.start = block.timestamp;
            newPeriod.end = block.timestamp + pool.blockDuration;

            period = newPeriod;

            emit PeriodEnded(_poolId, periodId - 1);
            emit PeriodStarted(_poolId, periodId);

            // now continue with deposit
        }
        // if more than 1.5% of staking period has passed, user cannot deposit anymore
        else if (
            period.start + ((pool.blockDuration * 15) / 1000) < block.timestamp
        ) revert PoolIsLocked();

        // transfer tokens to staking contract
        if (!Token.transferFrom(msg.sender, address(this), _amount))
            revert TokenTransferFailed();

        // update user deposits
        userDeposits[msg.sender].push(
            UserDeposit(_poolId, pool.periods.length - 1)
        );

        // update period
        period.stakes[msg.sender] += _amount;
        period.totalStaked += _amount;

        emit Deposited(_poolId, msg.sender, _amount);
    }

    function claim(uint256 _poolId, uint256 _periodId) external isInitialized {
        if (_poolId >= pools.length) revert NonExistantPool();

        Pool storage pool = pools[_poolId];
        Period storage period = pool.periods[_periodId];

        if (period.end >= block.timestamp) revert ClaimBeforePeriodEnd();
        if (period.stakes[msg.sender] == 0) revert AlreadyClaimed();

        if (period.stakes[msg.sender] > 0) {
            uint256 reward = (period.stakes[msg.sender] * pool.blockReward) /
                period.totalStaked;
            uint256 stake = period.stakes[msg.sender];

            if (period.end + CLAIM_PERIOD < block.timestamp) {
                // if claim period is expired burn the funds

                // update period
                period.stakes[msg.sender] = 0;
                period.totalStaked -= period.stakes[msg.sender];

                // update MINTED
                MINTED += reward;

                emit Claimed(_poolId, address(0), reward, false);
            } else {
                // update period
                period.stakes[msg.sender] = 0;
                period.totalStaked -= period.stakes[msg.sender];

                // update MINTED
                MINTED += reward;

                // mint reward
                Token.mint(msg.sender, reward);

                emit Claimed(_poolId, msg.sender, reward, false);
            }

            // return stake
            if (!Token.transfer(msg.sender, stake))
                revert TokenTransferFailed();
        }
    }

    function burnExpired(
        uint256 _poolId,
        uint256 _periodId,
        address user
    ) external isInitialized {
        if (_poolId >= pools.length) revert NonExistantPool();

        Pool storage pool = pools[_poolId];
        Period storage period = pool.periods[_periodId];

        if (period.end >= block.timestamp) revert ClaimBeforePeriodEnd();
        if (period.end + CLAIM_PERIOD >= block.timestamp)
            revert ClaimPeriodActive();
        if (period.stakes[user] == 0) revert AlreadyClaimed();

        uint256 reward = (period.stakes[user] * pool.blockReward) /
            period.totalStaked;
        uint256 stake = period.stakes[user];

        // update period
        period.stakes[user] = 0;
        period.totalStaked -= period.stakes[user];

        // update MINTED
        MINTED += reward;

        // return stake
        if (!Token.transfer(user, stake)) revert TokenTransferFailed();

        emit Claimed(_poolId, address(0), reward, true);
    }

    function decomission() external onlyOwner isInitialized {
        DECOMISISONED = true;
    }

    // Getters do not have isInitialized modifier, to lower the gas cost if used with other contracts.

    /**
     * Token address getter.
     * @return address Staking token address.
     */
    function getToken() external view returns (address) {
        return address(Token);
    }

    /**
     * Returns number of existing pools.
     * @return uint256 Number of pools.
     */
    function getPoolCount() external view returns (uint256) {
        return pools.length;
    }

    /**
     * @notice Returns pool info.
     * Will revert if pool does not exist, with NonExistantPool error.
     *
     * @param _poolId Pool id.
     *
     * @return blockDuration Duration of a pool period in blocks.
     * @return blockReward Token reward per block, with decimals included.
     * @return currentPeriod Current period id.
     */
    function getPool(
        uint256 _poolId
    )
        external
        view
        returns (
            uint256 blockDuration,
            uint256 blockReward,
            uint256 currentPeriod
        )
    {
        if (_poolId >= pools.length) revert NonExistantPool();

        Pool storage pool = pools[_poolId];

        return (pool.blockDuration, pool.blockReward, pool.periods.length - 1);
    }

    /**
     * @notice Returns period info.
     * Will revert if pool or period does not exist, with PeriodNotStarted error.
     *
     * @param _poolId Pool id.
     * @param _periodId Period id.
     *
     * @return start Block number when period started.
     * @return end Block number when period ended.
     * @return totalStaked Total amount of tokens staked in this period.
     */
    function getPeriod(
        uint256 _poolId,
        uint256 _periodId
    ) external view returns (uint256 start, uint256 end, uint256 totalStaked) {
        if (_poolId >= pools.length) revert NonExistantPool();

        Pool storage pool = pools[_poolId];

        if (_periodId >= pool.periods.length) revert PeriodNotStarted();

        Period storage period = pool.periods[_periodId];

        return (period.start, period.end, period.totalStaked);
    }

    /**
     * @notice Returns stake info for a certain pool, period and user.
     * Will revert if pool or period does not exist, with PeriodNotStarted or NonExistantPool error.
     *
     * @param _poolId Pool id.
     * @param _periodId Period id.
     * @param _user User address.
     *
     * @return stake Amount of tokens staked by user in this period, will be zero if period has ended and user has already claimed reward.
     */
    function getStake(
        uint256 _poolId,
        uint256 _periodId,
        address _user
    ) external view returns (uint256 stake) {
        if (_poolId >= pools.length) revert NonExistantPool();

        Pool storage pool = pools[_poolId];

        if (_periodId >= pool.periods.length) revert PeriodNotStarted();

        Period storage period = pool.periods[_periodId];

        return period.stakes[_user];
    }

    /**
     * @notice Returns user deposits.
     * @dev Made to easily allow frontends to display user deposits. Entries should be checked for staked amount, if zero, it is already claimed and should not be shown. Also, data should be filtered by periodId, to only show periods that can be claimed according to the claimPeriod.
     *
     * @param _user User address.
     *
     * @return deposits Array of user deposits, containing poolId and periodId.
     */
    function getUserDeposits(
        address _user
    ) external view returns (UserDeposit[] memory deposits) {
        return userDeposits[_user];
    }

    /**
     * @notice Claim period getter.
     * @return uint256 Claim period.
     */
    function getClaimPeriod() external view returns (uint256) {
        return CLAIM_PERIOD;
    }

    /**
     * @notice Is contract decomissioned?
     * @return bool True if contract is decomissioned.
     */
    function isDecomissioned() external view returns (bool) {
        return DECOMISISONED;
    }

    /**
     * @notice Returns total amount of tokens minted.
     * @return uint256 Total amount of tokens minted.
     */
    function getMinted() external view returns (uint256) {
        return MINTED;
    }

    /**
        * @notice Returns minting cap.
        * @return uint256 Minting cap.
    
     */
    function getMintingCap() external view returns (uint256) {
        return MINTING_CAP;
    }

    /**
     * @notice Is contract initialized?
        * @return bool True if contract is initialized.
    
     */
    function getIsInitialized() external view returns (bool) {
        return initialized;
    }
}