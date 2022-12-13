// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "contracts/interfaces/IERC721Transferable.sol";
import "contracts/interfaces/IStakingNFT.sol";
import "contracts/libraries/errors/LockupErrors.sol";
import "contracts/libraries/lockup/AccessControlled.sol";
import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/utils/auth/ImmutablePublicStaking.sol";
import "contracts/utils/auth/ImmutableALCA.sol";
import "contracts/utils/EthSafeTransfer.sol";
import "contracts/utils/ERC20SafeTransfer.sol";
import "contracts/BonusPool.sol";
import "contracts/RewardPool.sol";

/**
 * @notice This contract locks up publicStaking position for a certain period. The position is
 *  transferred to this contract, and the original owner is entitled to collect profits, and unlock
 *  the position. If the position was kept locked until the end of the locking period, the original
 *  owner will be able to get the original position back, plus any profits gained by the position
 *  (e.g from ALCB sale) + a bonus amount based on the amount of shares of the public staking
 *  position.
 *
 *  Original owner will be able to collect profits from the position normally during the locking
 *  period. However, a certain percentage will be held by the contract and only distributed after the
 *  locking period has finished and the user unlocks.
 *
 *  Original owner will be able to unlock position (partially or fully) before the locking period has
 *  finished. The owner will able to decide which will be the amount unlocked earlier (called
 *  exitAmount). In case of full exit (exitAmount == positionShares), the owner will not get the
 *  percentage of profits of that position that are held by this contract and he will not receive any
 *  bonus amount. In case, of partial exit (exitAmount < positionShares), the owner will be loosing
 *  only the profits + bonus relative to the exiting amount.
 *
 *
 * @dev deployed by the AliceNetFactory contract
 */

