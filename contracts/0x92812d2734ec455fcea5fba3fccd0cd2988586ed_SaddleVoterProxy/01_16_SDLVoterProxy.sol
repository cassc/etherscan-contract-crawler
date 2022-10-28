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

import "@interfaces/ISaddleYieldDistro.sol";
import "@interfaces/IVoting.sol";
import "@interfaces/IVoteEscrow.sol";
import "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract SaddleVoterProxy is OwnableUpgradeable, UUPSUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    error NotDepositorOrOwner();
    error NotDepositor();
    error NotRegistry();
    error NotRegisteredAdapter(address);
    error NotConverterOrOwner();

    // State Variables
    address public depositor;
    address public sdl;
    address public veSDL;
    address public gaugeController;
    address public registry;
    mapping(address => uint256) public isRegisteredAdapter;
    address public incentiveConverter;

    /* ========== INITIALIZER FUNCTION ========== */
    function initialize(
        address _sdl,
        address _veSDL,
        address _gaugeController
    ) public initializer {
        __UUPSUpgradeable_init_unchained();
        __Context_init_unchained();
        __Ownable_init_unchained();
        sdl = _sdl;
        veSDL = _veSDL;
        gaugeController = _gaugeController;
    }

    /* ========== FUNCTION MODIFIERS ========== */
    modifier onlyDepositor() {
        if (msg.sender != depositor) revert NotDepositor();
        _;
    }

    modifier depositorOrOwner() {
        if (msg.sender != depositor && msg.sender != owner()) revert NotDepositorOrOwner();
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
        depositor = _depositor;
    }

    function setRegistry(address _registry) external onlyOwner {
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
        incentiveConverter = _incentiveConverter;
    }

    function setSDL(address _sdl) external onlyOwner {
        sdl = _sdl;
    }

    function setVeSDL(address _veSDL) external onlyOwner {
        veSDL = _veSDL;
    }

    function setGaugeController(address _gaugeController) external onlyOwner {
        gaugeController = _gaugeController;
    }

    // --- End Update Addresses --- //

    function voteGaugeWeight(address _gauge, uint256 _weight) external onlyOwner returns (bool) {
        //vote
        IVoting(gaugeController).vote_for_gauge_weights(_gauge, _weight);
        emit VotedOnGaugeWeight(_gauge, _weight);
        return true;
    }

    /// @notice Claims fees and rewards from the Saddle Distributor & veSDL rewards.
    /// @param _distroContract The address of the Saddle Finance rewards distributor contract.
    /// @param _claimTo The address of our rewards distributor contract.
    function claimFees(address _distroContract, address _claimTo) external ownerOrConverter {
        // These checks could be performed Off-Chain, but doing here ensures up to date & foolproof
        address _token1 = ISaddleYieldDistro(_distroContract).token();
        address _veRewardsContract = ISaddleYieldDistro(_distroContract).vesdl_penalty_rewards();
        address _token2 = ISaddleYieldDistro(_veRewardsContract).rewardToken();

        // claim from distro contract
        ISaddleYieldDistro(_distroContract).claim(address(this), true, false); /// param _claim_rewards defaults to false

        uint256 token1Bal = IERC20Upgradeable(_token1).balanceOf(address(this));
        uint256 token2Bal = IERC20Upgradeable(_token2).balanceOf(address(this));

        // distribute both yielded assets (sdl/weth sushi lp & sdl)
        emit FeesClaimed(_claimTo, token1Bal);
        _withdrawToken(_token1, _claimTo, token1Bal);

        emit FeesClaimed(_claimTo, token2Bal);
        _withdrawToken(_token2, _claimTo, token2Bal);
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
        // withdraw all of a token from this contract
        IERC20Upgradeable(_token).safeTransfer(_to, _amount);
    }

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

    // used to manage upgrading the contract
    function _authorizeUpgrade(address) internal override onlyOwner {}

    /* ========== END OWNER FUNCTIONS ========== */

    /* ========== DEPOSITOR FUNCTIONS ========== */
    function createLock(uint256 _value, uint256 _unlockTime) external onlyDepositor returns (bool) {
        IERC20Upgradeable(sdl).safeApprove(veSDL, 0);
        IERC20Upgradeable(sdl).safeApprove(veSDL, _value);
        IVoteEscrow(veSDL).create_lock(_value, _unlockTime);

        emit LockCreated(msg.sender, _value, _unlockTime);
        return true;
    }

    function increaseAmount(uint256 _value) external onlyDepositor returns (bool) {
        IERC20Upgradeable(sdl).safeApprove(veSDL, 0);
        IERC20Upgradeable(sdl).safeApprove(veSDL, _value);
        IVoteEscrow(veSDL).increase_amount(_value);
        return true;
    }

    function increaseTime(uint256 _value) external onlyDepositor returns (bool) {
        IVoteEscrow(veSDL).increase_unlock_time(_value);
        return true;
    }

    function release(address _recipient) external onlyDepositor returns (bool) {
        IVoteEscrow(veSDL).withdraw();
        uint256 balance = IERC20Upgradeable(sdl).balanceOf(address(this));

        IERC20Upgradeable(sdl).safeTransfer(_recipient, balance);
        emit Released(_recipient, balance);
        return true;
    }

    // Also, they currently have this blocked & only callable by owner
    function checkpointFeeRewards(address _distroContract) external depositorOrOwner {
        ISaddleYieldDistro(_distroContract).checkpoint_token();
    }

    /* ========== END DEPOSITOR FUNCTIONS ========== */

    /* ========== EVENTS ========== */
    event LockCreated(address indexed user, uint256 value, uint256 duration);
    event FeesClaimed(address indexed user, uint256 value);
    event VotedOnGaugeWeight(address indexed _gauge, uint256 _weight);
    event Released(address indexed user, uint256 value);
    event AdapterRegistered(address indexed adapter);
}