pragma solidity 0.8.13;

// SPDX-License-Identifier: MIT

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { LinearVestingCore } from "./LinearVestingCore.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @notice Facilitate a swap from input token to output token but only send output tokens through a linear vesting schedule
/// @dev Only 1 schedule per ETH account so if the user wants to do multiple swaps they will have to use multiple accounts
abstract contract SwapVesting is LinearVestingCore, UUPSUpgradeable {
    /// @notice Emitted when a claim to withdraw tokens has been received
    event ClaimRequested(address indexed beneficiary, uint256 inputAmount);

    /// @notice Address of the token that beneficiaries will deposit in exchange for the vested token
    IERC20 public inputToken;

    /// @notice Definition of a schedule once input tokens have been deposited
    struct VestingSchedule {
        uint128 start;
        uint128 amount;
    }

    /// @notice Vesting schedule associated with a beneficiary address.
    mapping(address => VestingSchedule) public vestingSchedule;

    /// @notice After depositing input tokens, number of seconds user has to wait before vesting starts
    uint256 public waitPeriod;

    /// @notice Once vesting schedule starts, length of each vesting schedule
    uint256 public vestingLength;

    /// @notice Multiplier defining how many output tokens a user will get
    uint256 public inputToVestedTokenExchangeRate;

    /// @notice Address where vested tokens come from
    address public vestedTokenSource;

    /// @notice Address where input tokens get sent to inorder to burn forever
    address public burnAddress;

    function __Swap_Vesting_init(
        address _vestedToken,
        address _contractOwner,
        IERC20 _inputToken,
        address _vestedTokenSource,
        address _inputBurnAddress,
        uint256 _inputToVestedTokenExchangeRate,
        uint256 _waitPeriod,
        uint256 _vestingLength
    ) internal initializer {
        require(_vestedTokenSource != address(0), "Invalid source");
        vestedTokenSource = _vestedTokenSource;

        require(_inputBurnAddress != address(0), "OZ wont allow");
        burnAddress = _inputBurnAddress;

        require(address(_inputToken) != address(0), "Invalid input");
        require(address(_inputToken) != address(vestedToken), "Input eq output");
        inputToken = _inputToken;

        require(_inputToVestedTokenExchangeRate > 0, "Zero rate");
        inputToVestedTokenExchangeRate = _inputToVestedTokenExchangeRate;

        require(_vestingLength > 0, "Zero vesting");
        require(_vestingLength > _waitPeriod, "Wait and length are the same"); // this ensures start + end for schedules work
        waitPeriod = _waitPeriod;
        vestingLength = _vestingLength;

        __LinearVestingCore_init(_vestedToken, _contractOwner);
        __UUPSUpgradeable_init();

        vestingVersion = 1;
    }

    function _authorizeUpgrade(address newImplementation)
    internal
    onlyOwner
    override
    {}

    /// @notice Request that full balance of input token is swapped for vested token on agreed vesting schedule
    function requestClaim() external whenNotPaused {
        require(vestingSchedule[msg.sender].start == 0, "Already claimed");

        uint256 inputBalanceOfSender = inputToken.balanceOf(msg.sender);
        require(inputBalanceOfSender > 0, "Zero amount");

        uint256 amountOfOutputTokens = inputBalanceOfSender * inputToVestedTokenExchangeRate;
        require(_isOutputAmountAvailable(amountOfOutputTokens), "No output");

        _reserveOutputAmount(amountOfOutputTokens);

        vestingSchedule[msg.sender] = VestingSchedule({
            start: uint128(_getNow() + waitPeriod),
            amount: uint128(amountOfOutputTokens)
        });

        inputToken.transferFrom(msg.sender, burnAddress, inputBalanceOfSender);

        emit ClaimRequested(msg.sender, inputBalanceOfSender);
    }

    /// @notice Beneficiary can call this method to claim vested tokens owed up to the current block
    /// @notice _recipient Account that will receive the output tokens
    function claim(address _recipient) external whenNotPaused {
        require(_recipient != address(0), "Zero recipient");
        require(_recipient != address(this), "Self recipient");

        VestingSchedule storage schedule = vestingSchedule[msg.sender];
        require(schedule.start != 0, "Go claim");

        // Send tokens to beneficiary from vestedTokenSource
        require(
            vestedToken.transferFrom(
                vestedTokenSource,
                _recipient,
                _drawDown(
                    schedule.start,
                    schedule.start + vestingLength,
                    schedule.start,
                    schedule.amount,
                    msg.sender
                )
            ),
            "Failed"
        );
    }

    /// @notice Update exchange rate of input to output token
    function updateExchangeRate(uint256 _newRate) external onlyOwner {
        require(_newRate > 0, "Zero rate");
        inputToVestedTokenExchangeRate = _newRate;
    }

    /// @notice Update burning address for input tokens
    function updateBurnAddress(address _burn) external onlyOwner {
        require(_burn != address(0), "OZ does not permit zero");
        require(_burn != owner(), "Not owner");
        burnAddress = _burn;
    }

    /// @notice Update address that has approved tokens to fund vesting schedules
    function updateVestedTokenSource(address _source) external onlyOwner {
        require(_source != address(0), "Zero source");
        vestedTokenSource = _source;
    }

    /// @notice Update how long after sending input tokens, the vesting schedule starts
    function updateWaitPeriod(uint256 _newWait) external onlyOwner {
        waitPeriod = _newWait;
    }

    /// @notice Update how long each vesting schedule lasts from time of request
    function updateVestingLength(uint256 _newLength) external onlyOwner {
        vestingLength = _newLength;
    }

    /// @notice For a desired amount of output tokens, this will preview whether they are available
    function isOutputAmountAvailable(uint256 _outputAmount) external view returns (bool) {
        return _isOutputAmountAvailable(_outputAmount);
    }

    /// @dev Delegate to implementation to define whether the output tokens are in circulation or if they have been exhausted
    function _isOutputAmountAvailable(uint256 _outputAmount) internal virtual view returns (bool);

    /// @dev Delegate to implementation to reduce the total output supply if needed
    function _reserveOutputAmount(uint256 _outputAmount) internal virtual;
}