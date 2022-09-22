// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./dependencies/@openzeppelin/security/ReentrancyGuard.sol";
import "./dependencies/@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "./access/Governable.sol";
import "./storage/ESVSPStorage.sol";

/**
 * @title Non-transferable escrowed VSP.
 */
contract ESVSP is ReentrancyGuard, Governable, ESVSPStorageV1 {
    using SafeERC20 for IERC20;

    string public constant VERSION = "1.0.0";
    IERC20 public VSP;
    uint256 public constant MINIMUM_LOCK_PERIOD = 7 days;
    uint256 public constant MAXIMUM_LOCK_PERIOD = 2 * 365 days;
    uint256 public constant MAXIMUM_BOOST = 4;

    /// Emitted when a new position is created (i.e. when user locks VSP)
    event VspLocked(uint256 tokenId, address account, uint256 amount, uint256 lockPeriod);

    /// Emitted when a position is burned due to unlock or kick
    event VspUnlocked(uint256 tokenId, uint256 amount, uint256 unlocked, uint256 penalty);

    /// Emitted when the exit penalty is updated
    event ExitPenaltyUpdated(uint256 oldExitPenalty, uint256 newExitPenalty);

    /// Emitted when the treasury address is updated
    event TreasuryUpdated(address oldTreasury, address newTreasury);

    function initialize(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        IESVSP721 esVSP721_,
        address treasury_,
        address vsp_
    ) external initializer {
        require(address(esVSP721_) != address(0), "esVSP721-is-null");
        require(treasury_ != address(0), "treasury-is-null");
        VSP = IERC20(vsp_);
        __Governable_init();
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
        esVSP721 = esVSP721_;
        exitPenalty = 0.5e18; // 50%;
        treasury = treasury_;
    }

    /**
     * @notice Get boosted VSP balance of user. This is different than ESVSP721.balanceOf()
     * It is sum of boosted amount of VSP in each ERC721 (i.e. ESVSP721) token of user
     * @param account_ The account
     * @return user's boost VSP balance. Boost VSP > locked VSP
     */
    function balanceOf(address account_) external view override returns (uint256) {
        return boosted[account_];
    }

    /**
     * @notice Calculate exit penalty for a position
     * @param tokenId_ The position/token id
     */
    function calculateExitPenalty(uint256 tokenId_) external view returns (uint256 _penalty) {
        LockPosition memory _position = positions[tokenId_];
        if (block.timestamp < _position.unlockTime) {
            _penalty = _calculateExitPenalty(_position);
        }
    }

    /**
     * @notice Get the lock period
     * @param tokenId_ The position/token id
     */
    function getLockedPeriodOf(uint256 tokenId_) external view returns (uint256 _lockPeriod) {
        return _getLockedPeriodOf(positions[tokenId_]);
    }

    /**
     * @notice Burn an expired position and send locked amount to the owner
     * @param tokenId_ ERC721 tokenId
     */
    function kick(uint256 tokenId_) external override nonReentrant {
        address _owner = esVSP721.ownerOf(tokenId_);
        _updateReward(_owner);
        _kick(tokenId_, _owner);
    }

    /**
     * @notice Kick all expired positions from a given account
     * @param account_ The target account
     */
    function kickAllExpiredOf(address account_) external override nonReentrant {
        _updateReward(account_);
        _kickAllExpiredOf(account_);
    }

    /**
     * @notice Lock VSP to get boosted revenue and voting power. Lock VSP and generate users position by minting ERC721
     * @param amount_ The VSP amount to lock
     * @param lockPeriod_ The lock period
     */
    function lock(uint256 amount_, uint256 lockPeriod_) external override nonReentrant {
        address _to = _msgSender();
        _updateReward(_to);
        _lock(_to, amount_, lockPeriod_);
    }

    /**
     * @notice Lock VSP to get boosted revenue and voting power. Lock VSP and generate users position by minting ERC721
     * @param amount_ The VSP amount to lock
     * @param lockPeriod_ The lock period
     */
    function lockFor(
        address to_,
        uint256 amount_,
        uint256 lockPeriod_
    ) external override nonReentrant {
        _updateReward(to_);
        _lock(to_, amount_, lockPeriod_);
    }

    /**
     * @notice Get total locked VSP balance of user
     * It is sum of locked VSP in each ERC721 (i.e. ESVSP721) token of user
     * @param account_ The account
     * @return user's locked VSP balance
     */
    function lockedBalanceOf(address account_) external view override returns (uint256) {
        return locked[account_];
    }

    /**
     * @notice Total boosted amount
     */
    function totalSupply() external view override returns (uint256) {
        return totalBoosted;
    }

    /**
     * @notice Transfer position (i.e. locked and boosted amounts) between accounts
     * @dev Revert if caller isn't the esVSP721 contract
     * @param tokenId_ The position (NFT) to transfer
     * @param to_ The recipient
     */
    function transferPosition(uint256 tokenId_, address to_) external override {
        require(_msgSender() == address(esVSP721), "not-esvsp721");
        address _from = esVSP721.ownerOf(tokenId_);

        _updateReward(_from);
        _updateReward(to_);

        LockPosition memory _position = positions[tokenId_];
        uint256 _locked = _position.lockedAmount;
        uint256 _boosted = _position.boostedAmount;

        locked[_from] -= _locked;
        boosted[_from] -= _boosted;
        locked[to_] += _locked;
        boosted[to_] += _boosted;

        emit Transfer(_from, to_, _boosted);
    }

    /**
     * @notice Unlock VSP by burning given ERC721 tokenId_
     * @param tokenId_ ERC721 tokenId
     * @param beforeUnlockTime_ When `true` unlock before expiration and pays exit penalty
     */
    function unlock(uint256 tokenId_, bool beforeUnlockTime_) external override nonReentrant {
        _updateReward(_msgSender());
        _unlock(tokenId_, !beforeUnlockTime_);
    }

    /**
     * @notice Burn given position and transfer locked amount to the owner (charges penalty if applicable)
     * @param tokenId_ The id of the position (NFT)
     * @param onlyIfExpired_ When `true` revert if didn't reach unlockTime
     * @param _account The account to burn position from
     */
    function _burn(
        uint256 tokenId_,
        bool onlyIfExpired_,
        address _account
    ) private {
        LockPosition memory _position = positions[tokenId_];
        uint256 _unlockTime = _position.unlockTime;

        bool _isExpired = block.timestamp > _unlockTime;

        if (onlyIfExpired_) {
            require(_isExpired, "not-unlocked-yet");
        }

        uint256 _locked = _position.lockedAmount;
        uint256 _boosted = _position.boostedAmount;

        esVSP721.burn(tokenId_);
        delete positions[tokenId_];

        locked[_account] -= _locked;
        totalLocked -= _locked;
        boosted[_account] -= _boosted;
        totalBoosted -= _boosted;

        uint256 _toTransfer = _locked;

        if (!_isExpired && exitPenalty > 0) {
            uint256 _penalty = _calculateExitPenalty(_position);
            if (_penalty > 0) {
                VSP.safeTransfer(treasury, _penalty);
                _toTransfer -= _penalty;
            }
        }

        VSP.safeTransfer(_account, _toTransfer);

        emit Transfer(_account, address(0), _boosted);
        emit VspUnlocked(tokenId_, _locked, _toTransfer, _locked - _toTransfer);
    }

    /**
     * @notice Calculate exit penalty for a non-expired position
     * @param _position The position to check (must be non-expired)
     */
    function _calculateExitPenalty(LockPosition memory _position) private view returns (uint256 _penalty) {
        uint256 _progress = ((_position.unlockTime - block.timestamp) * 1e18) / _getLockedPeriodOf(_position);
        return (((_position.lockedAmount * exitPenalty) / 1e18) * _progress) / 1e18;
    }

    /**
     * @notice Get the lock period
     * @param _position The position
     */
    function _getLockedPeriodOf(LockPosition memory _position) private pure returns (uint256 _lockPeriod) {
        return (_position.boostedAmount * MAXIMUM_LOCK_PERIOD) / MAXIMUM_BOOST / _position.lockedAmount;
    }

    /**
     * @notice Kick all expired positions of a user
     * @param account_ The target account
     */
    function _kickAllExpiredOf(address account_) private {
        uint256 _len = esVSP721.balanceOf(account_);
        uint256 i;
        while (i < _len) {
            uint256 _tokenId = esVSP721.tokenOfOwnerByIndex(account_, i);
            if (block.timestamp > positions[_tokenId].unlockTime) {
                _kick(_tokenId, account_);
                _len--;
            } else {
                i++;
            }
        }
    }

    /**
     * @notice Burn an expired position and send locked amount to the owner
     * @param tokenId_ ERC721 tokenId
     */
    function _kick(uint256 tokenId_, address owner_) private {
        _burn(tokenId_, true, owner_);
    }

    /**
     * @notice Lock VSP to get boosted revenue and voting power. Lock VSP and generate users position by minting ERC721
     * @param to_ The beneficiary account
     * @param amount_ The VSP amount to lock
     * @param lockPeriod_ The lock period
     */
    function _lock(
        address to_,
        uint256 amount_,
        uint256 lockPeriod_
    ) internal {
        require(amount_ > 0, "amount-is-zero");
        require(lockPeriod_ > MINIMUM_LOCK_PERIOD, "lock-period-lt-minimum");
        require(lockPeriod_ <= MAXIMUM_LOCK_PERIOD, "lock-period-gt-maximum");

        uint256 balanceBefore_ = VSP.balanceOf(address(this));
        VSP.safeTransferFrom(_msgSender(), address(this), amount_);
        uint256 _lockedAmount = VSP.balanceOf(address(this)) - balanceBefore_;

        uint256 _boostedAmount = (_lockedAmount * lockPeriod_ * MAXIMUM_BOOST) / MAXIMUM_LOCK_PERIOD;

        locked[to_] += _lockedAmount;
        boosted[to_] += _boostedAmount;
        totalLocked += _lockedAmount;
        totalBoosted += _boostedAmount;

        uint256 _tokenId = esVSP721.mint(to_);

        positions[_tokenId] = LockPosition({
            lockedAmount: _lockedAmount,
            boostedAmount: _boostedAmount,
            unlockTime: block.timestamp + lockPeriod_
        });

        emit Transfer(address(0), to_, _boostedAmount);
        emit VspLocked(_tokenId, to_, amount_, lockPeriod_);
    }

    /**
     * @notice Unlock VSP by burning given ERC721 tokenId_
     * @param tokenId_ ERC721 tokenId
     */
    function _unlock(uint256 tokenId_, bool onlyIfExpired_) private {
        address _owner = esVSP721.ownerOf(tokenId_);
        require(_msgSender() == _owner, "not-position-owner");
        _burn(tokenId_, onlyIfExpired_, _owner);
    }

    /**
     * @notice Update related rewards
     * @param account_ The account to update
     */
    function _updateReward(address account_) private {
        if (address(rewards) != address(0)) {
            rewards.updateReward(account_);
        }
    }

    /** Governance methods **/

    /**
     * @notice Initialize the Rewards contract
     * @dev Called once
     * @param rewards_ The new contract
     */
    function initializeRewards(IRewards rewards_) external onlyGovernor {
        require(address(rewards) == address(0), "already-initialized");
        require(address(rewards_) != address(0), "address-is-null");
        rewards = rewards_;
    }

    /**
     * @notice Update exit penalty
     * @param exitPenalty_ The new exit penalty
     */
    function updateExitPenalty(uint256 exitPenalty_) external onlyGovernor {
        require(exitPenalty_ <= 1e18, "exit-fee-gt-100%");
        require(exitPenalty_ != exitPenalty, "fee-is-same-as-current");
        emit ExitPenaltyUpdated(exitPenalty, exitPenalty_);
        exitPenalty = exitPenalty_;
    }

    /**
     * @notice Update treasury contract
     * @param treasury_ The new treasury address
     */
    function updateTreasury(address treasury_) external onlyGovernor {
        require(treasury_ != address(0), "address-null");
        require(treasury_ != treasury, "address-is-same-as-current");
        emit TreasuryUpdated(treasury, treasury_);
        treasury = treasury_;
    }

    /** Methods not supported **/

    function allowance(
        address, /*owner*/
        address /*spender*/
    ) public view virtual override returns (uint256) {
        revert("allowance-not-supported");
    }

    function approve(
        address, /*spender*/
        uint256 /*amount*/
    ) public virtual override returns (bool) {
        revert("approval-not-supported");
    }

    function decreaseAllowance(
        address, /*spender*/
        uint256 /*subtractedValue*/
    ) public virtual returns (bool) {
        revert("allowance-not-supported");
    }

    function increaseAllowance(
        address, /*spender*/
        uint256 /*addedValue*/
    ) public virtual returns (bool) {
        revert("allowance-not-supported");
    }

    function transfer(
        address, /*recipient*/
        uint256 /*amount*/
    ) public virtual override returns (bool) {
        revert("transfer-not-supported");
    }

    function transferFrom(
        address, /*sender*/
        address, /*recipient*/
        uint256 /*amount*/
    ) public virtual override returns (bool) {
        revert("transfer-not-supported");
    }
}