// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// ==========================================
// |            ____  _ __       __         |
// |           / __ \(_) /______/ /_        |
// |          / /_/ / / __/ ___/ __ \       |
// |         / ____/ / /_/ /__/ / / /       |
// |        /_/   /_/\__/\___/_/ /_/        |
// |                                        |
// ==========================================
// ================= Pitch ==================
// ==========================================

// Authored by Pitch Research: [email protected]

import "@interfaces/ITokenMinter.sol";
import "@interfaces/IVoteEscrow.sol";
import "@interfaces/IVoterProxy.sol";
import "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract SDLDepositor is OwnableUpgradeable, UUPSUpgradeable {
    // use SafeERC20 to secure interactions with staking and reward token
    using SafeERC20Upgradeable for IERC20Upgradeable;

    error CannotBeZero();

    // Constants
    uint256 public constant MAXTIME = 4 * 364 * 86400; // 4 Years
    uint256 public constant WEEK = 7 * 86400; // Week
    uint256 public constant FEE_DENOMINATOR = 10000;

    // State variables
    uint256 public lockIncentive = 0; // Incentive to users who spend gas to lock SDL
    uint256 public incentiveSDL = 0;
    uint256 public unlockTime;

    // Addresses
    address public staker; // Voter Proxy
    address public minter; // pitchSDL Token
    address public sdl;
    address public veSDL;

    /* ========== INITIALIZER FUNCTION ========== */
    function initialize(
        address _staker,
        address _minter,
        address _sdl,
        address _veSDL
    ) public initializer {
        __UUPSUpgradeable_init_unchained();
        __Context_init_unchained();
        __Ownable_init_unchained();
        staker = _staker;
        minter = _minter;
        sdl = _sdl;
        veSDL = _veSDL;
    }

    /* ========== OWNER FUNCTIONS ========== */
    // --- Update Addresses --- //
    function setSDL(address _sdl) external onlyOwner {
        sdl = _sdl;
    }

    function setVeSDL(address _veSDL) external onlyOwner {
        veSDL = _veSDL;
    }

    // --- End Update Addresses --- //

    /**
     * @notice Set the lock incentive, can only be called by contract owner.
     * @param _lockIncentive New incentive for users who lock SDL.
     */
    function setFees(uint256 _lockIncentive) external onlyOwner {
        if (_lockIncentive >= 0 && _lockIncentive <= 30) {
            lockIncentive = _lockIncentive;
            emit FeesChanged(_lockIncentive);
        }
    }

    /**
     * @notice Set the initial veSDL lock, can only be called by contract owner.
     */
    function initialLock() external onlyOwner {
        uint256 veSDLBalance = IERC20Upgradeable(veSDL).balanceOf(staker);
        uint256 locked = IVoteEscrow(veSDL).locked(staker);

        if (veSDLBalance == 0 || veSDLBalance == locked) {
            uint256 unlockAt = block.timestamp + MAXTIME;
            uint256 unlockInWeeks = (unlockAt / WEEK) * WEEK;

            // Release old lock on SDL if it exists
            IVoterProxy(staker).release(address(staker));

            // Create a new lock
            uint256 stakerSDLBalance = IERC20Upgradeable(sdl).balanceOf(staker);
            IVoterProxy(staker).createLock(stakerSDLBalance, unlockAt);
            unlockTime = unlockInWeeks;
        }
    }

    // used to manage upgrading the contract
    function _authorizeUpgrade(address) internal override onlyOwner {}

    /* ========== END OWNER FUNCTIONS ========== */

    /* ========== LOCKING FUNCTIONS ========== */
    function _lockSDL() internal {
        // Get SDL balance of depositor
        uint256 sdlBalance = IERC20Upgradeable(sdl).balanceOf(address(this));

        // If there's a positive SDL balance, send it to the staker
        if (sdlBalance > 0) {
            IERC20Upgradeable(sdl).safeTransfer(staker, sdlBalance);
            emit TokenLocked(msg.sender, sdlBalance);
        }

        // Increase the balance of the staker
        uint256 sdlBalanceStaker = IERC20Upgradeable(sdl).balanceOf(staker);
        if (sdlBalanceStaker == 0) {
            return;
        }

        IVoterProxy(staker).increaseAmount(sdlBalanceStaker);

        uint256 unlockAt = block.timestamp + MAXTIME;
        uint256 unlockInWeeks = (unlockAt / WEEK) * WEEK;

        // Increase time if over 1 week buffer
        if (unlockInWeeks - unlockTime >= 1) {
            IVoterProxy(staker).increaseTime(unlockAt);
            unlockTime = unlockInWeeks;
        }
    }

    function lockSDL() external {
        _lockSDL();

        // Mint incentives for locking SDL
        if (incentiveSDL > 0) {
            ITokenMinter(minter).mint(msg.sender, incentiveSDL);
            emit IncentiveReceived(msg.sender, incentiveSDL);
            incentiveSDL = 0;
        }
    }

    /* ========== END LOCKING FUNCTIONS ========== */

    /* ========== DEPOSIT FUNCTIONS ========== */
    function deposit(uint256 _amount, bool _lock) public {
        // Make sure we're depositing an amount > 0
        if (_amount <= 0) revert CannotBeZero();

        if (_lock) {
            // Lock SDL immediately, transfer to staker
            IERC20Upgradeable(sdl).safeTransferFrom(msg.sender, staker, _amount);
            _lockSDL();

            if (incentiveSDL > 0) {
                // Add the incentive tokens here to be staked together
                _amount += incentiveSDL;
                emit IncentiveReceived(msg.sender, incentiveSDL);
                incentiveSDL = 0;
            }
        } else {
            // Move tokens to this address to defer lock
            IERC20Upgradeable(sdl).safeTransferFrom(msg.sender, address(this), _amount);

            // Defer lock cost to another user
            if (lockIncentive > 0) {
                uint256 callIncentive = (_amount * lockIncentive) / FEE_DENOMINATOR;
                _amount -= callIncentive;

                // Add to a pool for lock caller
                incentiveSDL += callIncentive;
            }
        }

        // Mint token for sender
        ITokenMinter(minter).mint(msg.sender, _amount);

        // Emit event
        emit Deposited(msg.sender, _amount, _lock);
    }

    function depositAll(bool _lock) external {
        uint256 sdlBalance = IERC20Upgradeable(sdl).balanceOf(msg.sender);
        deposit(sdlBalance, _lock);
    }

    /* ========== END DEPOSIT FUNCTIONS ========== */

    /* ========== EVENTS ========== */
    event Deposited(address indexed caller, uint256 amount, bool lock);
    event TokenLocked(address indexed caller, uint256 amount);
    event IncentiveReceived(address indexed caller, uint256 amount);
    event FeesChanged(uint256 newFee);
}