pragma solidity 0.8.13;

// SPDX-License-Identifier: MIT

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { ERC20Votes, IERC20 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

/// @dev Core business logic required to implement a linear vesting contract
abstract contract LinearVestingCore is PausableUpgradeable, OwnableUpgradeable {
    /// @notice Emitted when tokens have been drawn down for a beneficiary
    event TokensClaimed(address indexed beneficiary, uint256 indexed version, uint256 amount);

    /// @notice Output token that users will receive
    ERC20Votes public vestedToken;

    /// @notice Active version of vesting applicable to beneficiaries
    uint256 public vestingVersion;

    /// @notice Beneficiary address -> total number of tokens drawn down
    mapping(address => uint256) public drawnDown;

    /// @notice Beneficiary address -> Last timestamp when tokens were drawn down
    mapping(address => uint256) public lastDrawnAt;

    function __LinearVestingCore_init(address _vestedToken, address _contractOwner) internal initializer {
        require(_vestedToken != address(0), "Invalid token");
        vestedToken = ERC20Votes(_vestedToken);

        __Ownable_init();
        __Pausable_init();

        require(_contractOwner != address(vestedToken), "Owner cannot be token");
        transferOwnership(_contractOwner);

        // start in paused state
        _pause();
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    function _unpause() internal override whenPaused {
        require(vestingVersion > 0, "Contract under maintenance");
        super._unpause();
    }

    /// @notice Given params of a vesting schedule, how many tokens would be available for draw down
    /// @param _start Start timestamp of the schedule
    /// @param _end End timestamp of the schedule
    /// @param _cliff Cliff end timestamp for the schedule
    /// @param _amount Amount of tokens allocated to the schedule
    /// @param _beneficiary Address receiving the tokens
    function availableDrawDownAmount(
        uint256 _start,
        uint256 _end,
        uint256 _cliff,
        uint256 _amount,
        address _beneficiary
    ) external view returns (uint256) {
        return _availableDrawDownAmount(_start, _end, _cliff, _amount, _beneficiary);
    }

    /// @notice Trigger a token draw down and update internal state to reflect
    /// @param _start Start timestamp of the schedule
    /// @param _end End timestamp of the schedule
    /// @param _cliff Cliff end timestamp for the schedule
    /// @param _amount Amount of tokens allocated to the schedule
    /// @param _beneficiary Address receiving the tokens
    function _drawDown(
        uint256 _start,
        uint256 _end,
        uint256 _cliff,
        uint256 _amount,
        address _beneficiary
    ) internal whenNotPaused returns (uint256 amountOfTokensToSend) {
        // cliff is either same or greater than the start
        require(_cliff >= _start, "Invalid cliff");

        // end must be greater than cliff which means must be greater than start
        require(_end > _cliff, "Invalid end");

        // amount must be non zero
        require(_amount > 0, "Invalid amount");

        // beneficiary must be non zero
        require(_beneficiary != address(0), "Claim from zero");

        // check if there is anything to draw down at the moment
        uint256 amount = _availableDrawDownAmount(_start, _end, _cliff, _amount, _beneficiary);
        require(amount > 0, "Nothing to claim");

        // sense check that you cannot draw down more than amount
        require(drawnDown[_beneficiary] + amount <= _amount, "Bad");

        // If there is, record the last time the draw down happened and the total amount drawn
        lastDrawnAt[_beneficiary] = _getNow();
        drawnDown[_beneficiary] += amount;

        emit TokensClaimed(_beneficiary, vestingVersion, amount);

        return amount;
    }

    /// @dev Business logic for working out available draw down amount based on tokens already withdrawn
    function _availableDrawDownAmount(
        uint256 _start,
        uint256 _end,
        uint256 _cliff,
        uint256 _amount,
        address _beneficiary
    ) internal view returns (uint256) {
        // fully drawn down path - return zero immediately
        if (drawnDown[_beneficiary] >= _amount) {
            return 0;
        }

        // not started path - the cliff period has not ended, therefore, no tokens to draw down
        if (_getNow() <= _cliff) {
            return 0;
        }

        // Ended path - send all remaining tokens including any dust that may have been missed off
        if (_getNow() >= _end) {
            return _amount - drawnDown[_beneficiary];
        }

        // Active path - Work out how many tokens to give the user
        uint256 timeLastDrawnOrStart = lastDrawnAt[_beneficiary] == 0 ? _start : lastDrawnAt[_beneficiary];

        // Find out how much time has past since last invocation as that will dictate how many tokens can be released
        uint256 timePassedSinceLastInvocation = _getNow() - timeLastDrawnOrStart;

        // To work out how many tokens are due = seconds passed since start * rate per second
        uint256 drawDownRate = _amount / (_end - _start);
        return timePassedSinceLastInvocation * drawDownRate;
    }

    /// @param _token Address of the token being recovered
    /// @param _amount Amount of the token being recovered
    /// @param _recipient Receiving the recovered tokens
    function recoverERC20Funds(IERC20 _token, uint256 _amount, address _recipient) external onlyOwner {
        _token.transfer(_recipient, _amount);
    }

    /// @dev Allow testing contracts to override
    function _getNow() internal view virtual returns (uint256) {
        return block.timestamp;
    }
}