// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;

// Have to use SafeERC20Upgradeable instead of SafeERC20 because SafeERC20 inherits Address.sol,
// which uses delegeatecall functions, which are not allowed by OZ's upgrade process
// See more:
// https://forum.openzeppelin.com/t/error-contract-is-not-upgrade-safe-use-of-delegatecall-is-not-allowed/16859
import { SafeERC20Upgradeable, IERC20Upgradeable } from "../../lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { ReentrancyGuardUpgradeable } from "../../lib/openzeppelin-contracts-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";

import { IWrappy } from "../external/IWrappy.sol";
import { CoreReference } from "../refs/CoreReference.sol";
import { VaultStorage } from "./VaultStorage.sol";
import { IVault } from "./IVault.sol";

/// @notice Contains the primary logic for vaults
/// @author Recursive Research Inc
abstract contract Vault is IVault, CoreReference, ReentrancyGuardUpgradeable, VaultStorage {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 public constant TOKEN0 = keccak256("TOKEN0");
    bytes32 public constant TOKEN1 = keccak256("TOKEN1");

    uint256 public constant RAY = 1e27;
    uint256 public constant POOL_ERR = 50; // 0.5% error margin allowed
    uint256 public constant DENOM = 10_000;
    uint256 public constant MIN_LP = 1000; // minimum amount of tokens to be deposited as LP

    // ----------- Upgradeable Constructor Pattern -----------

    /// Initializes the vault to point to the Core contract and configures it to have
    /// a given epoch duration, pair of tokens, and floor returns on each Token
    /// @param coreAddress address of the Core contract
    /// @param _epochDuration duration of the epoch in seconds
    /// @param _token0 address of TOKEN0
    /// @param _token1 address of TOKEN1
    /// @param _token0FloorNum the floor returns of the TOKEN0 side (out of `DENOM`). In practice,
    ///     10000 to guarantee lossless returns for the TOKEN0 side.
    /// @param _token1FloorNum the floor returns of the TOKEN1 side (out of `DENOM`). In practice,
    ///     500 to prevent accounting errors.
    function __Vault_init(
        address coreAddress,
        uint256 _epochDuration,
        address _token0,
        address _token1,
        uint256 _token0FloorNum,
        uint256 _token1FloorNum
    ) internal onlyInitializing {
        __CoreReference_init(coreAddress);
        __ReentrancyGuard_init();
        __Vault_init_unchained(_epochDuration, _token0, _token1, _token0FloorNum, _token1FloorNum);
    }

    function __Vault_init_unchained(
        uint256 _epochDuration,
        address _token0,
        address _token1,
        uint256 _token0FloorNum,
        uint256 _token1FloorNum
    ) internal onlyInitializing {
        require(_token0FloorNum > 0, "INVALID_TOKEN0_FLOOR");
        require(_token1FloorNum > 0, "INVALID_TOKEN1_FLOOR");

        isNativeVault = _token0 == core.wrappedNative();

        token0 = IERC20Upgradeable(_token0);
        token1 = IERC20Upgradeable(_token1);

        token0Data.epochToRate[0] = RAY;
        token1Data.epochToRate[0] = RAY;
        epoch = 1;
        epochDuration = _epochDuration;
        token0FloorNum = _token0FloorNum;
        token1FloorNum = _token1FloorNum;
    }

    modifier onlyParticipantOrStrategist(address _user) {
        (uint256 depositedToken0, uint256 pendingToken0, ) = this.token0Balance(_user);
        (uint256 depositedToken1, uint256 pendingToken1, ) = this.token1Balance(_user);
        require(
            depositedToken0 + pendingToken0 + depositedToken1 + pendingToken1 > 0 || _isStrategist(_user),
            "NOT_PARTICIPANT_OR_STRATEGIST"
        );
        _;
    }
    modifier whenDepositsEnabled() {
        require(depositsEnabled, "DEPOSITS_DISABLED");
        _;
    }

    // ----------- Deposit Requests -----------

    /// @notice schedules a deposit of TOKEN0 into the floor tranche
    /// @dev currently does not support fee on transfer / deflationary tokens.
    /// @param _amount the amount of the TOKEN0 to schedule-deposit if a non native vault,
    ///     and unused if it's a native vault. msg.value must be zero if not a native vault
    ///     typechain does not allow payable function overloading so we can either have 2 different
    ///     names or consolidate them into the same function as we do here
    function depositToken0(uint256 _amount) external payable override whenDepositsEnabled whenNotPaused nonReentrant {
        if (isNativeVault) {
            IWrappy(address(token0)).deposit{ value: msg.value }();
            _depositAccounting(token0Data, msg.value, TOKEN0);
        } else {
            require(msg.value == 0, "NOT_NATIVE_VAULT");
            token0.safeTransferFrom(msg.sender, address(this), _amount);
            _depositAccounting(token0Data, _amount, TOKEN0);
        }
    }

    /// @notice schedules a deposit of the TOKEN1 into the ceiling tranche
    /// @dev currently does not support fee on transfer / deflationary tokens.
    /// @param _amount the amount of the TOKEN1 to schedule-deposit
    function depositToken1(uint256 _amount) external override whenDepositsEnabled whenNotPaused nonReentrant {
        token1.safeTransferFrom(msg.sender, address(this), _amount);
        _depositAccounting(token1Data, _amount, TOKEN1);
    }

    /// @dev handles the accounting for scheduling deposits in a way that abstracts the logic
    /// @param assetData storage reference to the data for the desired asset
    /// @param _depositAmount the amount of the asset to deposit
    /// @param assetCode code for the type of asset (either `TOKEN0` or `TOKEN1`)
    function _depositAccounting(
        AssetData storage assetData,
        uint256 _depositAmount,
        bytes32 assetCode
    ) private {
        require(_depositAmount > 0, "ZERO_AMOUNT");
        uint256 currEpoch = epoch;

        // Check their prior deposit requests and flush to balanceDay0 if needed
        assetData.balanceDay0[msg.sender] = __updateDepositRequests(assetData, currEpoch, _depositAmount);

        // track total deposit requests
        assetData.depositRequestsTotal += _depositAmount;

        emit DepositScheduled(assetCode, msg.sender, _depositAmount, currEpoch);
    }

    /// @dev for updating the deposit requests with any new deposit amount
    /// or flushing the deposits to balanceDay0 if the epoch of the request has passed
    /// @param assetData storage reference to the data for the desired asset
    /// @param currEpoch current epoch (passed to save a storage read)
    /// @param _depositAmount amount of deposits
    /// @return newBalanceDay0 new balance day 0 of the user (returned to save a storage read)
    function __updateDepositRequests(
        AssetData storage assetData,
        uint256 currEpoch,
        uint256 _depositAmount
    ) private returns (uint256 newBalanceDay0) {
        Request storage req = assetData.depositRequests[msg.sender];

        uint256 balance = assetData.balanceDay0[msg.sender];
        uint256 reqAmount = req.amount;

        // If they have a prior request
        if (reqAmount > 0 && req.epoch < currEpoch) {
            // and if it was from a prior epoch
            // we now know the exchange rate at that epoch,
            // so we can add to their balance
            uint256 conversionRate = assetData.epochToRate[req.epoch];
            // will not overflow even if value = total mc of crypto
            balance += (reqAmount * RAY) / conversionRate;

            reqAmount = 0;
        }

        if (_depositAmount > 0) {
            // if they don't have a prior request, store this one (if this is a non-zero deposit)
            reqAmount += _depositAmount;
            req.epoch = currEpoch;
        }
        req.amount = reqAmount;

        return balance;
    }

    // ----------- Withdraw Requests -----------

    /// @notice schedules a withdrawal of TOKEN0 from the floor tranche
    /// @param _amount amount of Day 0 TOKEN0 to withdraw
    function withdrawToken0(uint256 _amount) external override whenNotPaused nonReentrant {
        _withdrawAccounting(token0Data, _amount, TOKEN0);
    }

    /// @notice schedules a withdrawal of the TOKEN1 from the ceiling tranche
    /// @param _amount amount of Day 0 TOKEN1 to withdraw
    function withdrawToken1(uint256 _amount) external override whenNotPaused nonReentrant {
        _withdrawAccounting(token1Data, _amount, TOKEN1);
    }

    /// @dev handles the accounting for schedules withdrawals in a way that abstracts the logic
    /// @param assetData storage reference to the data for the desired asset
    /// @param _withdrawAmountDay0 the amount of the asset to withdraw
    /// @param assetCode code for the type of asset (either `TOKEN0` or `TOKEN1`)
    function _withdrawAccounting(
        AssetData storage assetData,
        uint256 _withdrawAmountDay0,
        bytes32 assetCode
    ) private {
        require(_withdrawAmountDay0 > 0, "ZERO_AMOUNT");
        uint256 currEpoch = epoch;

        // Check if they have any deposit request that
        // might not have been flushed to the deposit mapping yet
        uint256 userBalanceDay0 = __updateDepositRequests(assetData, currEpoch, 0);

        // See if there were any existing withdraw requests
        Request storage req = assetData.withdrawRequests[msg.sender];
        if (req.amount > 0 && req.epoch < currEpoch) {
            // If there was a request from a previous epoch, we now know the corresponding amount
            // that was withdrawn and we can add it to the accumulated amount of claimable assets
            // tokenAmount * epochToRate will not overflow even if value = total mc of crypto & rate = 3.8e10 * RAY
            assetData.claimable[msg.sender] += (req.amount * assetData.epochToRate[req.epoch]) / RAY;
            req.amount = 0;
        }

        // Subtract the amount they way to withdraw from their deposit amount
        // Want to explicitly send out own reversion message
        require(userBalanceDay0 >= _withdrawAmountDay0, "INSUFFICIENT_BALANCE");
        unchecked {
            assetData.balanceDay0[msg.sender] = userBalanceDay0 - _withdrawAmountDay0;
        }

        // Add it to their withdraw request and log the epoch
        req.amount = _withdrawAmountDay0 + req.amount;
        if (req.epoch < currEpoch) {
            req.epoch = currEpoch;
        }

        // track total withdraw requests
        assetData.withdrawRequestsTotal += _withdrawAmountDay0;

        emit WithdrawScheduled(assetCode, msg.sender, _withdrawAmountDay0, currEpoch);
    }

    // ----------- Claim Functions -----------

    /// @notice allows the user (`msg.sender`) to claim the TOKEN0 they have a right to once
    /// withdrawal requests are processed
    function claimToken0() external override whenNotPaused nonReentrant {
        uint256 claim = _claimAccounting(token0Data, TOKEN0);

        if (isNativeVault) {
            IWrappy(address(token0)).withdraw(claim);
            (bool success, ) = msg.sender.call{ value: claim }("");
            require(success, "TRANSFER_FAILED");
        } else {
            token0.safeTransfer(msg.sender, claim);
        }
    }

    /// @notice allows the user (`msg.sender`) to claim the TOKEN1 they have a right to once
    /// withdrawal requests are processed
    function claimToken1() external override whenNotPaused nonReentrant {
        uint256 claim = _claimAccounting(token1Data, TOKEN1);
        token1.safeTransfer(msg.sender, claim);
    }

    /// @notice calculates the current amount of an asset the user (`msg.sender`) has claim to
    /// after withdrawal requests are processed and abstracts away the accounting logic
    /// @param assetData storage reference to the data for the desired asset
    /// @return _claim amount of the asset the user has a claim to
    /// @param assetCode code for the type of asset (either `TOKEN0` or `TOKEN1`)
    function _claimAccounting(AssetData storage assetData, bytes32 assetCode) private returns (uint256 _claim) {
        Request storage withdrawReq = assetData.withdrawRequests[msg.sender];
        uint256 currEpoch = epoch;
        uint256 withdrawEpoch = withdrawReq.epoch;

        uint256 claimable = assetData.claimable[msg.sender];
        if (withdrawEpoch < currEpoch) {
            // If epoch ended, calculate the amount they can withdraw
            uint256 withdrawAmountDay0 = withdrawReq.amount;
            if (withdrawAmountDay0 > 0) {
                delete assetData.withdrawRequests[msg.sender];
                // tokenAmount * epochToRate will not overflow even if value = total mc of crypto & rate = 3.8e10 * RAY
                claimable += (withdrawAmountDay0 * assetData.epochToRate[withdrawEpoch]) / RAY;
            }
        }

        require(claimable > 0, "NO_CLAIM");
        assetData.claimable[msg.sender] = 0;
        assetData.claimableTotal -= claimable;
        emit AssetsClaimed(assetCode, msg.sender, claimable);
        return claimable;
    }

    // ----------- Balance Functions -----------

    /// @notice gets a user's current TOKEN0 balance
    /// @param user address of the user in which whose balance we are interested
    /// @return deposited amount of deposited TOKEN0 in the protocol
    /// @return pendingDeposit amount of TOKEN0 pending deposit
    /// @return claimable amount of TOKEN0 ready to be withdrawn
    function token0Balance(address user)
        external
        view
        override
        returns (
            uint256 deposited,
            uint256 pendingDeposit,
            uint256 claimable
        )
    {
        return _balance(token0Data, user);
    }

    /// @notice gets a user's current TOKEN1 balance
    /// @param user address of the user in which whose balance we are interested
    /// @return deposited amount of deposited TOKEN1 in the protocol
    /// @return pendingDeposit amount of TOKEN1 pending deposit
    /// @return claimable amount of TOKEN1 ready to be withdrawn
    function token1Balance(address user)
        external
        view
        override
        returns (
            uint256 deposited,
            uint256 pendingDeposit,
            uint256 claimable
        )
    {
        return _balance(token1Data, user);
    }

    /// @dev handles the balance calculations in a way that abstracts the logic
    /// @param assetData storage reference to the data for the desired asset
    /// @param user address of the user in which whose balance we are interested
    /// @return _deposited amount of their asset that is deposited in the protocol
    /// @return _pendingDeposit amount of their asset pending deposit
    /// @return _claimable amount of their asset ready to be withdrawn
    function _balance(AssetData storage assetData, address user)
        private
        view
        returns (
            uint256 _deposited,
            uint256 _pendingDeposit,
            uint256 _claimable
        )
    {
        uint256 currEpoch = epoch;

        uint256 balanceDay0 = assetData.balanceDay0[user];

        // then check if they have any open deposit requests
        Request memory depositReq = assetData.depositRequests[user];
        uint256 depositAmt = depositReq.amount;
        uint256 depositEpoch = depositReq.epoch;

        if (depositAmt > 0) {
            // if they have one from a previous epoch, add the Day 0 amount that
            // deposit is worth
            if (depositEpoch < currEpoch) {
                balanceDay0 += (depositAmt * RAY) / assetData.epochToRate[depositEpoch];
            } else {
                // if they have one from this epoch, set the flat amount
                _pendingDeposit = depositAmt;
            }
        }

        // Check their withdraw requests, because if they made one
        // their deposit balances would have been flushed to here
        Request memory withdrawReq = assetData.withdrawRequests[user];
        _claimable = assetData.claimable[user];
        if (withdrawReq.amount > 0) {
            // if they have one from a previous epoch, calculate that
            // requests day 0 Value
            if (withdrawReq.epoch < currEpoch) {
                _claimable += (withdrawReq.amount * assetData.epochToRate[withdrawReq.epoch]) / RAY;
            } else {
                // if they have one from this epoch, that means the tokens are still active
                balanceDay0 += withdrawReq.amount;
            }
        }

        /* TODO: this would be better calculated if we simulated ending the epoch here
        because this doesn't consider the IL / profits from this current epoch
        but this is fine for now */
        // Note that currEpoch >= 1 since it is initialized to 1 in the constructor
        uint256 currentConversionRate = assetData.epochToRate[currEpoch - 1];

        // tokenAmount * epochToRate will not overflow even if value = total mc of crypto & rate = 3.8e10 * RAY
        return ((balanceDay0 * currentConversionRate) / RAY, _pendingDeposit, _claimable);
    }

    // ----------- Next Epoch Functions -----------

    /// @notice Struct just for wrapper around local variables to avoid the stack limit in `nextEpoch()`
    struct NextEpochVariables {
        uint256 poolBalance;
        uint256 withdrawn;
        uint256 available;
        uint256 original;
        uint256 newRate;
        uint256 newClaimable;
    }

    /// @notice Initiates the next epoch
    /// @param expectedPoolToken0 the approximate amount of TOKEN0 expected to be in the pool (preventing frontrunning)
    /// @param expectedPoolToken1 the approximate amount of TOKEN1 expected to be in the pool (preventing frontrunning)
    function nextEpoch(uint256 expectedPoolToken0, uint256 expectedPoolToken1)
        external
        override
        onlyParticipantOrStrategist(msg.sender)
        whenNotPaused
    {
        require(block.timestamp - lastEpochStart >= epochDuration, "EPOCH_DURATION_UNMET");

        AssetDataStatics memory _token0Data = _assetDataStatics(token0Data);
        AssetDataStatics memory _token1Data = _assetDataStatics(token1Data);
        // These are used to avoid hitting the local variable stack limit
        NextEpochVariables memory _token0;
        NextEpochVariables memory _token1;

        uint256 currEpoch = epoch;

        // Total tokens in the liquidity pool and our ownership of those tokens
        (_token0.poolBalance, _token1.poolBalance) = getPoolBalances();
        // will not overflow with reasonable expectedPoolToken amount (DENOM = 10,000)
        require(_token0.poolBalance >= (expectedPoolToken0 * (DENOM - POOL_ERR)) / DENOM, "UNEXPECTED_POOL_BALANCES");
        require(_token0.poolBalance <= (expectedPoolToken0 * (DENOM + POOL_ERR)) / DENOM, "UNEXPECTED_POOL_BALANCES");
        require(_token1.poolBalance >= (expectedPoolToken1 * (DENOM - POOL_ERR)) / DENOM, "UNEXPECTED_POOL_BALANCES");
        require(_token1.poolBalance <= (expectedPoolToken1 * (DENOM + POOL_ERR)) / DENOM, "UNEXPECTED_POOL_BALANCES");
        // !!NOTE: After this point we don't need to worry about front-running anymore because the pool's state has been
        // verified (as long as there is no calls to untrusted external parties)

        // (1) Withdraw liquidity
        (_token0.withdrawn, _token1.withdrawn) = withdrawLiquidity();
        (_token0.poolBalance, _token1.poolBalance) = getPoolBalances();
        _token0.available = _token0.withdrawn + _token0Data.reserves;
        _token1.available = _token1.withdrawn + _token1Data.reserves;

        // (2) Perform the swap

        // Calculate the floor and ceiling returns for each side
        // will not overflow with reasonable amounts (token0/1FloorNum ~ 10,000)
        uint256 token0Floor = _token0Data.reserves + (_token0Data.active * token0FloorNum) / DENOM;
        uint256 token1Floor = _token1Data.reserves + (_token1Data.active * token1FloorNum) / DENOM;
        uint256 token1Ceiling = _token1Data.reserves + _token1Data.active;
        // Add interest to the token1 ceiling (but we don't for this version)
        // token1Ceiling += (_token1Data.active * timePassed * tokenInterest) / (RAY * 365 days);

        if (token0Floor > _token0.available) {
            // The min amount needed to reach the TOKEN0 floor
            uint256 token1NeededToSwap;
            uint256 token0Deficit = token0Floor - _token0.available;
            if (token0Deficit > _token0.poolBalance) {
                token1NeededToSwap = _token1.available;
            } else {
                token1NeededToSwap = calcAmountIn(token0Deficit, _token1.poolBalance, _token0.poolBalance);
            }

            // swap as much token1 as is necessary to get back to the token0 floor, without going
            // under the token1 floor
            uint256 swapAmount = (token1Ceiling + token1NeededToSwap < _token1.available)
                ? _token1.available - token1Ceiling
                : token1NeededToSwap + token1Floor > _token1.available
                ? _token1.available - token1Floor
                : token1NeededToSwap;

            (uint256 amountOut, uint256 amountConsumed) = swap(token1, token0, swapAmount);
            _token0.available += amountOut;
            _token1.available -= amountConsumed;
        } else if (_token1.available >= token1Ceiling) {
            // If we have more token0 than the floor and more token1 than the ceiling so we swap the excess amount
            // all to TOKEN0

            (uint256 amountOut, uint256 amountConsumed) = swap(token1, token0, _token1.available - token1Ceiling);
            _token0.available += amountOut;
            _token1.available -= amountConsumed;
        } else {
            // We have more token0 than the floor but are below the token1 ceiling
            // Min amount of TOKEN0 needed to swap to hit the token1 ceiling
            uint256 token0NeededToSwap;
            uint256 token1Deficit = token1Ceiling - _token1.available;
            if (token1Deficit > _token1.poolBalance) {
                token0NeededToSwap = _token0.poolBalance;
            } else {
                token0NeededToSwap = calcAmountIn(token1Deficit, _token0.poolBalance, _token1.poolBalance);
            }

            if (token0Floor + token0NeededToSwap < _token0.available) {
                // If we can reach the token1 ceiling without going through the TOKEN0 floor
                (uint256 amountOut, uint256 amountConsumed) = swap(token0, token1, token0NeededToSwap);
                _token0.available -= amountConsumed;
                _token1.available += amountOut;
            } else {
                // We swap as much TOKEN0 as we can without going through the TOKEN0 floor
                (uint256 amountOut, uint256 amountConsumed) = swap(token0, token1, _token0.available - token0Floor);
                _token0.available -= amountConsumed;
                _token1.available += amountOut;
            }
        }

        // (3) Add in new deposits and subtract withdrawals
        _token0.original = _token0Data.reserves + _token0Data.active;
        _token1.original = _token1Data.reserves + _token1Data.active;

        // collect protocol fee if profitable
        if (_token0.available > _token0.original) {
            // will not overflow core.protocolFee() < 10,000
            _token0.available -= ((_token0.available - _token0.original) * core.protocolFee()) / core.MAX_FEE();
        }
        if (_token1.available > _token1.original) {
            // will not overflow core.protocolFee() < 10,000
            _token1.available -= ((_token1.available - _token1.original) * core.protocolFee()) / core.MAX_FEE();
        }

        // calculate new rate (before withdraws and deposits) as available tokens divided by
        // tokens that were available at the beginning of the epoch
        // and tally claimable amount (withdraws that are now accounted for) for this token
        // tokenAmount * epochToRate will not overflow even if value = total mc of crypto & rate = 3.8e10 * RAY
        _token0.newRate = _token0.original > 0
            ? (token0Data.epochToRate[currEpoch - 1] * _token0.available) / _token0.original // no overflow
            : token0Data.epochToRate[currEpoch - 1];
        token0Data.epochToRate[currEpoch] = _token0.newRate;
        _token0.newClaimable = (_token0Data.withdrawRequestsTotal * _token0.newRate) / RAY; // no overflow
        token0Data.claimableTotal += _token0.newClaimable;
        _token1.newRate = _token1.original > 0
            ? (token1Data.epochToRate[currEpoch - 1] * _token1.available) / _token1.original // no overflow
            : token1Data.epochToRate[currEpoch - 1];
        token1Data.epochToRate[currEpoch] = _token1.newRate;
        _token1.newClaimable = (_token1Data.withdrawRequestsTotal * _token1.newRate) / RAY; // no overflow
        token1Data.claimableTotal += _token1.newClaimable;

        // calculate available token after deposits and withdraws
        _token0.available = _token0.available + _token0Data.depositRequestsTotal - _token0.newClaimable;
        _token1.available = _token1.available + _token1Data.depositRequestsTotal - _token1.newClaimable;

        token0Data.depositRequestsTotal = 0;
        token0Data.withdrawRequestsTotal = 0;
        token1Data.depositRequestsTotal = 0;
        token1Data.withdrawRequestsTotal = 0;

        // (4) Deposit liquidity back in
        (token0Data.active, token1Data.active) = depositLiquidity(_token0.available, _token1.available);
        token0Data.reserves = _token0.available - token0Data.active;
        token1Data.reserves = _token1.available - token1Data.active;

        epoch += 1;
        lastEpochStart = block.timestamp;

        emit NextEpochStarted(epoch, msg.sender, block.timestamp);
    }

    function _assetDataStatics(AssetData storage assetData) internal view returns (AssetDataStatics memory) {
        return
            AssetDataStatics({
                reserves: assetData.reserves,
                active: assetData.active,
                depositRequestsTotal: assetData.depositRequestsTotal,
                withdrawRequestsTotal: assetData.withdrawRequestsTotal
            });
    }

    // ----------- Abstract Functions Implemented For Each DEX -----------

    function getPoolBalances() internal view virtual returns (uint256 poolToken0, uint256 poolToken1);

    /// @dev This is provided automatically by the Uniswap router
    function calcAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal view virtual returns (uint256 amountIn);

    /// @dev Withdraws all liquidity
    function withdrawLiquidity() internal returns (uint256 token0Withdrawn, uint256 token1Withdrawn) {
        // the combination of `unstakeLiquidity` and `_withdrawLiquidity` should never result in a decreased
        // balance of either token. If they do, this transaction will revert.
        uint256 token0BalanceBefore = token0.balanceOf(address(this));
        uint256 token1BalanceBefore = token1.balanceOf(address(this));
        _unstakeLiquidity();
        _withdrawLiquidity();
        token0Withdrawn = token0.balanceOf(address(this)) - token0BalanceBefore;
        token1Withdrawn = token1.balanceOf(address(this)) - token1BalanceBefore;
    }

    function _withdrawLiquidity() internal virtual;

    /// @dev Deposits liquidity into the pool
    function depositLiquidity(uint256 availableToken0, uint256 availableToken1)
        internal
        returns (uint256 token0Deposited, uint256 token1Deposited)
    {
        // ensure sufficient liquidity is minted, if < MIN_LP don't activate those funds
        if ((availableToken0 < MIN_LP) || (availableToken1 < MIN_LP)) return (0, 0);
        (token0Deposited, token1Deposited) = _depositLiquidity(availableToken0, availableToken1);
        _stakeLiquidity();
    }

    function _depositLiquidity(uint256 availableToken0, uint256 availableToken1)
        internal
        virtual
        returns (uint256 token0Deposited, uint256 token1Deposited);

    /// @dev Swaps tokens and handles the case where amountIn == 0
    function swap(
        IERC20Upgradeable tokenIn,
        IERC20Upgradeable tokenOut,
        uint256 amountIn
    ) internal virtual returns (uint256 amountOut, uint256 amountConsumed);

    // ----------- Rescue Funds -----------

    /// @notice rescues funds from this contract in dire situations, only when contract is paused
    /// @param tokens array of tokens to rescue
    /// @param amounts list of amounts for each token to rescue. If 0, the full balance
    function rescueTokens(address[] calldata tokens, uint256[] calldata amounts)
        external
        override
        nonReentrant
        onlyGuardian
        whenPaused
    {
        require(tokens.length == amounts.length, "INVALID_INPUTS");

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 amount = amounts[i];
            if (tokens[i] == address(0)) {
                amount = (amount == 0) ? address(this).balance : amount;
                (bool success, ) = msg.sender.call{ value: amount }("");
                require(success, "TRANSFER_FAILED");
            } else {
                amount = (amount == 0) ? IERC20Upgradeable(tokens[i]).balanceOf(address(this)) : amount;
                IERC20Upgradeable(tokens[i]).safeTransfer(msg.sender, amount);
            }
        }
        emit FundsRescued(msg.sender);
    }

    /// @notice A function that should be called by the guardian to unstake any liquidity before rescuing LP tokens
    function unstakeLiquidity() external override nonReentrant onlyGuardian whenPaused {
        _unstakeLiquidity();
    }

    /// @notice stakes all LP tokens
    function _unstakeLiquidity() internal virtual;

    /// @notice unstakes all LP tokens
    function _stakeLiquidity() internal virtual;

    // ----------- Getter Functions -----------

    function token0ValueLocked() external view override returns (uint256) {
        return token0.balanceOf(address(this)) + token0Data.active;
    }

    function token1ValueLocked() external view override returns (uint256) {
        return token1.balanceOf(address(this)) + token1Data.active;
    }

    function token0BalanceDay0(address user) external view override returns (uint256) {
        return __user_balanceDay0(token0Data, user);
    }

    function epochToToken0Rate(uint256 _epoch) external view override returns (uint256) {
        return token0Data.epochToRate[_epoch];
    }

    function token0WithdrawRequests(address user) external view override returns (uint256) {
        return __user_requestView(token0Data.withdrawRequests[user]);
    }

    function token1BalanceDay0(address user) external view override returns (uint256) {
        return __user_balanceDay0(token1Data, user);
    }

    function epochToToken1Rate(uint256 _epoch) external view override returns (uint256) {
        return token1Data.epochToRate[_epoch];
    }

    function token1WithdrawRequests(address user) external view override returns (uint256) {
        return __user_requestView(token1Data.withdrawRequests[user]);
    }

    /// @dev This function is used to convert the way balances are internally stored to
    /// what makes sense for the user
    function __user_balanceDay0(AssetData storage assetData, address user) internal view returns (uint256) {
        uint256 res = assetData.balanceDay0[user];
        Request memory depositReq = assetData.depositRequests[user];
        if (depositReq.epoch < epoch) {
            // will not overflow even if value = total mc of crypto
            res += (depositReq.amount * RAY) / assetData.epochToRate[depositReq.epoch];
        }
        Request memory withdrawReq = assetData.withdrawRequests[user];
        if (withdrawReq.epoch == epoch) {
            // This amount has not been withdrawn yet so this is still part of
            // their Day 0 Balance
            res += withdrawReq.amount;
        }
        return res;
    }

    /// @dev This function is used to convert the way requests are internally stored to
    /// what makes sense for the user
    function __user_requestView(Request memory req) internal view returns (uint256) {
        if (req.epoch < epoch) {
            return 0;
        }
        return req.amount;
    }

    /// @notice calculates current amount of fees accrued, as the current balance of each token
    /// less the amounts each tokens that are active user funds. token0Data.active is not
    /// included because they are currently in the DEX pool
    function feesAccrued() public view override returns (uint256 token0Fees, uint256 token1Fees) {
        token0Fees =
            token0.balanceOf(address(this)) -
            token0Data.claimableTotal -
            token0Data.reserves -
            token0Data.depositRequestsTotal;
        token1Fees =
            token1.balanceOf(address(this)) -
            token1Data.claimableTotal -
            token1Data.reserves -
            token1Data.depositRequestsTotal;
    }

    /// ------------------- Setters -------------------

    /// @notice sets a new value for the token0 floor
    /// @param _token0FloorNum the new floor token0 returns (out of `DENOM`)
    function setToken0Floor(uint256 _token0FloorNum) external override onlyStrategist {
        require(_token0FloorNum > 0, "INVALID_TOKEN0_FLOOR");
        token0FloorNum = _token0FloorNum;
        emit Token0FloorUpdated(_token0FloorNum);
    }

    /// @notice sets a new value for the token1 floor
    /// @param _token1FloorNum the new floor token1 returns (out of `DENOM`)
    function setToken1Floor(uint256 _token1FloorNum) external override onlyStrategist {
        require(_token1FloorNum > 0, "INVALID_TOKEN1_FLOOR");
        token1FloorNum = _token1FloorNum;
        emit Token1FloorUpdated(_token1FloorNum);
    }

    function setEpochDuration(uint256 _epochDuration) external override onlyStrategist whenPaused {
        epochDuration = _epochDuration;
        emit EpochDurationUpdated(_epochDuration);
    }

    /// @notice sends accrued fees to the core.feeTo() address, the treasury
    function collectFees() external override {
        (uint256 token0Fees, uint256 token1Fees) = feesAccrued();
        if (token0Fees > 0) {
            token0.safeTransfer(core.feeTo(), token0Fees);
        }
        if (token1Fees > 0) {
            token1.safeTransfer(core.feeTo(), token1Fees);
        }
    }

    function setDepositsEnabled() external onlyStrategist whenPaused {
        depositsEnabled = true;
    }

    function setDepositsDisabled() external onlyStrategist whenPaused {
        depositsEnabled = false;
    }

    // To receive any native token sent here (ex. from wrapped native withdraw)
    receive() external payable {
        // no logic upon reciept of native token required
    }
}