// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import "./../@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/math/SafeMath.sol";
import './../@openzeppelin/contracts/utils/math/SafeMath.sol';
// import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import './../@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import "./../@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


contract Staking3 is Initializable, ReentrancyGuardUpgradeable {
    using SafeMath for uint256;

    uint128 constant private BASE_MULTIPLIER = uint128(1 * 10 ** 18);

    // timestamp for the epoch 1
    // everything before that is considered epoch 0 which won't have a reward but allows for the initial stake
    uint256 public epoch1Start;

    // duration of each epoch
    uint256 public epochDuration;

    // holds the current balance of the user for each token
    mapping(address => mapping(address => uint256)) private balances;

    struct Pool {
        uint256 size;
        bool set;
    }

    // for each token, we store the total pool size
    mapping(address => mapping(uint256 => Pool)) private poolSize;

    // a checkpoint of the valid balance of a user for an epoch
    struct Checkpoint {
        uint128 epochId;
        uint128 multiplier;
        uint256 startBalance;
        uint256 newDeposits;
    }

    // balanceCheckpoints[user][token][]
    mapping(address => mapping(address => Checkpoint[])) private balanceCheckpoints;

    mapping(address => uint128) private lastWithdrawEpochId;

    event Deposit(address indexed user, address indexed tokenAddress, uint256 amount);
    event Withdraw(address indexed user, address indexed tokenAddress, uint256 amount);
    event ManualEpochInit(address indexed caller, uint128 indexed epochId, address[] tokens);
    event EmergencyWithdraw(address indexed user, address indexed tokenAddress, uint256 amount);

    address guardianAddress;
    mapping(address => bool) isApproved;

    // Base holding rewards tracking
    mapping(address => uint256) private _accrued;

    function initialize(address _guardianAddress, uint256 _epoch1Start, uint256 _epochDuration) public initializer {
        guardianAddress = _guardianAddress;
        epoch1Start = _epoch1Start;
        epochDuration = _epochDuration;
    }

    // TODO: set up stuff to connect this to the bHome token

    function approveAccess(address addr) public{
        require(msg.sender == guardianAddress, "caller must be guardian");
        isApproved[addr] = true;
    }

    function revokeAccess(address addr) public{
        require(msg.sender == guardianAddress, "caller must be guardian");
        isApproved[addr] = false;
    }

    /*
     * Stores `amount` of `tokenAddress` tokens for the `user` into the vault
     */
    function deposit(address tokenAddress, address wallet, uint256 amount) public nonReentrant {
        require(isApproved[msg.sender], "Caller must be an approved");
        require(amount > 0, "Staking: Amount must be > 0");

        IERC20 token = IERC20(tokenAddress);
        uint256 stakedBalance = _getBalance(balances[wallet][tokenAddress]).add(amount);

        // Scoping this so we don't run out of stack space <sigh>
        {
            // TODO: does it make sense to do this allowance thing if we are the ones doing the transfer? Probably not...
            // uint256 allowance = token.allowance(wallet, address(this));
            // require(allowance >= amount, "Staking: Token allowance too small");

            _setBalance(wallet, tokenAddress, stakedBalance);
            // token.transferFrom(wallet, address(this), amount);
        }

        // epoch logic
        uint128 currentEpoch = getCurrentEpoch();
        uint128 currentMultiplier = currentEpochMultiplier();

        if (!epochIsInitialized(tokenAddress, currentEpoch)) {
            address[] memory tokens = new address[](1);
            tokens[0] = tokenAddress;
            manualEpochInit(tokens, currentEpoch);
        }

        // update the next epoch pool size
        Pool storage pNextEpoch = poolSize[tokenAddress][currentEpoch + 1];
        pNextEpoch.size = token.balanceOf(address(this));
        pNextEpoch.set = true;

        Checkpoint[] storage checkpoints = balanceCheckpoints[wallet][tokenAddress];

        uint256 balanceBefore = getEpochUserBalance(wallet, tokenAddress, currentEpoch);

        // if there's no checkpoint yet, it means the user didn't have any activity
        // we want to store checkpoints both for the current epoch and next epoch because
        // if a user does a withdraw, the current epoch can also be modified and
        // we don't want to insert another checkpoint in the middle of the array as that could be expensive
        if (checkpoints.length == 0) {
            checkpoints.push(Checkpoint(currentEpoch, currentMultiplier, 0, amount));

            // next epoch => multiplier is 1, epoch deposits is 0
            checkpoints.push(Checkpoint(currentEpoch + 1, BASE_MULTIPLIER, amount, 0));
        } else {
            uint256 last = checkpoints.length - 1;

            // the last action happened in an older epoch (e.g. a deposit in epoch 3, current epoch is >=5)
            if (checkpoints[last].epochId < currentEpoch) {
                uint128 multiplier = computeNewMultiplier(
                    getCheckpointBalance(checkpoints[last]),
                    BASE_MULTIPLIER,
                    amount,
                    currentMultiplier
                );
                checkpoints.push(Checkpoint(currentEpoch, multiplier, getCheckpointBalance(checkpoints[last]), amount));
                checkpoints.push(Checkpoint(currentEpoch + 1, BASE_MULTIPLIER, stakedBalance, 0));
            }
            // the last action happened in the previous epoch
            else if (checkpoints[last].epochId == currentEpoch) {
                checkpoints[last].multiplier = computeNewMultiplier(
                    getCheckpointBalance(checkpoints[last]),
                    checkpoints[last].multiplier,
                    amount,
                    currentMultiplier
                );
                checkpoints[last].newDeposits = checkpoints[last].newDeposits.add(amount);

                checkpoints.push(Checkpoint(currentEpoch + 1, BASE_MULTIPLIER, stakedBalance, 0));
            }
            // the last action happened in the current epoch
            else {
                if (last >= 1 && checkpoints[last - 1].epochId == currentEpoch) {
                    checkpoints[last - 1].multiplier = computeNewMultiplier(
                        getCheckpointBalance(checkpoints[last - 1]),
                        checkpoints[last - 1].multiplier,
                        amount,
                        currentMultiplier
                    );
                    checkpoints[last - 1].newDeposits = checkpoints[last - 1].newDeposits.add(amount);
                }

                checkpoints[last].startBalance = stakedBalance;
            }
        }

        uint256 balanceAfter = getEpochUserBalance(wallet, tokenAddress, currentEpoch);

        poolSize[tokenAddress][currentEpoch].size = poolSize[tokenAddress][currentEpoch].size.add(balanceAfter.sub(balanceBefore));

        emit Deposit(wallet, tokenAddress, amount);
    }

    /*
     * Removes the deposit of the user and sends the amount of `tokenAddress` back to the `user`
     */
    function withdraw(address tokenAddress, address wallet, uint256 amount) public nonReentrant {
        require(isApproved[msg.sender], "Caller must be an approved");

        uint256 stakedBalance = _getBalance(balances[wallet][tokenAddress]);
        require(stakedBalance >= amount, "Staking: balance too small");

        stakedBalance = stakedBalance.sub(amount);
        _setBalance(wallet, tokenAddress, stakedBalance);

        IERC20 token = IERC20(tokenAddress);
        token.transfer(wallet, amount);

        // epoch logic
        uint128 currentEpoch = getCurrentEpoch();

        lastWithdrawEpochId[tokenAddress] = currentEpoch;

        if (!epochIsInitialized(tokenAddress, currentEpoch)) {
            address[] memory tokens = new address[](1);
            tokens[0] = tokenAddress;
            manualEpochInit(tokens, currentEpoch);
        }

        // update the pool size of the next epoch to its current balance
        Pool storage pNextEpoch = poolSize[tokenAddress][currentEpoch + 1];
        pNextEpoch.size = token.balanceOf(address(this));
        pNextEpoch.set = true;

        Checkpoint[] storage checkpoints = balanceCheckpoints[wallet][tokenAddress];
        uint256 last = checkpoints.length - 1;

        // note: it's impossible to have a withdraw and no checkpoints because the balance would be 0 and revert

        // there was a deposit in an older epoch (more than 1 behind [eg: previous 0, now 5]) but no other action since then
        if (checkpoints[last].epochId < currentEpoch) {
            checkpoints.push(Checkpoint(currentEpoch, BASE_MULTIPLIER, stakedBalance, 0));

            poolSize[tokenAddress][currentEpoch].size = poolSize[tokenAddress][currentEpoch].size.sub(amount);
        }
        // there was a deposit in the `epochId - 1` epoch => we have a checkpoint for the current epoch
        else if (checkpoints[last].epochId == currentEpoch) {
            checkpoints[last].startBalance = stakedBalance;
            checkpoints[last].newDeposits = 0;
            checkpoints[last].multiplier = BASE_MULTIPLIER;

            poolSize[tokenAddress][currentEpoch].size = poolSize[tokenAddress][currentEpoch].size.sub(amount);
        }
        // there was a deposit in the current epoch
        else {
            Checkpoint storage currentEpochCheckpoint = checkpoints[last - 1];

            uint256 balanceBefore = getCheckpointEffectiveBalance(currentEpochCheckpoint);

            // in case of withdraw, we have 2 branches:
            // 1. the user withdraws less than he added in the current epoch
            // 2. the user withdraws more than he added in the current epoch (including 0)
            if (amount < currentEpochCheckpoint.newDeposits) {
                uint128 avgDepositMultiplier = uint128(
                    balanceBefore.sub(currentEpochCheckpoint.startBalance).mul(BASE_MULTIPLIER).div(currentEpochCheckpoint.newDeposits)
                );

                currentEpochCheckpoint.newDeposits = currentEpochCheckpoint.newDeposits.sub(amount);

                currentEpochCheckpoint.multiplier = computeNewMultiplier(
                    currentEpochCheckpoint.startBalance,
                    BASE_MULTIPLIER,
                    currentEpochCheckpoint.newDeposits,
                    avgDepositMultiplier
                );
            } else {
                currentEpochCheckpoint.startBalance = currentEpochCheckpoint.startBalance.sub(
                    amount.sub(currentEpochCheckpoint.newDeposits)
                );
                currentEpochCheckpoint.newDeposits = 0;
                currentEpochCheckpoint.multiplier = BASE_MULTIPLIER;
            }

            uint256 balanceAfter = getCheckpointEffectiveBalance(currentEpochCheckpoint);

            poolSize[tokenAddress][currentEpoch].size = poolSize[tokenAddress][currentEpoch].size.sub(balanceBefore.sub(balanceAfter));

            checkpoints[last].startBalance = stakedBalance;
        }

        emit Withdraw(wallet, tokenAddress, amount);
    }

    /*
     * manualEpochInit can be used by anyone to initialize an epoch based on the previous one
     * This is only applicable if there was no action (deposit/withdraw) in the current epoch.
     * Any deposit and withdraw will automatically initialize the current and next epoch.
     */
    function manualEpochInit(address[] memory tokens, uint128 epochId) public {
        require(epochId <= getCurrentEpoch(), "can't init a future epoch");

        for (uint i = 0; i < tokens.length; i++) {
            Pool storage p = poolSize[tokens[i]][epochId];

            if (epochId == 0) {
                p.size = uint256(0);
                p.set = true;
            } else {
                require(!epochIsInitialized(tokens[i], epochId), "Staking: epoch already initialized");
                require(epochIsInitialized(tokens[i], epochId - 1), "Staking: previous epoch not initialized");

                p.size = poolSize[tokens[i]][epochId - 1].size;
                p.set = true;
            }
        }

        emit ManualEpochInit(msg.sender, epochId, tokens);
    }

    /* helpful function for testnets where the epoch is often not inited by users */
    function manualBatchEpochInit(address[] memory tokens, uint128 startingEpochId, uint128 endingEpochId) public {
        require(endingEpochId <= getCurrentEpoch(), "can't init a future epoch");
        for (uint128 i = startingEpochId; i <= endingEpochId; i++) {
            manualEpochInit(tokens, i);
        }
    }

    function emergencyWithdraw(address wallet, address tokenAddress) public {
        require(isApproved[msg.sender], "Caller must be an approved");
        require((getCurrentEpoch() - lastWithdrawEpochId[tokenAddress]) >= 10, "At least 10 epochs must pass without success");

        uint256 totalUserBalance = _getBalance(balances[wallet][tokenAddress]);
        require(totalUserBalance > 0, "Amount must be > 0");

        _setBalance(wallet, tokenAddress, 0);

        IERC20 token = IERC20(tokenAddress);
        token.transfer(wallet, totalUserBalance);

        emit EmergencyWithdraw(wallet, tokenAddress, totalUserBalance);
    }

    /*
     * Returns the valid balance of a user that was taken into consideration in the total pool size for the epoch
     * A deposit will only change the next epoch balance.
     * A withdraw will decrease the current epoch (and subsequent) balance.
     */
    function getEpochUserBalance(address user, address token, uint128 epochId) public view returns (uint256) {
        Checkpoint[] storage checkpoints = balanceCheckpoints[user][token];

        // if there are no checkpoints, it means the user never deposited any tokens, so the balance is 0
        if (checkpoints.length == 0 || epochId < checkpoints[0].epochId) {
            return 0;
        }

        uint min = 0;
        uint max = checkpoints.length - 1;

        // shortcut for blocks newer than the latest checkpoint == current balance
        if (epochId >= checkpoints[max].epochId) {
            return getCheckpointEffectiveBalance(checkpoints[max]);
        }

        // binary search of the value in the array
        while (max > min) {
            uint mid = (max + min + 1) / 2;
            if (checkpoints[mid].epochId <= epochId) {
                min = mid;
            } else {
                max = mid - 1;
            }
        }

        return getCheckpointEffectiveBalance(checkpoints[min]);
    }

    /*
     * Returns the amount of `token` that the `user` has currently staked
     */
    function balanceOf(address user, address token) public view returns (uint256) {
        return _getBalance(balances[user][token]);
    }

    /*
     * Returns the id of the current epoch derived from block.timestamp
     */
    function getCurrentEpoch() public view returns (uint128) {
        if (block.timestamp < epoch1Start) {
            return 0;
        }

        return uint128((block.timestamp - epoch1Start) / epochDuration + 1);
    }

    /*
     * Returns the total amount of `tokenAddress` that was locked from beginning to end of epoch identified by `epochId`
     */
    function getEpochPoolSize(address tokenAddress, uint128 epochId) public view returns (uint256) {
        // Premises:
        // 1. it's impossible to have gaps of uninitialized epochs
        // - any deposit or withdraw initialize the current epoch which requires the previous one to be initialized
        if (epochIsInitialized(tokenAddress, epochId)) {
            return poolSize[tokenAddress][epochId].size;
        }

        // epochId not initialized and epoch 0 not initialized => there was never any action on this pool
        if (!epochIsInitialized(tokenAddress, 0)) {
            return 0;
        }

        // epoch 0 is initialized => there was an action at some point but none that initialized the epochId
        // which means the current pool size is equal to the current balance of token held by the staking contract
        IERC20 token = IERC20(tokenAddress);
        return token.balanceOf(address(this));
    }

    /*
     * Returns the percentage of time left in the current epoch
     */
    function currentEpochMultiplier() public view returns (uint128) {
        uint128 currentEpoch = getCurrentEpoch();
        uint256 currentEpochEnd = epoch1Start + currentEpoch * epochDuration;
        uint256 timeLeft = currentEpochEnd - block.timestamp;
        uint128 multiplier = uint128(timeLeft * BASE_MULTIPLIER / epochDuration);

        return multiplier;
    }

    function computeNewMultiplier(uint256 prevBalance, uint128 prevMultiplier, uint256 amount, uint128 currentMultiplier) public pure returns (uint128) {
        uint256 prevAmount = prevBalance.mul(prevMultiplier).div(BASE_MULTIPLIER);
        uint256 addAmount = amount.mul(currentMultiplier).div(BASE_MULTIPLIER);
        uint128 newMultiplier = uint128(prevAmount.add(addAmount).mul(BASE_MULTIPLIER).div(prevBalance.add(amount)));

        return newMultiplier;
    }

    /*
     * Checks if an epoch is initialized, meaning we have a pool size set for it
     */
    function epochIsInitialized(address token, uint128 epochId) public view returns (bool) {
        return poolSize[token][epochId].set;
    }

    function getCheckpointBalance(Checkpoint memory c) internal pure returns (uint256) {
        return c.startBalance.add(c.newDeposits);
    }

    function getCheckpointEffectiveBalance(Checkpoint memory c) internal pure returns (uint256) {
        return getCheckpointBalance(c).mul(c.multiplier).div(BASE_MULTIPLIER);
    }


    // Base holding rewards tracking. See ERC20UpgradeableFromERC777Rewardable.

    uint256 constant BASE_MASK     = 0xffffffffffffffffffffffff000000000000000000000000;
    uint256 constant BALANCE_MASK  = 0x000000000000000000000000ffffffffffffffffffffffff;

    uint256 constant SHIFT = 2 ** 128;

    // 60 sec * 60 min * 24 hours * 360 days (mortgage year)
    uint256 constant SECONDS_PER_YEAR = 31104000;

    // Start time of rewards earning. June 1st 2022.
    uint256 constant STARTING_TIME = 1654041600;

    /**
     * @dev
     */
    function _getBalance(uint256 balanceStorage) private view returns (uint256) {
        return balanceStorage & BALANCE_MASK;
    }

    /**
     * @dev
     */
    function _getBase(uint256 balanceStorage) private view returns (uint256) {
        uint256 base = (balanceStorage & BASE_MASK).div(SHIFT);

        if (base == 0) {
            base = block.timestamp;
            if (_getBalance(balanceStorage) > 0) {
                base = STARTING_TIME;
            }
        }
        return base;
    }

    /**
     * @dev
     */
    function _getTokenSeconds(uint256 balanceStorage) private view returns (uint256) {
        return (block.timestamp.sub(_getBase(balanceStorage)).mul(_getBalance(balanceStorage)));
    }

    /**
     * @dev
     */
    function _setBalance(address account, address tokenAddress, uint256 balance) private {
        uint256 balanceStorage = balances[account][tokenAddress];

        if (balance == 0) {
            _accrued[account] += _getTokenSeconds(balanceStorage).div(SECONDS_PER_YEAR);
            balances[account][tokenAddress] = 0;
        } else {
            uint256 newBase = block.timestamp;
            if (_getTokenSeconds(balanceStorage).div(balance) < block.timestamp) {
                newBase = block.timestamp.sub(_getTokenSeconds(balanceStorage).div(balance));
            } else {
                _accrued[account] += _getTokenSeconds(balanceStorage).div(SECONDS_PER_YEAR);
            }
            balances[account][tokenAddress] = newBase.mul(SHIFT) | (balance & BALANCE_MASK);
        }
    }

    /**
     * @dev
     */
    function getAndClearReward(address account, address tokenAddress) external returns (uint256) {
        require(isApproved[msg.sender], "Caller must be an approved");

        uint256 reward = _getTokenSeconds(balances[account][tokenAddress]).div(SECONDS_PER_YEAR);

        reward += _accrued[account];
        _accrued[account] = 0;

        balances[account][tokenAddress] = block.timestamp.mul(SHIFT) | ((balances[account][tokenAddress]) & BALANCE_MASK);

        return reward;
    }
}