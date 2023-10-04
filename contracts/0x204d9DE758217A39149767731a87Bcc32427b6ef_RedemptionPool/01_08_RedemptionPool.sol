// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Ownable} from "Ownable.sol";
import {IERC20} from "IERC20.sol";
import {SafeERC20} from "SafeERC20.sol";
import {RedemptionErrors} from "Errors.sol";

/////////////////////////////////////////////////////////////////////////////
//                                  Interfaces                             //
/////////////////////////////////////////////////////////////////////////////
// Interface for Compound cToken (cUSDC)

interface ICERC20 is IERC20 {
    function redeem(uint256 redeemTokens) external returns (uint256);

    function exchangeRateStored() external view returns (uint256);
}

contract RedemptionPool is Ownable {
    using SafeERC20 for IERC20;

    /////////////////////////////////////////////////////////////////////////////
    //                                  Constants                              //
    /////////////////////////////////////////////////////////////////////////////

    uint256 public constant DURATION = 28 days;
    uint256 public immutable DEADLINE;
    uint256 internal constant PRECISION = 1e18;
    address internal constant DAO = address(0x359F4fe841f246a095a82cb26F5819E10a91fe0d);

    // TOKENS
    IERC20 public constant GRO = IERC20(0x3Ec8798B81485A254928B70CDA1cf0A2BB0B74D7);
    ICERC20 public constant CUSDC = ICERC20(0x39AA39c021dfbaE8faC545936693aC917d5E7563);
    IERC20 public constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    /////////////////////////////////////////////////////////////////////////////
    //                                  Modifiers                              //
    /////////////////////////////////////////////////////////////////////////////

    modifier onlyBeforeDeadline() {
        if (block.timestamp > DEADLINE) {
            revert RedemptionErrors.DeadlineExceeded();
        }
        _;
    }

    modifier onlyAfterDeadline() {
        if (block.timestamp <= DEADLINE) {
            revert RedemptionErrors.ClaimsPeriodNotStarted();
        }
        _;
    }
    /////////////////////////////////////////////////////////////////////////////
    //                                  Storage                                //
    /////////////////////////////////////////////////////////////////////////////

    mapping(address => uint256) private _userGROBalance;
    mapping(address => uint256) private _userClaims;
    uint256 public totalGRO;
    uint256 public totalCUSDCDeposited;
    uint256 public totalCUSDCWithdrawn;

    /////////////////////////////////////////////////////////////////////////////
    //                                  Events                                 //
    /////////////////////////////////////////////////////////////////////////////
    event Deposit(address indexed user, uint256 amount);
    event TotalGRODeposited(uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Claim(address indexed user, uint256 amount);
    event CUSDCDeposit(uint256 amount);

    /////////////////////////////////////////////////////////////////////////////
    //                                  CONSTRUCTOR                            //
    /////////////////////////////////////////////////////////////////////////////

    constructor() {
        transferOwnership(DAO);
        // Sets the DEADLINE to 28 days from now
        DEADLINE = block.timestamp + DURATION;
    }

    /////////////////////////////////////////////////////////////////////////////
    //                                   VIEWS                                 //
    /////////////////////////////////////////////////////////////////////////////

    /// @notice Returns the price per share of the pool in terms of CUSDC
    function getPricePerShare() public view returns (uint256) {
        return (totalCUSDCDeposited * PRECISION) / totalGRO;
    }

    /// @notice Returns the price per share of the pool in terms of USDC
    function getPricePerShareUSDC() public view returns (uint256) {
        return (totalCUSDCDeposited * ICERC20(CUSDC).exchangeRateStored()) / totalGRO;
    }

    /// @notice Returns the price per share of the pool in terms of USDC
    function getUSDCperGRO() public view returns (uint256) {
        // Get the exchange rate from cUSDC to USDC (16 decimals) as exchangeRateStored is normalized for USDC
        uint256 USDCperCUSDC = ICERC20(CUSDC).exchangeRateStored();

        // Calculate USDC per GRO (result will have 6 decimals)
        return (totalCUSDCDeposited * USDCperCUSDC) / totalGRO;
    }

    /// @notice Returns user's share of the claims pot
    /// @param user address of the user
    function getSharesAvailable(address user) public view returns (uint256) {
        return (_userGROBalance[user] * totalCUSDCDeposited) / totalGRO - _userClaims[user];
    }

    /// @notice Returns the amount of GRO user has deposited
    /// @param user address of the user
    function getUserBalance(address user) external view returns (uint256) {
        return _userGROBalance[user];
    }

    /// @notice Returns claimed cUSDC for a user
    /// @param user address of the user
    function getUserClaim(address user) external view returns (uint256) {
        return _userClaims[user];
    }

    /// @notice Returns the deadline of the redemption pool
    function getDeadline() external view returns (uint256) {
        return DEADLINE;
    }

    /////////////////////////////////////////////////////////////////////////////
    //                                  CORE                                   //
    /////////////////////////////////////////////////////////////////////////////

    /// @notice deposit GRO tokens to the pool before the deadline
    /// @param _amount amount of GRO tokens to deposit
    function deposit(uint256 _amount) external onlyBeforeDeadline {
        // Transfers the GRO tokens from the sender to this contract
        GRO.safeTransferFrom(msg.sender, address(this), _amount);
        // Increases the balance of the sender by the amount
        _userGROBalance[msg.sender] += _amount;
        // Increases the total deposited by the amount
        totalGRO += _amount;
        emit Deposit(msg.sender, _amount);
        emit TotalGRODeposited(totalGRO);
    }

    /// @notice withdraw deposited GRO tokens before the deadline
    /// @param _amount amount of GRO tokens to withdraw
    function withdraw(uint256 _amount) external onlyBeforeDeadline {
        if (_userGROBalance[msg.sender] < _amount) {
            revert RedemptionErrors.InsufficientBalance();
        }

        _userGROBalance[msg.sender] -= _amount;
        totalGRO -= _amount;
        GRO.safeTransfer(msg.sender, _amount);
        emit Withdraw(msg.sender, _amount);
    }

    /**
     * @notice Allow users to claim their share of USDC tokens based on the amount of GRO tokens they have deposited
     * @dev Users must have a positive GRO token balance and a non-zero claim available to make a claim
     * @dev The deadline for making GRO deposits must have passed
     * @dev Redeems the user's cUSDC tokens for an equivalent amount of USDC tokens and transfers them to the user's address
     * @dev Decreases the user's claims and contract accounting by the amount claimed
     */
    function claim(uint256 _amount) external onlyAfterDeadline {
        // Get the amount of cUSDC tokens available for the user to claim
        uint256 userClaim = getSharesAvailable(msg.sender);

        // Check that _amount is greater than 0 and smaller (or equal to) than userClaim
        if (!(_amount > 0 && _amount <= userClaim)) {
            revert RedemptionErrors.InvalidClaim();
        }

        // Redeem the user's cUSDC tokens for USDC tokens
        // and transfer the USDC tokens to the user's address
        uint256 usdcBalanceBefore = USDC.balanceOf(address(this));
        uint256 redeemResult = ICERC20(CUSDC).redeem(_amount);
        if (redeemResult != 0) {
            revert RedemptionErrors.USDCRedeemFailed(redeemResult);
        }
        uint256 usdcRedeemed = USDC.balanceOf(address(this)) - usdcBalanceBefore;
        USDC.safeTransfer(msg.sender, usdcRedeemed);

        // Adjust the user's and the cumulative tally of claimed cUSDC
        _userClaims[msg.sender] += _amount;
        totalCUSDCWithdrawn += _amount;
        emit Claim(msg.sender, _amount);
    }

    /////////////////////////////////////////////////////////////////////////////
    //                              Permissioned funcs                         //
    /////////////////////////////////////////////////////////////////////////////

    /// @notice Pulls assets from the DAO msig
    /// @param _amount amount of cUSDC to pull
    function depositCUSDC(uint256 _amount) external onlyOwner {
        // Transfer cUSDC from the caller to this contract
        IERC20(CUSDC).safeTransferFrom(msg.sender, address(this), _amount);

        totalCUSDCDeposited += _amount;
        emit CUSDCDeposit(totalCUSDCDeposited);
    }

    /// @notice Allow to withdraw any tokens except GRO back to the owner, as long as the deadline has not passed
    /// @param _token address of the token to sweep
    function sweep(address _token) external onlyOwner onlyBeforeDeadline {
        // Do not allow to sweep GRO tokens
        if (_token == address(GRO)) revert RedemptionErrors.NoSweepGro();

        // Transfers the tokens to the owner
        IERC20(_token).safeTransfer(owner(), IERC20(_token).balanceOf(address(this)));
    }
}