/// @custom:salt Lockup
/// @custom:deploy-type deployCreateAndRegister
/// @custom:deploy-group lockup
/// @custom:deploy-group-index 0
contract Lockup is
    ImmutablePublicStaking,
    ImmutableALCA,
    ERC20SafeTransfer,
    EthSafeTransfer,
    ERC721Holder
{
    enum State {
        PreLock,
        InLock,
        PostLock
    }

    uint256 public constant SCALING_FACTOR = 10 ** 18;
    uint256 public constant FRACTION_RESERVED = SCALING_FACTOR / 5;
    // rewardPool contract address
    address internal immutable _rewardPool;
    // bonusPool contract address
    address internal immutable _bonusPool;
    // block on which lock starts
    uint256 internal immutable _startBlock;
    // block on which lock ends
    uint256 internal immutable _endBlock;
    // Total Locked describes the total number of ALCA locked in this contract.
    // Since no accumulators are used this is tracked to allow proportionate
    // payouts.
    uint256 internal _totalSharesLocked;
    // _ownerOf tracks who is the owner of a tokenID locked in this contract
    // mapping(tokenID -> owner).
    mapping(uint256 => address) internal _ownerOf;
    // _tokenOf is the inverse of ownerOf and returns the owner given the tokenID
    // users are only allowed 1 position per account, mapping (owner -> tokenID).
    mapping(address => uint256) internal _tokenOf;

    // maps and index to a tokenID for iterable counting i.e (index ->  tokenID).
    // Stop iterating when token id is zero. Must use tail insert to delete or else
    // pagination will end early.
    mapping(uint256 => uint256) internal _tokenIDs;
    // lookup index by ID (tokenID -> index).
    mapping(uint256 => uint256) internal _reverseTokenIDs;
    // tracks the number of tokenIDs this contract holds.
    uint256 internal _lenTokenIDs;

    // support mapping to keep track all the ethereum owed to user to be
    // redistributed in the postLock phase during safe mode.
    mapping(address => uint256) internal _rewardEth;
    // support mapping to keep track all the token owed to user to be
    // redistributed in the postLock phase during safe mode.
    mapping(address => uint256) internal _rewardTokens;
    // Flag to determine if we are in the postLock phase safe or unsafe, i.e if
    // users are allowed to withdrawal or not. All profits need to be collect by all
    // positions before setting the safe mode.
    bool public payoutSafe;

    // offset for pagination when collecting the profits in the postLock unsafe
    // phase. Many people may call aggregateProfits until all rewards has been
    // collected.
    uint256 internal _tokenIDOffset;

    event EarlyExit(address to_, uint256 tokenID_);
    event NewLockup(address from_, uint256 tokenID_);

    modifier onlyPreLock() {
        if (_getState() != State.PreLock) {
            revert LockupErrors.PreLockStateRequired();
        }
        _;
    }

    modifier excludePreLock() {
        if (_getState() == State.PreLock) {
            revert LockupErrors.PreLockStateNotAllowed();
        }
        _;
    }

    modifier onlyPostLock() {
        if (_getState() != State.PostLock) {
            revert LockupErrors.PostLockStateRequired();
        }
        _;
    }

    modifier excludePostLock() {
        if (_getState() == State.PostLock) {
            revert LockupErrors.PostLockStateNotAllowed();
        }
        _;
    }

    modifier onlyPayoutSafe() {
        if (!payoutSafe) {
            revert LockupErrors.PayoutUnsafe();
        }
        _;
    }

    modifier onlyPayoutUnSafe() {
        if (payoutSafe) {
            revert LockupErrors.PayoutSafe();
        }
        _;
    }

    modifier onlyInLock() {
        if (_getState() != State.InLock) {
            revert LockupErrors.InLockStateRequired();
        }
        _;
    }

    constructor(
        uint256 enrollmentPeriod_,
        uint256 lockDuration_,
        uint256 totalBonusAmount_
    ) ImmutableFactory(msg.sender) ImmutablePublicStaking() ImmutableALCA() {
        RewardPool rewardPool = new RewardPool(
            _alcaAddress(),
            _factoryAddress(),
            totalBonusAmount_
        );
        _rewardPool = address(rewardPool);
        _bonusPool = rewardPool.getBonusPoolAddress();
        _startBlock = block.number + enrollmentPeriod_;
        _endBlock = _startBlock + lockDuration_;
    }

    /// @dev only publicStaking and rewardPool are allowed to send ether to this contract
    receive() external payable {
        if (msg.sender != _publicStakingAddress() && msg.sender != _rewardPool) {
            revert LockupErrors.AddressNotAllowedToSendEther();
        }
    }

    /// @notice callback function called by the ERC721.safeTransfer. On safe transfer of
    /// publicStaking positions to this contract, it will be performing checks and in case everything
    /// is fine, that position will be locked in name of the original owner that performed the
    /// transfer
    /// @dev publicStaking positions can only be safe transferred to this contract on PreLock phase
    /// (enrollment phase)
    /// @param from_ original owner of the publicStaking Position. The position will locked for this
    /// address
    /// @param tokenID_ The publicStaking tokenID that will be locked up
    function onERC721Received(
        address,
        address from_,
        uint256 tokenID_,
        bytes memory
    ) public override onlyPreLock returns (bytes4) {
        if (msg.sender != _publicStakingAddress()) {
            revert LockupErrors.OnlyStakingNFTAllowed();
        }

        _lockFromTransfer(tokenID_, from_);
        return this.onERC721Received.selector;
    }

    /// @notice transfer and locks a pre-approved publicStaking position to this contract
    /// @dev can only be called at PreLock phase (enrollment phase)
    /// @param tokenID_ The publicStaking tokenID that will be locked up
    function lockFromApproval(uint256 tokenID_) public {
        // msg.sender already approved transfer, so contract can safeTransfer to itself; by doing
        // this onERC721Received is called as part of the chain of transfer methods hence the checks
        // run from within onERC721Received
        IERC721Transferable(_publicStakingAddress()).safeTransferFrom(
            msg.sender,
            address(this),
            tokenID_
        );
    }

    /// @notice locks a position that was already transferred to this contract without using
    /// safeTransfer. WARNING: SHOULD ONLY BE USED FROM SMART CONTRACT THAT TRANSFERS A POSITION AND
    /// CALL THIS METHOD RIGHT IN SEQUENCE
    /// @dev can only be called at PreLock phase (enrollment phase)
    /// @param tokenID_ The publicStaking tokenID that will be locked up
    /// @param tokenOwner_ The address that will be used as the user entitled to that position
    function lockFromTransfer(uint256 tokenID_, address tokenOwner_) public onlyPreLock {
        _lockFromTransfer(tokenID_, tokenOwner_);
    }

    /// @notice collects all profits from a position locked up by this contract. Only a certain
    /// amount of the profits will be sent, the rest will held by the contract and released at the
    /// final unlock.
    /// @dev can only be called if the PostLock phase has not began
    /// @dev can only be called by position's entitled owner
    /// @return payoutEth the amount of eth that was sent to user
    /// @return payoutToken the amount of ALCA that was sent to user
    function collectAllProfits()
        public
        excludePostLock
        returns (uint256 payoutEth, uint256 payoutToken)
    {
        return _collectAllProfits(_payableSender(), _validateAndGetTokenId());
    }

    /// @notice function to partially or fully unlock a locked position. The entitled owner will
    /// able to decide which will be the amount unlocked earlier (exitValue_). In case of full exit
    /// (exitValue_ == positionShares), the owner will not get the percentage of profits of that
    /// position that are held by this contract and he will not receive any bonus amount. In case, of
    /// partial exit (exitValue_< positionShares), the owner will be loosing only the profits + bonus
    /// relative to the exiting amount. The owner may choose via stakeExit_ boolean if the ALCA will be
    /// sent a new publicStaking position or as ALCA directly to his address.
    /// @dev can only be called if the PostLock phase has not began
    /// @dev can only be called by position's entitled owner
    /// @param exitValue_ The amount in which the user wants to unlock earlier
    /// @param stakeExit_ Flag to decide the ALCA will be sent directly or staked as new
    /// publicStaking position
    /// @return payoutEth the amount of eth that was sent to user discounting the reserved amount
    /// @return payoutToken the amount of ALCA discounting the reserved amount that was sent or
    /// staked as new position to the user
    function unlockEarly(
        uint256 exitValue_,
        bool stakeExit_
    ) public excludePostLock returns (uint256 payoutEth, uint256 payoutToken) {
        uint256 tokenID = _validateAndGetTokenId();
        // get the number of shares and check validity
        uint256 shares = _getNumShares(tokenID);
        if (exitValue_ > shares) {
            revert LockupErrors.InsufficientBalanceForEarlyExit(exitValue_, shares);
        }
        // burn the existing position
        (payoutEth, payoutToken) = IStakingNFT(_publicStakingAddress()).burn(tokenID);
        // separating alca reward from alca shares
        payoutToken -= shares;
        // blank old record
        _ownerOf[tokenID] = address(0);
        // create placeholder
        uint256 newTokenID;
        // find shares delta and mint new position
        uint256 remainingShares = shares - exitValue_;
        if (remainingShares > 0) {
            // approve the transfer of ALCA in order to mint the publicStaking position
            IERC20(_alcaAddress()).approve(_publicStakingAddress(), remainingShares);
            // burn profits contain staked position... so sub it out
            newTokenID = IStakingNFT(_publicStakingAddress()).mint(remainingShares);
            // set new records
            _ownerOf[newTokenID] = msg.sender;
            _replaceTokenID(tokenID, newTokenID);
        } else {
            _removeTokenID(tokenID);
        }
        // safe because newTokenId is zero if shares == exitValue
        _tokenOf[msg.sender] = newTokenID;
        _totalSharesLocked -= exitValue_;
        (payoutEth, payoutToken) = _distributeAllProfits(
            _payableSender(),
            payoutEth,
            payoutToken,
            exitValue_,
            stakeExit_
        );
        emit EarlyExit(msg.sender, tokenID);
    }

    /// @notice aggregateProfits iterate alls locked positions and collect their profits before
    /// allowing withdraws/unlocks. This step is necessary to make sure that the correct reserved
    /// amount is in the rewardPool before allowing unlocks. This function will not send any ether or
    /// ALCA to users, since this can be very dangerous (specially on a loop). Instead all the
    /// assets that are not sent to the rewardPool are held in the lockup contract, and the right
    /// balance is stored per position owner. All the value will be send to the owner address at the
    /// call of the `{unlock()}` function. This function can only be called after the locking period
    /// has finished. Anyone can call this function.
    function aggregateProfits() public onlyPayoutUnSafe onlyPostLock {
        // get some gas cost tracking setup
        uint256 gasStart = gasleft();
        uint256 gasLoop;
        // start index where we left off plus one
        uint256 i = _tokenIDOffset + 1;
        // for loop that will exit when one of following is true the gas remaining is less than 5x
        // the estimated per iteration cost or the iterator is done
        for (; ; i++) {
            (uint256 tokenID, bool ok) = _getTokenIDAtIndex(i);
            if (!ok) {
                // if we get here, iteration of array is done and we can move on with life and set
                // payoutSafe since all payouts have been recorded
                payoutSafe = true;
                // burn the bonus Position and send the bonus to the rewardPool contract
                BonusPool(payable(_bonusPool)).terminate();
                break;
            }
            address payable acct = _getOwnerOf(tokenID);
            _collectAllProfits(acct, tokenID);
            uint256 gasRem = gasleft();
            if (gasLoop == 0) {
                // record gas iteration estimate if not done
                gasLoop = gasStart - gasRem;
                // give 5x multi on it to ensure even an overpriced element by 2x the normal
                // cost will still pass
                gasLoop = 5 * gasLoop;
                // accounts for state writes on exit
                gasLoop = gasLoop + 10000;
            } else if (gasRem <= gasLoop) {
                // if we are below cutoff break
                break;
            }
        }
        _tokenIDOffset = i;
    }

    /// @notice unlocks a locked position and collect all kind of profits (bonus shares, held
    /// rewards etc). Can only be called after the locking period has finished and {aggregateProfits}
    /// has been executed for positions. Can only be called by the user entitled to a position
    /// (address that locked a position). This function can only be called after the locking period
    /// has finished and {aggregateProfits()} has been executed for all locked positions.
    /// @param to_ destination address were the profits, shares will be sent
    /// @param stakeExit_ boolean flag indicating if the ALCA should be returned directly or staked
    /// into a new publicStaking position.
    /// @return payoutEth the ether amount deposited to an address after unlock
    /// @return payoutToken the ALCA amount staked or sent to an address after unlock
    function unlock(
        address to_,
        bool stakeExit_
    ) public onlyPostLock onlyPayoutSafe returns (uint256 payoutEth, uint256 payoutToken) {
        uint256 tokenID = _validateAndGetTokenId();
        uint256 shares = _getNumShares(tokenID);
        bool isLastPosition = _lenTokenIDs == 1;

        (payoutEth, payoutToken) = _burnLockedPosition(tokenID, msg.sender);

        (uint256 accumulatedRewardEth, uint256 accumulatedRewardToken) = RewardPool(_rewardPool)
            .payout(_totalSharesLocked, shares, isLastPosition);
        payoutEth += accumulatedRewardEth;
        payoutToken += accumulatedRewardToken;

        (uint256 aggregatedEth, uint256 aggregatedToken) = _withdrawalAggregatedAmount(msg.sender);
        payoutEth += aggregatedEth;
        payoutToken += aggregatedToken;
        _transferEthAndTokensWithReStake(to_, payoutEth, payoutToken, stakeExit_);
    }

    /// @notice gets the address that is entitled to unlock/collect profits for a position. I.e the
    /// address that locked this position into this contract.
    /// @param tokenID_ the position Id to retrieve the owner
    /// @return the owner address of a position. Returns 0 if a position is not locked into this
    /// contract
    function ownerOf(uint256 tokenID_) public view returns (address payable) {
        return _getOwnerOf(tokenID_);
    }

    /// @notice gets the positionID that an address is entitled to unlock/collect profits. I.e
    /// position that an address locked into this contract.
    /// @param acct_ address to retrieve a position (tokenID)
    /// @return the position ID (tokenID) of the position that the address locked into this
    /// contract. If an address doesn't possess any locked position in this contract, this function
    /// returns 0
    function tokenOf(address acct_) public view returns (uint256) {
        return _getTokenOf(acct_);
    }

    /// @notice gets the total number of positions locked into this contract. Can be used with
    /// {getIndexByTokenId} and {getPositionByIndex} to get all publicStaking positions held by this
    /// contract.
    /// @return the total number of positions locked into this contract
    function getCurrentNumberOfLockedPositions() public view returns (uint256) {
        return _lenTokenIDs;
    }

    /// @notice gets the position referenced by an index in the enumerable mapping implemented by
    /// this contract. Can be used {getIndexByTokenId} to get all positions IDs locked by this
    /// contract.
    /// @param index_ the index to get the positionID
    /// @return the tokenId referenced by an index the enumerable mapping (indexes start at 1). If
    /// the index doesn't exists this function returns 0
    function getPositionByIndex(uint256 index_) public view returns (uint256) {
        return _tokenIDs[index_];
    }

    /// @notice gets the index of a position in the enumerable mapping implemented by this contract.
    /// Can be used {getPositionByIndex} to get all positions IDs locked by this contract.
    /// @param tokenID_ the position ID to get index for
    /// @return the index of a position in the enumerable mapping (indexes start at 1). If the
    /// tokenID is not locked into this contract this function returns 0
    function getIndexByTokenId(uint256 tokenID_) public view returns (uint256) {
        return _reverseTokenIDs[tokenID_];
    }

    /// @notice gets the ethereum block where the locking period will start. This block is also
    /// when the enrollment period will finish. I.e after this block we don't allow new positions to
    /// be locked.
    /// @return the ethereum block where the locking period will start
    function getLockupStartBlock() public view returns (uint256) {
        return _startBlock;
    }

    /// @notice gets the ethereum block where the locking period will end. After this block
    /// aggregateProfit has to be called to enable the unlock period.
    /// @return the ethereum block where the locking period will end
    function getLockupEndBlock() public view returns (uint256) {
        return _endBlock;
    }

    /// @notice gets the ether and ALCA balance owed to a user after aggregateProfit has been
    /// called. This funds are send after final unlock.
    /// @return user ether balance held by this contract
    /// @return user ALCA balance held by this contract
    function getTemporaryRewardBalance(address user_) public view returns (uint256, uint256) {
        return _getTemporaryRewardBalance(user_);
    }

    /// @notice gets the RewardPool contract address
    /// @return the reward pool contract address
    function getRewardPoolAddress() public view returns (address) {
        return _rewardPool;
    }

    /// @notice gets the bonusPool contract address
    /// @return the bonusPool contract address
    function getBonusPoolAddress() public view returns (address) {
        return _bonusPool;
    }

    /// @notice gets the current amount of ALCA that is locked in this contract, after all early exits
    /// @return the amount of ALCA that is currently locked in this contract
    function getTotalSharesLocked() public view returns (uint256) {
        return _totalSharesLocked;
    }

    /// @notice gets the current state of the lockup (preLock, InLock, PostLock)
    /// @return the current state of the lockup contract
    function getState() public view returns (State) {
        return _getState();
    }

    /// @notice estimate the (liquid) income that can be collected from locked positions via
    /// {collectAllProfits}
    /// @dev this functions deducts the reserved amount that is sent to rewardPool contract
    function estimateProfits(
        uint256 tokenID_
    ) public view returns (uint256 payoutEth, uint256 payoutToken) {
        // check if the position owned by this contract
        _verifyLockedPosition(tokenID_);
        (payoutEth, payoutToken) = IStakingNFT(_publicStakingAddress()).estimateAllProfits(
            tokenID_
        );
        (uint256 reserveEth, uint256 reserveToken) = _computeReservedAmount(payoutEth, payoutToken);
        payoutEth -= reserveEth;
        payoutToken -= reserveToken;
    }

    /// @notice function to estimate the final amount of ALCA and ether that a locked
    /// position will receive at the end of the locking period. Depending on the preciseEstimation_ flag this function can be an imprecise approximation,
    /// the real amount can differ especially as user's collect profits in the middle of the locking
    /// period. Passing preciseEstimation_ as true will give a precise estimate since all profits are aggregated in a loop,
    /// hence is optional as it can be expensive if called as part of a smart contract transaction that alters state. After the locking
    /// period has finished and aggregateProfits has been executed for all locked positions the estimate will also be accurate.
    /// @dev this function is just an approximation when preciseEstimation_ is false, the real amount can differ!
    /// @param tokenID_ The token to check for the final profits.
    /// @param preciseEstimation_ whether to use the precise estimation or the approximation (precise is expensive due to looping so use wisely)
    /// @return positionShares_ the positions ALCA shares
    /// @return payoutEth_ the ether amount that the position will receive as profit
    /// @return payoutToken_ the ALCA amount that the position will receive as profit
    function estimateFinalBonusWithProfits(
        uint256 tokenID_,
        bool preciseEstimation_
    ) public view returns (uint256 positionShares_, uint256 payoutEth_, uint256 payoutToken_) {
        // check if the position owned by this contract
        _verifyLockedPosition(tokenID_);
        positionShares_ = _getNumShares(tokenID_);

        uint256 currentSharesLocked = _totalSharesLocked;

        // get the bonus amount + any profit from the bonus staked position
        (payoutEth_, payoutToken_) = BonusPool(payable(_bonusPool)).estimateBonusAmountWithReward(
            currentSharesLocked,
            positionShares_
        );

        //  get the cumulative rewards held in the rewardPool so far. In the case that
        // aggregateProfits has not been ran, the amount returned by this call may not be precise,
        // since only some users may have been collected until this point, in which case
        // preciseEstimation_ can be passed as true to get a precise estimate.
        (uint256 rewardEthProfit, uint256 rewardTokenProfit) = RewardPool(_rewardPool)
            .estimateRewards(currentSharesLocked, positionShares_);
        payoutEth_ += rewardEthProfit;
        payoutToken_ += rewardTokenProfit;

        uint256 reservedEth;
        uint256 reservedToken;

        // if aggregateProfits has been called (indicated by the payoutSafe flag), this calculation is not needed
        if (preciseEstimation_ && !payoutSafe) {
            // get this positions share based on all user profits aggregated (NOTE: precise but expensive due to the loop)
            (reservedEth, reservedToken) = _estimateUserAggregatedProfits(
                positionShares_,
                currentSharesLocked
            );
        } else {
            // get any future profit that will be held in the rewardPool for this position
            (uint256 positionEthProfit, uint256 positionTokenProfit) = IStakingNFT(
                _publicStakingAddress()
            ).estimateAllProfits(tokenID_);
            (reservedEth, reservedToken) = _computeReservedAmount(
                positionEthProfit,
                positionTokenProfit
            );
        }

        payoutEth_ += reservedEth;
        payoutToken_ += reservedToken;

        // get any eth and token held by this contract as result of the call to the aggregateProfit
        // function
        (uint256 aggregatedEth, uint256 aggregatedTokens) = _getTemporaryRewardBalance(
            _getOwnerOf(tokenID_)
        );
        payoutEth_ += aggregatedEth;
        payoutToken_ += aggregatedTokens;
    }

    /// @notice return the percentage amount that is held from the locked positions
    /// @dev this value is scaled by 100. Therefore the values are from 0-100%
    /// @return the percentage amount that is held from the locked positions
    function getReservedPercentage() public pure returns (uint256) {
        return (100 * FRACTION_RESERVED) / SCALING_FACTOR;
    }

    /// @notice gets the fraction of the amount that is reserved to reward pool
    /// @return the calculated reserved amount
    function getReservedAmount(uint256 amount_) public pure returns (uint256) {
        return (amount_ * FRACTION_RESERVED) / SCALING_FACTOR;
    }

    function _lockFromTransfer(uint256 tokenID_, address tokenOwner_) internal {
        _validateEntry(tokenID_, tokenOwner_);
        _checkTokenTransfer(tokenID_);
        _lock(tokenID_, tokenOwner_);
    }

    function _lock(uint256 tokenID_, address tokenOwner_) internal {
        uint256 shares = _verifyPositionAndGetShares(tokenID_);
        _totalSharesLocked += shares;
        _tokenOf[tokenOwner_] = tokenID_;
        _ownerOf[tokenID_] = tokenOwner_;
        _newTokenID(tokenID_);
        emit NewLockup(tokenOwner_, tokenID_);
    }

    function _burnLockedPosition(
        uint256 tokenID_,
        address tokenOwner_
    ) internal returns (uint256 payoutEth, uint256 payoutToken) {
        // burn the old position
        (payoutEth, payoutToken) = IStakingNFT(_publicStakingAddress()).burn(tokenID_);
        //delete tokenID_ from iterable tokenID mapping
        _removeTokenID(tokenID_);
        delete (_tokenOf[tokenOwner_]);
        delete (_ownerOf[tokenID_]);
    }

    function _withdrawalAggregatedAmount(
        address account_
    ) internal returns (uint256 payoutEth, uint256 payoutToken) {
        // case of we are sending out final pay based on request just pay all
        payoutEth = _rewardEth[account_];
        payoutToken = _rewardTokens[account_];
        _rewardEth[account_] = 0;
        _rewardTokens[account_] = 0;
    }

    function _collectAllProfits(
        address payable acct_,
        uint256 tokenID_
    ) internal returns (uint256 payoutEth, uint256 payoutToken) {
        (payoutEth, payoutToken) = IStakingNFT(_publicStakingAddress()).collectAllProfits(tokenID_);
        return _distributeAllProfits(acct_, payoutEth, payoutToken, 0, false);
    }

    function _distributeAllProfits(
        address payable acct_,
        uint256 payoutEth_,
        uint256 payoutToken_,
        uint256 additionalTokens,
        bool stakeExit_
    ) internal returns (uint256 userPayoutEth, uint256 userPayoutToken) {
        State state = _getState();
        bool localPayoutSafe = payoutSafe;
        userPayoutEth = payoutEth_;
        userPayoutToken = payoutToken_;
        (uint256 reservedEth, uint256 reservedToken) = _computeReservedAmount(
            payoutEth_,
            payoutToken_
        );
        userPayoutEth -= reservedEth;
        userPayoutToken -= reservedToken;
        // send tokens to reward pool
        _depositFundsInRewardPool(reservedEth, reservedToken);
        // in case this is being called by {aggregateProfits()} we don't send any asset to the
        // users, we just store the owed amounts on state
        if (!localPayoutSafe && state == State.PostLock) {
            // we should not send here and should instead track to local mapping as
            // otherwise a single bad user could block exit operations for all other users
            // by making the send to their account fail via a contract
            _rewardEth[acct_] += userPayoutEth;
            _rewardTokens[acct_] += userPayoutToken;
            return (userPayoutEth, userPayoutToken);
        }
        // adding any additional token that should be sent to the user (e.g shares from
        // burned position on early exit)
        userPayoutToken += additionalTokens;
        _transferEthAndTokensWithReStake(acct_, userPayoutEth, userPayoutToken, stakeExit_);
        return (userPayoutEth, userPayoutToken);
    }

    function _transferEthAndTokensWithReStake(
        address to_,
        uint256 payoutEth_,
        uint256 payoutToken_,
        bool stakeExit_
    ) internal {
        if (stakeExit_) {
            IERC20(_alcaAddress()).approve(_publicStakingAddress(), payoutToken_);
            IStakingNFT(_publicStakingAddress()).mintTo(to_, payoutToken_, 0);
        } else {
            _safeTransferERC20(IERC20Transferable(_alcaAddress()), to_, payoutToken_);
        }
        _safeTransferEth(to_, payoutEth_);
    }

    function _newTokenID(uint256 tokenID_) internal {
        uint256 index = _lenTokenIDs + 1;
        _tokenIDs[index] = tokenID_;
        _reverseTokenIDs[tokenID_] = index;
        _lenTokenIDs = index;
    }

    function _replaceTokenID(uint256 oldID_, uint256 newID_) internal {
        uint256 index = _reverseTokenIDs[oldID_];
        _reverseTokenIDs[oldID_] = 0;
        _tokenIDs[index] = newID_;
        _reverseTokenIDs[newID_] = index;
    }

    function _removeTokenID(uint256 tokenID_) internal {
        uint256 initialLen = _lenTokenIDs;
        if (initialLen == 0) {
            return;
        }
        if (initialLen == 1) {
            uint256 index = _reverseTokenIDs[tokenID_];
            _reverseTokenIDs[tokenID_] = 0;
            _tokenIDs[index] = 0;
            _lenTokenIDs = 0;
            return;
        }
        // pop the tail
        uint256 tailTokenID = _tokenIDs[initialLen];
        _tokenIDs[initialLen] = 0;
        _lenTokenIDs = initialLen - 1;
        if (tailTokenID == tokenID_) {
            // element was tail, so we are done
            _reverseTokenIDs[tailTokenID] = 0;
            return;
        }
        // use swap logic to re-insert tail over other position
        _replaceTokenID(tokenID_, tailTokenID);
    }

    function _depositFundsInRewardPool(uint256 reservedEth_, uint256 reservedToken_) internal {
        _safeTransferERC20(IERC20Transferable(_alcaAddress()), _rewardPool, reservedToken_);
        RewardPool(_rewardPool).deposit{value: reservedEth_}(reservedToken_);
    }

    function _getNumShares(uint256 tokenID_) internal view returns (uint256 shares) {
        (shares, , , , ) = IStakingNFT(_publicStakingAddress()).getPosition(tokenID_);
    }

    function _estimateTotalAggregatedProfits()
        internal
        view
        returns (uint256 payoutEth, uint256 payoutToken)
    {
        for (uint256 i = 1; i <= _lenTokenIDs; i++) {
            (uint256 tokenID, ) = _getTokenIDAtIndex(i);
            (uint256 stakingProfitEth, uint256 stakingProfitToken) = IStakingNFT(
                _publicStakingAddress()
            ).estimateAllProfits(tokenID);
            (uint256 reserveEth, uint256 reserveToken) = _computeReservedAmount(
                stakingProfitEth,
                stakingProfitToken
            );
            payoutEth += reserveEth;
            payoutToken += reserveToken;
        }
    }

    function _estimateUserAggregatedProfits(
        uint256 userShares_,
        uint256 totalShares_
    ) internal view returns (uint256 payoutEth, uint256 payoutToken) {
        (payoutEth, payoutToken) = _estimateTotalAggregatedProfits();
        payoutEth = (payoutEth * userShares_) / totalShares_;
        payoutToken = (payoutToken * userShares_) / totalShares_;
    }

    function _payableSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _getTokenIDAtIndex(uint256 index_) internal view returns (uint256 tokenID, bool ok) {
        tokenID = _tokenIDs[index_];
        return (tokenID, tokenID > 0);
    }

    function _checkTokenTransfer(uint256 tokenID_) internal view {
        if (IERC721(_publicStakingAddress()).ownerOf(tokenID_) != address(this)) {
            revert LockupErrors.ContractDoesNotOwnTokenID(tokenID_);
        }
    }

    function _validateEntry(uint256 tokenID_, address sender_) internal view {
        if (_getOwnerOf(tokenID_) != address(0)) {
            revert LockupErrors.TokenIDAlreadyClaimed(tokenID_);
        }
        if (_getTokenOf(sender_) != 0) {
            revert LockupErrors.AddressAlreadyLockedUp();
        }
    }

    function _validateAndGetTokenId() internal view returns (uint256) {
        // get tokenID of caller
        uint256 tokenID = _getTokenOf(msg.sender);
        if (tokenID == 0) {
            revert LockupErrors.UserHasNoPosition();
        }
        return tokenID;
    }

    function _verifyLockedPosition(uint256 tokenID_) internal view {
        if (_getOwnerOf(tokenID_) == address(0)) {
            revert LockupErrors.TokenIDNotLocked(tokenID_);
        }
    }

    // Gets the shares of position and checks if a position exists and if we can collect the
    // profits after the _endBlock.
    function _verifyPositionAndGetShares(uint256 tokenId_) internal view returns (uint256) {
        // get position fails if the position doesn't exists!
        (uint256 shares, , uint256 withdrawFreeAfter, , ) = IStakingNFT(_publicStakingAddress())
            .getPosition(tokenId_);
        if (withdrawFreeAfter >= _endBlock) {
            revert LockupErrors.InvalidPositionWithdrawPeriod(withdrawFreeAfter, _endBlock);
        }
        return shares;
    }

    function _getState() internal view returns (State) {
        if (block.number < _startBlock) {
            return State.PreLock;
        }
        if (block.number < _endBlock) {
            return State.InLock;
        }
        return State.PostLock;
    }

    function _getOwnerOf(uint256 tokenID_) internal view returns (address payable) {
        return payable(_ownerOf[tokenID_]);
    }

    function _getTokenOf(address acct_) internal view returns (uint256) {
        return _tokenOf[acct_];
    }

    function _getTemporaryRewardBalance(address user_) internal view returns (uint256, uint256) {
        return (_rewardEth[user_], _rewardTokens[user_]);
    }

    function _computeReservedAmount(
        uint256 payoutEth_,
        uint256 payoutToken_
    ) internal pure returns (uint256 reservedEth, uint256 reservedToken) {
        reservedEth = (payoutEth_ * FRACTION_RESERVED) / SCALING_FACTOR;
        reservedToken = (payoutToken_ * FRACTION_RESERVED) / SCALING_FACTOR;
    }
}