// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title HighStreet Nft Pool
 *
 */
contract HighStreetNftPool is ReentrancyGuard, ERC721Holder {

    /**
     * @dev Deposit is a key data structure used in staking,
     *      it represents a unit of reward with its amount and time interval
     */
    struct Deposit {
        // @dev reward amount
        uint256 rewardAmount;
        // @dev locking period - from
        uint64 lockedFrom;
        // @dev locking period - until
        uint64 lockedUntil;
    }

    /// @dev Data structure representing token holder using a pool
    struct User {
        // @dev Total staked NFT amount
        uint256 tokenAmount;
        // @dev Total reward amount
        uint256 rewardAmount;
        // @dev Auxiliary variable for yield calculation
        uint256 subYieldRewards;
        // @dev An array of holder's nft
        uint16[] list;
        // @dev An array of holder's rewards
        Deposit[] deposits;
    }

    /// @dev Link to HIGH STREET ERC20 Token instance
    address public immutable HIGH;

    /// @dev Token holder storage, maps token holder address to their data record
    mapping(address => User) public users;

    /// @dev Link to the pool token instance, here is the Duck NFT 
    address public immutable poolToken;

    /// @dev Block number of the last yield distribution event
    uint256 public lastYieldDistribution;

    /// @dev Used to calculate yield rewards
    uint256 public yieldRewardsPerToken;

    /// @dev Used to calculate yield rewards, tracking the token amount in the pool
    uint256 public usersLockingAmount;

    /// @dev HIGH/block determines yield farming reward
    uint256 public highPerBlock;

    /**
     * @dev End block is the last block when yield farming stops
     */
    uint256 public endBlock;

    /**
     * @dev Rewards per token are stored multiplied by 1e24, as integers
     */
    uint256 internal constant REWARD_PER_TOKEN_MULTIPLIER = 1e24;

    /**
     * @dev Define the size of each batch, see getDepositsBatch()
     */
    uint256 public constant DEPOSIT_BATCH_SIZE  = 20;

    /**
     * @dev Define the size of each batch, see getNftsBatch()
     */
    uint256 public constant NFT_BATCH_SIZE  = 100;

    /**
     * @dev Handle the nft id equal to zero
     */
    uint16 internal constant UINT_16_MAX = type(uint16).max;

    /**
     * @dev Fired in _stake() and stake()
     *
     * @param _by an address which performed an operation, usually token holder
     * @param _from token holder address, the tokens will be returned to that address
     * @param amount amount of tokens staked
     * @param nfts an array stored the NFT id that holder staked
     */
    event Staked(address indexed _by, address indexed _from, uint256 amount, uint256[] nfts);

    /**
     * @dev Fired in _unstake() and unstake()
     *
     * @param _by an address which performed an operation, usually token holder
     * @param _to an address which received the unstaked tokens, usually token holder
     * @param amount amount of tokens unstaked
     * @param nfts an array which stored the unstaked NFT id 
     */
    event Unstaked(address indexed _by, address indexed _to, uint256 amount, uint256[] nfts);

    /**
     * @dev Fired in _unstakeReward() and unstakeReward()
     *
     * @param _by an address which performed an operation, usually token holder
     * @param _to an address which received the unstaked tokens, usually token holder
     * @param amount amount of rewards unstaked
     */
    event UnstakedReward(address indexed _by, address indexed _to, uint256 amount);

    /**
     * @dev Fired in _sync(), sync() and dependent functions (stake, unstake, etc.)
     *
     * @param _by an address which performed an operation
     * @param yieldRewardsPerToken updated yield rewards per token value
     * @param lastYieldDistribution usually, current block number
     */
    event Synchronized(address indexed _by, uint256 yieldRewardsPerToken, uint256 lastYieldDistribution);

    /**
     * @dev Fired in _processRewards(), processRewards() and dependent functions (stake, unstake, etc.)
     *
     * @param _by an address which performed an operation
     * @param _to an address which claimed the yield reward
     * @param amount amount of yield paid
     */
    event YieldClaimed(address indexed _by, address indexed _to, uint256 amount);

    /**
     * @dev construct the pool
     *
     * @param _high HIGH ERC20 Token address
     * @param _poolToken token ERC721 the pool operates on, here is the Duck NFT
     * @param _initBlock initial block used to calculate the rewards
     *      note: _initBlock can be set to the future effectively meaning _sync() calls will do nothing
     * @param _endBlock block number when farming stops and rewards cannot be updated anymore
     * @param _highPerBlock HIGH/block value for rewards
     */
    constructor(
        address _high,
        address _poolToken,
        uint256 _initBlock,
        uint256 _endBlock,
        uint256 _highPerBlock
    ) {
        // verify the inputs are set
        require(_high != address(0), "high token address not set");
        require(_poolToken != address(0), "pool token address not set");
        require(_initBlock >= blockNumber(), "Invalid init block");

        // save the inputs into internal state variables
        HIGH = _high;
        poolToken = _poolToken;
        highPerBlock = _highPerBlock;

        // init the dependent internal state variables
        lastYieldDistribution = _initBlock;
        endBlock = _endBlock;
    }

    /**
     * @notice Calculates current yield rewards value available for address specified
     *
     * @param _staker an address to calculate yield rewards value for
     * @return calculated yield reward value for the given address
     */
    function pendingYieldRewards(address _staker) external view returns (uint256) {
        // `newYieldRewardsPerToken` will store stored or recalculated value for `yieldRewardsPerToken`
        uint256 newYieldRewardsPerToken;

        // if smart contract state was not updated recently, `yieldRewardsPerToken` value
        // is outdated and we need to recalculate it in order to calculate pending rewards correctly
        if (blockNumber() > lastYieldDistribution && usersLockingAmount != 0) {
            uint256 multiplier =
                blockNumber() > endBlock ? endBlock - lastYieldDistribution : blockNumber() - lastYieldDistribution;
            uint256 highRewards = multiplier * highPerBlock;

            // recalculated value for `yieldRewardsPerToken`
            newYieldRewardsPerToken = rewardToToken(highRewards, usersLockingAmount) + yieldRewardsPerToken;
        } else {
            // if smart contract state is up to date, we don't recalculate
            newYieldRewardsPerToken = yieldRewardsPerToken;
        }

        // based on the rewards per token value, calculate pending rewards;
        User memory user = users[_staker];
        uint256 pending = tokenToReward(user.tokenAmount, newYieldRewardsPerToken) - user.subYieldRewards;

        return pending;
    }

    /**
     * @notice Returns total staked token balance for the given address
     *
     * @param _user an address to query balance for
     * @return total staked token balance
     */
    function balanceOf(address _user) external view returns (uint256) {
        // read specified user token amount and return
        return users[_user].tokenAmount;
    }

    /**
     * @notice Returns the NFT id on the given index and address
     *
     * @dev See getNftListLength
     *
     * @param _user an address to query deposit for
     * @param _index zero-indexed ID for the address specified
     * @return nft id sotred
     */
    function getNftId(address _user, uint256 _index) external view returns (int32) {
        // read deposit at specified index and return
        uint16 value = users[_user].list[_index];
        if(value == 0) {
            return -1;
        } else if(value == UINT_16_MAX) {
            return  0;
        } else {
            return int32(uint32(value));
        }
    }

    /**
     * @notice Returns number of nfts for the given address. Allows iteration over nfts.
     *
     * @dev See getNftId
     *
     * @param _user an address to query deposit length for
     * @return number of nfts for the given address
     */
    function getNftsLength(address _user) external view returns (uint256) {
        // read deposits array length and return
        return users[_user].list.length;
    }

    /**
     * @notice Returns information on the given deposit for the given address
     *
     * @dev See getDepositsLength
     *
     * @param _user an address to query deposit for
     * @param _depositId zero-indexed deposit ID for the address specified
     * @return deposit info as Deposit structure
     */
    function getDeposit(address _user, uint256 _depositId) external view returns (Deposit memory) {
        // read deposit at specified index and return
        return users[_user].deposits[_depositId];
    }

    /**
     * @notice Returns number of deposits for the given address. Allows iteration over deposits.
     *
     * @dev See getDeposit
     *
     * @param _user an address to query deposit length for
     * @return number of deposits for the given address
     */
    function getDepositsLength(address _user) external view returns (uint256) {
        // read deposits array length and return
        return users[_user].deposits.length;
    }

    /**
     * @notice Returns a batch of deposits on the given pageId for the given address
     *
     * @dev We separate deposits into serveral of pages, and each page have DEPOSIT_BATCH_SIZE of item.
     *
     * @param _user an address to query deposit for
     * @param _pageId zero-indexed page ID for the address specified
     * @return deposits info as Deposit structure
     */
    function getDepositsBatch(address _user, uint256 _pageId) external view returns (Deposit[] memory) {
        uint256 pageStart = _pageId * DEPOSIT_BATCH_SIZE;
        uint256 pageEnd = (_pageId + 1) * DEPOSIT_BATCH_SIZE;
        uint256 pageLength = DEPOSIT_BATCH_SIZE;

        if(pageEnd > (users[_user].deposits.length - pageStart)) {
            pageEnd = users[_user].deposits.length;
            pageLength = pageEnd - pageStart;
        }

        Deposit[] memory deposits = new Deposit[](pageLength);
        for(uint256 i = pageStart; i < pageEnd; ++i) {
            deposits[i-pageStart] = users[_user].deposits[i];
        }
        return deposits;
    }

    /**
     * @notice Returns number of pages for the given address. Allows iteration over deposits.
     *
     * @dev See getDepositsBatch
     *
     * @param _user an address to query deposit length for
     * @return number of pages for the given address
     */
    function getDepositsBatchLength(address _user) external view returns (uint256) {
        if(users[_user].deposits.length == 0) {
            return 0;
        }
        return 1 + (users[_user].deposits.length - 1) / DEPOSIT_BATCH_SIZE;
    }


    /**
     * @notice Returns a batch of NFT id on the given pageId for the given address
     *
     * @dev We separate NFT id into serveral of pages, and each page have NFT_BATCH_SIZE of ids.
     *
     * @param _user an address to query deposit for
     * @param _pageId zero-indexed page ID for the address specified
     * @return nft ids that holder staked
     */
    function getNftsBatch(address _user, uint256 _pageId) external view returns (int32[] memory) {
        uint256 pageStart = _pageId * NFT_BATCH_SIZE;
        uint256 pageEnd = (_pageId + 1) * NFT_BATCH_SIZE;
        uint256 pageLength = NFT_BATCH_SIZE;

        if(pageEnd > (users[_user].list.length - pageStart)) {
            pageEnd = users[_user].list.length;
            pageLength = pageEnd - pageStart;
        }

        int32[] memory list = new int32[](pageLength);
        uint16 value;
        for(uint256 i = pageStart; i < pageEnd; ++i) {
            value = users[_user].list[i];
            if(value == 0) {
                list[i-pageStart] = -1;
            } else if(value == UINT_16_MAX) {
                list[i-pageStart] = 0;
            } else {
                list[i-pageStart] = int32(uint32(value));
            }
        }
        return list;
    }

    /**
     * @notice Returns number of pages for the given address. Allows iteration over nfts.
     *
     * @dev See getNftsBatch
     *
     * @param _user an address to query NFT id length for
     * @return number of pages for the given address
     */
    function getNftsBatchLength(address _user) external view returns (uint256) {
        if(users[_user].list.length == 0) {
            return 0;
        }
        return 1 + (users[_user].list.length - 1) / NFT_BATCH_SIZE;
    }

    /**
     * @notice Stakes specified NFT ids
     *
     * @dev Requires amount to stake to be greater than zero
     *
     * @dev Reentrancy safety enforced via `ReentrancyGuard.nonReentrant`
     *
     * @param _nftIds array of NFTs to stake
     */
    function stake(
        uint256[] calldata _nftIds
    ) external nonReentrant {
        require(!isPoolDisabled(), "Pool disable");
        // delegate call to an internal function
        _stake(msg.sender, _nftIds);
    }

    /**
     * @notice Unstakes specified amount of NFTs, and pays pending yield rewards
     *
     * @dev Requires amount to unstake to be greater than zero
     *
     * @dev Reentrancy safety enforced via `ReentrancyGuard.nonReentrant`
     *
     * @param _listIds index ID to unstake from, zero-indexed
     */
    function unstake(
        uint256[] calldata _listIds
    ) external nonReentrant {
        // delegate call to an internal function
        _unstake(msg.sender, _listIds);
    }

    /**
     * @notice Unstakes specified amount of rewards
     *
     * @dev Requires amount to unstake to be greater than zero
     *
     * @dev Reentrancy safety enforced via `ReentrancyGuard.nonReentrant`
     *
     * @param _depositId deposit ID to unstake from, zero-indexed
     */
    function unstakeReward(
        uint256 _depositId
    ) external nonReentrant {
        // delegate call to an internal function
        User storage user = users[msg.sender];
        Deposit memory stakeDeposit = user.deposits[_depositId];
        require(now256() > stakeDeposit.lockedUntil, "deposit not yet unlocked");
        _unstakeReward(msg.sender, _depositId);
    }

    /**
     * @notice Service function to synchronize pool state with current time
     *
     * @dev Can be executed by anyone at any time, but has an effect only when
     *      at least one block passes between synchronizations
     * @dev Executed internally when staking, unstaking, processing rewards in order
     *      for calculations to be correct and to reflect state progress of the contract
     * @dev When timing conditions are not met (executed too frequently, or after end block
     *      ), function doesn't throw and exits silently
     */
    function sync() external {
        // delegate call to an internal function
        _sync();
    }

    /**
     * @notice Service function to calculate and pay pending yield rewards to the sender
     *
     * @dev Can be executed by anyone at any time, but has an effect only when
     *      executed by deposit holder and when at least one block passes from the
     *      previous reward processing
     * @dev Executed internally when staking and unstaking, executes sync() under the hood
     *      before making further calculations and payouts
     * @dev When timing conditions are not met (executed too frequently, or after end block
     *      ), function doesn't throw and exits silently
     *
     * @dev Reentrancy safety enforced via `ReentrancyGuard.nonReentrant`
     *
     */
    function processRewards() external virtual nonReentrant {
        // delegate call to an internal function
        _processRewards(msg.sender, true);
    }

    /**
     * @dev Similar to public pendingYieldRewards, but performs calculations based on
     *      current smart contract state only, not taking into account any additional
     *      time/blocks which might have passed
     *
     * @param _staker an address to calculate yield rewards value for
     * @return pending calculated yield reward value for the given address
     */
    function _pendingYieldRewards(address _staker) internal view returns (uint256 pending) {
        // read user data structure into memory
        User memory user = users[_staker];

        // and perform the calculation using the values read
        return tokenToReward(user.tokenAmount, yieldRewardsPerToken) - user.subYieldRewards;
    }

    /**
     * @dev Used internally, mostly by children implementations, see stake()
     *
     * @param _staker an address which stakes tokens and which will receive them back
     * @param _nftIds array of NFTs staked
     */
    function _stake(
        address _staker,
        uint256[] calldata _nftIds
    ) internal virtual {
        require(_nftIds.length > 0, "zero amount");
        // limit the max nft transfer.
        require(_nftIds.length <= 40, "length exceeds limitation");

        // update smart contract state
        _sync();

        // get a link to user data struct, we will write to it later
        User storage user = users[_staker];
        // process current pending rewards if any
        if (user.tokenAmount > 0) {
            _processRewards(_staker, false);
        }

        //looping transfer
        uint256 addedAmount;
        for(uint i; i < _nftIds.length; ++i) {
            IERC721(poolToken).safeTransferFrom(_staker, address(this), _nftIds[i]);
            if(_nftIds[i] == 0) {
                //if nft id ==0, then set it to uint16 max
                user.list.push(UINT_16_MAX);
            } else {
                user.list.push(uint16(_nftIds[i]));
            }
            addedAmount = addedAmount + 1;
        }

        user.tokenAmount += addedAmount;
        user.subYieldRewards = tokenToReward(user.tokenAmount, yieldRewardsPerToken);
        usersLockingAmount += addedAmount;

        // emit an event
        emit Staked(msg.sender, _staker, addedAmount, _nftIds);
    }

    /**
     * @dev Used internally, mostly by children implementations, see unstake()
     *
     * @param _staker an address which unstakes NFT (which has staked some NFTs earlier)
     * @param _listIds index ID to unstake from, zero-indexed
     */
    function _unstake(
        address _staker,
        uint256[] calldata _listIds
    ) internal virtual {
        require(_listIds.length > 0, "zero amount");
        // limit the max nft transfer.
        require(_listIds.length <= 40, "length exceeds limitation");

        // get a link to user data struct, we will write to it later
        User storage user = users[_staker];
        uint16[] memory list = user.list;
        uint256 amount = _listIds.length;
        require(user.tokenAmount >= amount, "amount exceeds stake");

        // update smart contract state
        _sync();
        // and process current pending rewards if any
        _processRewards(_staker, false);

        // update user record
        user.tokenAmount -= amount;
        user.subYieldRewards = tokenToReward(user.tokenAmount, yieldRewardsPerToken);
        usersLockingAmount = usersLockingAmount - amount;

        uint256 index;
        uint256[] memory nfts = new uint256[](_listIds.length);
        for(uint i; i < _listIds.length; ++i) {
            index = _listIds[i];
            if(UINT_16_MAX == list[index]) {
                nfts[i] = 0;
            } else {
                nfts[i] = uint256(list[index]);
            }
            IERC721(poolToken).safeTransferFrom(address(this), _staker, nfts[i]);
            if (user.tokenAmount  != 0) {
                delete user.list[index];
            }
        }

        if (user.tokenAmount  == 0) {
            delete user.list;
        }

        // emit an event
        emit Unstaked(msg.sender, _staker, amount, nfts);
    }

    /**
     * @dev Used internally, mostly by children implementations, see unstakeReward()
     *
     * @param _staker an address to withraw the yield reward
     * @param _depositId deposit ID to unstake from, zero-indexed
     */
    function _unstakeReward(
        address _staker,
        uint256 _depositId
    ) internal virtual {

        // get a link to user data struct, we will write to it later
        User storage user = users[_staker];
        // get a link to the corresponding deposit, we may write to it later
        Deposit storage stakeDeposit = user.deposits[_depositId];

        uint256 amount = stakeDeposit.rewardAmount;

        // verify available balance
        // if staker address ot deposit doesn't exist this check will fail as well
        require(amount >= 0, "amount exceeds stake");

        // delete deposit if its depleted
        delete user.deposits[_depositId];

        // update user record
        user.rewardAmount -= amount;

        // transfer HIGH tokens as required
        SafeERC20.safeTransfer(IERC20(HIGH), _staker, amount);

        // emit an event
        emit UnstakedReward(msg.sender, _staker, amount);
    }

    /**
     * @dev Used internally, mostly by children implementations, see sync()
     *
     * @dev Updates smart contract state (`yieldRewardsPerToken`, `lastYieldDistribution`)
     */
    function _sync() internal virtual {

        // check bound conditions and if these are not met -
        // exit silently, without emitting an event
        if (lastYieldDistribution >= endBlock) {
            return;
        }
        if (blockNumber() <= lastYieldDistribution) {
            return;
        }
        // if locking weight is zero - update only `lastYieldDistribution` and exit
        if (usersLockingAmount == 0) {
            lastYieldDistribution = blockNumber();
            return;
        }

        // to calculate the reward we need to know how many blocks passed, and reward per block
        uint256 currentBlock = blockNumber() > endBlock ? endBlock : blockNumber();
        uint256 blocksPassed = currentBlock - lastYieldDistribution;

        // calculate the reward
        uint256 highReward = blocksPassed * highPerBlock;

        // update rewards per weight and `lastYieldDistribution`
        yieldRewardsPerToken += rewardToToken(highReward, usersLockingAmount);
        lastYieldDistribution = currentBlock;

        // emit an event
        emit Synchronized(msg.sender, yieldRewardsPerToken, lastYieldDistribution);
    }

    /**
     * @dev Used internally, mostly by children implementations, see processRewards()
     *
     * @param _staker an address which receives the reward (which has staked some tokens earlier)
     * @param _withUpdate flag allowing to disable synchronization (see sync()) if set to false
     * @return pendingYield the rewards calculated
     */
    function _processRewards(
        address _staker,
        bool _withUpdate
    ) internal virtual returns (uint256 pendingYield) {
        // update smart contract state if required
        if (_withUpdate) {
            _sync();
        }

        // calculate pending yield rewards, this value will be returned
        pendingYield = _pendingYieldRewards(_staker);

        // if pending yield is zero - just return silently
        if (pendingYield == 0) return 0;

        // get link to a user data structure, we will write into it later
        User storage user = users[_staker];

        // create new HIGH deposit
        // and save it - push it into deposits array
        Deposit memory newDeposit =
            Deposit({
                rewardAmount: pendingYield,
                lockedFrom: uint64(now256()),
                lockedUntil: uint64(now256() + 365 days) // staking yield for 1 year
            });
        user.deposits.push(newDeposit);

        // update user record
        user.rewardAmount += pendingYield;

        // update users's record for `subYieldRewards` if requested
        if (_withUpdate) {
            user.subYieldRewards = tokenToReward(user.tokenAmount, yieldRewardsPerToken);
        }

        // emit an event
        emit YieldClaimed(msg.sender, _staker, pendingYield);
    }

    /**
     * @dev Converts stake token (not to be mixed with the pool token) to
     *      HIGH reward value, applying the 10^24 division on token
     *
     * @param _token stake token
     * @param _rewardPerToken HIGH reward per token
     * @return reward value normalized to 10^24
     */
    function tokenToReward(uint256 _token, uint256 _rewardPerToken) public pure returns (uint256) {
        // apply the formula and return
        return (_token * _rewardPerToken) / REWARD_PER_TOKEN_MULTIPLIER;
    }

    /**
     * @dev Converts reward HIGH value to stake token (not to be mixed with the pool token),
     *      applying the 10^24 multiplication on the reward
     *
     * @param _reward yield reward
     * @param _rewardPerToken staked token amount
     * @return reward/token
     */
    function rewardToToken(uint256 _reward, uint256 _rewardPerToken) public pure returns (uint256) {
        // apply the reverse formula and return
        return (_reward * REWARD_PER_TOKEN_MULTIPLIER) / _rewardPerToken;
    }

    /**
     * @notice The function to check pool state. pool is considered "disabled"
     *      once time reaches its "end block"
     *
     * @return true if pool is disabled (time has reached end block), false otherwise
     */
    function isPoolDisabled() public view returns (bool) {
        // verify the pool expiration condition and return the result
        return blockNumber() >= endBlock;
    }

    /**
     * @dev Testing time-dependent functionality is difficult and the best way of
     *      doing it is to block number in helper test smart contracts
     *
     * @return `block.number` in mainnet, custom values in testnets (if overridden)
     */
    function blockNumber() public view virtual returns (uint256) {
        // return current block number
        return block.number;
    }

    /**
     * @dev Testing time-dependent functionality is difficult and the best way of
     *      doing it is to time in helper test smart contracts
     *
     * @return `block.timestamp` in mainnet, custom values in testnets (if overridden)
     */
    function now256() public view virtual returns (uint256) {
        // return current block timestamp
        return block.timestamp;
    }
}