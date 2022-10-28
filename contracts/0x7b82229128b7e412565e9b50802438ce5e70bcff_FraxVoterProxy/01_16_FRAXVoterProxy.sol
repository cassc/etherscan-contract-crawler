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

import "@interfaces/IFraxYieldDistro.sol";
import "@interfaces/IVoting.sol";
import "@interfaces/IVoteEscrow.sol";
import "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract FraxVoterProxy is OwnableUpgradeable, UUPSUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // State Variables
    address public depositor;
    address public FXS;
    address public veFXS;
    address public gaugeController;
    address public registry;
    address public incentiveConverter;
    mapping(address => uint256) public isRegisteredAdapter;

    error NotDepositorOrOwner();
    error NotDepositor();
    error NotRegistry();
    error NotRegisteredAdapter(address);
    error NotConverterOrOwner();

    /* ========== INITIALIZER FUNCTION ========== */
    function initialize(
        address _fxs,
        address _veFXS,
        address _gaugeController
    ) public initializer {
        __UUPSUpgradeable_init_unchained();
        __Context_init_unchained();
        __Ownable_init_unchained();
        FXS = _fxs;
        veFXS = _veFXS;
        gaugeController = _gaugeController;
    }

    /* ========== FUNCTION MODIFIERS ========== */
    modifier onlyDepositor() {
        if (msg.sender != depositor) revert NotDepositor();
        _;
    }

    modifier ownerOrConverter() {
        if (msg.sender != owner() && msg.sender != incentiveConverter) revert NotConverterOrOwner();
        _;
    }

    /* ========== END FUNCTION MODIFIERS ========== */

    /* ========== OWNER FUNCTIONS ========== */
    // --- Update Addresses --- //
    function setDepositor(address _depositor) external onlyOwner {
        emit DepositorUpdated(depositor, _depositor);
        depositor = _depositor;
    }

    function setRegistry(address _registry) external onlyOwner {
        emit AdapterRegistryUpdated(registry, _registry);
        registry = _registry;
    }

    function registerAdapter(address _adapter) external {
        if (msg.sender != registry) {
            revert NotRegistry();
        }
        isRegisteredAdapter[_adapter] = 1;

        emit AdapterRegistered(_adapter);
    }

    function setIncentiveConverter(address _incentiveConverter) external onlyOwner {
        emit IncentiveConverterUpdated(incentiveConverter, _incentiveConverter);
        incentiveConverter = _incentiveConverter;
    }

    function setFXS(address _fxs) external onlyOwner {
        emit FxsUpdated(FXS, _fxs);
        FXS = _fxs;
    }

    function setVeFXS(address _veFXS) external onlyOwner {
        emit VeFxsUpdated(veFXS, _veFXS);
        veFXS = _veFXS;
    }

    function setGaugeController(address _gaugeController) external onlyOwner {
        emit GaugeControllerUpdated(gaugeController, _gaugeController);
        gaugeController = _gaugeController;
    }

    // --- End Update Addresses --- //

    /// @notice Cast the gauge weight votes.
    /// @param _gauge Address of gauge to vote for.
    /// @param _weight The allocation of votes to cast for _gauge.
    /// @return bool Returns true if successful.
    function voteGaugeWeight(address _gauge, uint256 _weight) external onlyOwner returns (bool) {
        //vote
        IVoting(gaugeController).vote_for_gauge_weights(_gauge, _weight);
        emit VotedOnGaugeWeight(_gauge, _weight);
        return true;
    }

    /// @notice Claims the yield accrued for the veFXS in custody & withdraws them.
    /// @param _distroContract The target contract at which to claim accrued yield.
    /// @param _token The token to claim.
    /// @param _claimTo The address where yield is to be sent.
    /// @return uint Amount of token claimed.
    function claimFees(
        address _distroContract,
        address _token,
        address _claimTo
    ) external ownerOrConverter returns (uint256) {
        IFraxYieldDistro(_distroContract).getYield();
        uint256 _balance = IERC20Upgradeable(_token).balanceOf(address(this)); //_token = FXS

        emit FeesClaimed(_claimTo, _balance);

        _withdrawToken(_token, _claimTo, _balance);

        return _balance;
    }

    // Allows recovery of arbitrary tokens and airdrops to authorized address
    function withdrawToken(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        _withdrawToken(_token, _to, _amount);
    }

    // Executes the withdrawal of the token
    function _withdrawToken(
        address _token,
        address _to,
        uint256 _amount
    ) internal {
        // withdraw token from this contract
        IERC20Upgradeable(_token).safeTransfer(_to, _amount);
    }

    // this lets the contract execute arbitrary code and send arbitrary data... something to be very careful about
    /// @notice Allows contract to execute arbitrary code & send arbitrary data.
    /// @dev Be very careful with the use of this & ensure it is protected.
    /// @param _to The contract address to call.
    /// @param _value The value to pass in to the call.
    /// @param _data The encoded data to use for the call, such as function selector, etc
    /// @return success bool Success if true.
    /// @return result bytes in memory - the data returned from the call.
    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external returns (bool success, bytes memory result) {
        // only callable by the adapter or the registry
        if (isRegisteredAdapter[msg.sender] != 1 && msg.sender == registry) revert NotRegisteredAdapter(msg.sender);

        // execute the arbitrary call
        (success, result) = _to.call{value: _value}(_data);
    }

    /// @notice Used to verify whether the calling address is allowed to authorize.
    /// @param newImplementation The address of the new implementation, as required by OZ.
    /// @dev Must fail if address calling is not the owner.
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /* ========== END OWNER FUNCTIONS ========== */

    /* ========== DEPOSITOR FUNCTIONS ========== */
    /// @notice Called by the FXS Depositor when user deposits FXS - locks more veFXS.
    /// @param _value The amount of FXS to lock.
    /// @param _unlockTime The duration of the lock.
    /// @return bool True if successful.
    function createLock(uint256 _value, uint256 _unlockTime) external onlyDepositor returns (bool) {
        IERC20Upgradeable(FXS).safeApprove(veFXS, 0);
        IERC20Upgradeable(FXS).safeApprove(veFXS, _value);
        IVoteEscrow(veFXS).create_lock(_value, _unlockTime);

        emit LockCreated(msg.sender, _value, _unlockTime);
        return true;
    }

    /// @notice Alows depositor contract to increase amount of lock.
    /// @param _value The amount to increase by.
    /// @return bool True if successful.
    function increaseAmount(uint256 _value) external onlyDepositor returns (bool) {
        // zero out approvals
        IERC20Upgradeable(FXS).safeApprove(veFXS, 0);
        // approve for the exact amount
        IERC20Upgradeable(FXS).safeApprove(veFXS, _value);
        // increase the amount by _value
        IVoteEscrow(veFXS).increase_amount(_value);
        // return true if previous steps have succeeded
        return true;
    }

    /// @notice Allows depositor contract to increase duration of lock.
    /// @param _value The amount of seconds to extend duration by.
    /// @return bool True if successful.
    function increaseTime(uint256 _value) external onlyDepositor returns (bool) {
        IVoteEscrow(veFXS).increase_unlock_time(_value);
        return true;
    }

    /// @notice Allows depositor contract to withdraw unlocked veFXS as FXS.
    /// @param _recipient The address to send the FXS to.
    /// @return bool True if successful.
    function release(address _recipient) external onlyDepositor returns (bool) {
        IVoteEscrow(veFXS).withdraw();
        uint256 balance = IERC20Upgradeable(FXS).balanceOf(address(this));

        IERC20Upgradeable(FXS).safeTransfer(_recipient, balance);
        emit Released(_recipient, balance);
        return true;
    }

    /// @notice Allows calling Checkpoint to lock in rewards.
    /// @param _distroContract The address of the contract to call checkpoint on behalf of.
    function checkpointFeeRewards(address _distroContract) external {
        if (msg.sender != depositor && msg.sender != owner() && msg.sender != incentiveConverter) {
            revert NotDepositorOrOwner();
        }

        IFraxYieldDistro(_distroContract).checkpoint();
    }

    /* ========== END DEPOSITOR FUNCTIONS ========== */

    /* ========== EVENTS ========== */
    event LockCreated(address indexed user, uint256 value, uint256 duration);
    event FeesClaimed(address indexed user, uint256 value);
    event VotedOnGaugeWeight(address indexed _gauge, uint256 _weight);
    event Released(address indexed user, uint256 value);
    event AdapterRegistered(address indexed adapter);
    event GaugeControllerUpdated(address oldAddress, address newAddress);
    event VeFxsUpdated(address oldAddress, address newAddress);
    event FxsUpdated(address _oldAddress, address newAddress);
    event IncentiveConverterUpdated(address _oldAddress, address newAddress);
    event AdapterRegistryUpdated(address _oldAddress, address newAddress);
    event DepositorUpdated(address _oldAddress, address newAddress);
}