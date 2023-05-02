// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import "communal/ReentrancyGuard.sol";
import "communal/Owned.sol";
import "communal/SafeERC20.sol";
import "communal/TransferHelper.sol";

import "forge-std/console.sol";

/*
 * VDAMM Contract:
 *
 */

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint wad) external;
}

interface ILSDVault {
    function darknetAddress() external view returns (address);

    function redeemFee() external view returns (uint256);

    function exit(uint256 amount) external;

    function isEnabled(address lsd) external view returns (bool);

    function remainingRoomToCap(address lsd, uint256 marginalDeposit) external view returns (uint256);

    function getTargetAmount(address lsd, uint256 marginalDeposit) external view returns (uint256);
}

interface IDarknet {
    function checkPrice(address lsd) external view returns (uint256);
}

interface IunshETH {
    function timelock_address() external view returns (address);
}

/*
 * Fee Collector Contract:
 * This contract is responsible for managing fee curves and calculations
 * vdAMM swap and unshETH redemption fees are collected here after fee switch is turned on
 */

contract VDAMM is Owned, ReentrancyGuard {
    using SafeERC20 for IERC20;
    /*
    ============================================================================
    State Variables
    ============================================================================
    */
    address public constant wethAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant unshethAddress = 0x0Ae38f7E10A43B5b2fB064B42a2f4514cbA909ef;
    address public immutable vaultAddress;
    address public darknetAddress;

    address[] public lsds;

    ILSDVault public vault;
    IDarknet public darknet;

    bool public ammPaused = false;

    struct AmmFee {
        uint256 baseFee;
        uint256 dynamicFee;
        uint256 instantRedemptionFee;
    }

    struct AMMFeeConfig {
        uint256 baseFeeBps;
        uint256 instantRedemptionFeeBps;
        uint256 unshethFeeShareBps;
        uint256 dynamicFeeSlope_x;
        uint256 dynamicFeeSlope_x2;
    }

    //Mutable parameters, can be changed by governance
    AMMFeeConfig ammFeeConfig = AMMFeeConfig(1, 20, 10000, 50, 1000);

    bool public depositFeeEnabled = true;

    //Immutable parameters, cannot be changed after deployment
    uint256 public constant maxBaseFeeBps = 10;
    uint256 public constant maxDynamicFeeBps = 200;
    uint256 public constant minUnshethFeeShareBps = 5000; //At least half swap fees go to unshETH

    /*
    ============================================================================
    Events
    ============================================================================
    */

    //Fee curve parameters
    event BaseFeeUpdated(uint256 _baseFeeBps);
    event UnshethFeeShareUpdated(uint256 _unshethFeeShareBps);
    event InstantRedemptionFeeUpdated(uint256 _instantRedemptionFeeBps);
    event FeeSlopesUpdated(uint256 _dynamicFeeSlope_x, uint256 _dynamicFeeSlope_x2);
    event DepositFeeToggled(bool depositFeeEnabled);

    //Admin functions
    event PauseToggled(bool ammPaused);
    event TokensWithdrawn(address tokenAddress, uint256 amount);
    event EthWithdrawn(uint256 amount);
    event DarknetAddressUpdated(address darknetAddress);
    event NewLsdApproved(address lsd);

    /*
    ============================================================================
    Constructor
    ============================================================================
    */
    constructor(address _owner, address[] memory _lsds) Owned(_owner) {
        vaultAddress = IunshETH(unshethAddress).timelock_address();
        vault = ILSDVault(vaultAddress);
        darknetAddress = vault.darknetAddress();
        darknet = IDarknet(darknetAddress);
        lsds = _lsds;

        //set approvals
        for (uint256 i = 0; i < _lsds.length; i = unchkIncr(i)) {
            TransferHelper.safeApprove(_lsds[i], vaultAddress, type(uint256).max);
        }

        TransferHelper.safeApprove(unshethAddress, vaultAddress, type(uint256).max);
    }

    /*
    ============================================================================
    Function Modifiers
    ============================================================================
    */
    modifier onlyWhenUnpaused() {
        require(ammPaused == false, "AMM is paused");
        _;
    }

    modifier onlyWhenPaused() {
        require(ammPaused == true, "AMM must be paused");
        _;
    }

    /*
    ============================================================================
    vdAMM configuration functions (multisig only)
    ============================================================================
    */

    function setBaseFee(uint256 _baseFeeBps) external onlyOwner {
        require(_baseFeeBps <= maxBaseFeeBps, "Base fee cannot be greater than max fee");
        ammFeeConfig.baseFeeBps = _baseFeeBps;
        emit BaseFeeUpdated(_baseFeeBps);
    }

    function setDynamicFeeSlopes(uint256 _dynamicFeeSlope_x, uint256 _dynamicFeeSlope_x2) external onlyOwner {
        ammFeeConfig.dynamicFeeSlope_x = _dynamicFeeSlope_x;
        ammFeeConfig.dynamicFeeSlope_x2 = _dynamicFeeSlope_x2;
        emit FeeSlopesUpdated(_dynamicFeeSlope_x, _dynamicFeeSlope_x2);
    }

    function setUnshethFeeShare(uint256 _unshethFeeShareBps) external onlyOwner {
        require(_unshethFeeShareBps <= 10000, "unshETH fee share cannot be greater than 100%");
        require(_unshethFeeShareBps >= minUnshethFeeShareBps, "unshETH fee share must be greater than min");
        ammFeeConfig.unshethFeeShareBps = _unshethFeeShareBps;
        emit UnshethFeeShareUpdated(_unshethFeeShareBps);
    }

    function setInstantRedemptionFee(uint256 _instantRedemptionFeeBps) external onlyOwner {
        require(
            _instantRedemptionFeeBps <= maxDynamicFeeBps,
            "Instant redemption fee cannot be greater than max fee"
        );
        ammFeeConfig.instantRedemptionFeeBps = _instantRedemptionFeeBps;
        emit InstantRedemptionFeeUpdated(_instantRedemptionFeeBps);
    }

    function toggleDepositFee() external onlyOwner {
        depositFeeEnabled = !depositFeeEnabled;
        emit DepositFeeToggled(depositFeeEnabled);
    }

    /*
    ============================================================================
    Admin functions (multisig only)
    ============================================================================
    */

    function togglePaused() external onlyOwner {
        ammPaused = !ammPaused;
        emit PauseToggled(ammPaused);
    }

    function withdrawTokens(address tokenAddress) external onlyOwner {
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        TransferHelper.safeTransfer(tokenAddress, msg.sender, balance);
        emit TokensWithdrawn(tokenAddress, balance);
    }

    function withdrawStuckEth() external onlyOwner {
        uint256 ethBal = address(this).balance;
        Address.sendValue(payable(owner), ethBal);
        emit EthWithdrawn(ethBal);
    }

    function updateDarknetAddress() external onlyOwner {
        darknetAddress = ILSDVault(vaultAddress).darknetAddress();
        darknet = IDarknet(darknetAddress);
        emit DarknetAddressUpdated(darknetAddress);
    }

    //Technically, full timelock proposal is needed to add a new LSD.  This function just ensures new vdAMM doesn't need to be re-deployed
    function approveNewLsd(address lsdAddress) external onlyOwner {
        lsds.push(lsdAddress);
        TransferHelper.safeApprove(lsdAddress, vaultAddress, type(uint256).max);
        emit NewLsdApproved(lsdAddress);
    }

    /*
    ============================================================================
    Fee curve logic
    ============================================================================
    */

    function unshethFeeShareBps() public view returns (uint256) {
        return ammFeeConfig.unshethFeeShareBps;
    }

    function getEthConversionRate(address lsd) public view returns (uint256) {
        return darknet.checkPrice(lsd);
    }

    //View function to get lsdAmountOut and fees for a swap. Does not deal with require checks if the swap is valid
    function swapLsdToLsdCalcs(
        uint256 amountIn,
        address lsdIn,
        address lsdOut
    ) public view returns (uint256, uint256, uint256, uint256) {
        //Sanity checks
        require(lsdIn != lsdOut, "Cannot swap same lsd");
        require(vault.isEnabled(lsdIn), "lsdIn not enabled");
        require(vault.isEnabled(lsdOut), "lsdOut is not enabled");
        require(amountIn > 0, "Cannot swap 0 lsd");

        //In a swap, total amount of ETH in the vault is constant we're swapping on a 1:1 ETH basis
        //To simplify and do a conservative first order approximation, we assume marginal deposit amount is 0
        uint256 distanceToCap = vault.remainingRoomToCap(lsdIn, 0);
        require(amountIn <= distanceToCap, "Trade would exceed cap");

        uint256 ethAmountIn = (amountIn * getEthConversionRate(lsdIn)) / 1e18;
        uint256 ethAmountOutBeforeFees = ethAmountIn;

        //Calculate fees
        (uint256 baseFee, uint256 dynamicFee, ) = getAmmFee(ethAmountIn, lsdIn, lsdOut); //in lsdOut terms

        //Fees are paid in lsdOut terms
        uint256 totalFee = baseFee + dynamicFee;
        uint256 protocolFee = (totalFee * (10000 - ammFeeConfig.unshethFeeShareBps)) / 10000;

        uint256 lsdAmountOutBeforeFees = (ethAmountOutBeforeFees * 1e18) / getEthConversionRate(lsdOut);
        uint256 lsdAmountOut = lsdAmountOutBeforeFees - totalFee;

        return (lsdAmountOut, baseFee, dynamicFee, protocolFee);
    }

    //returns amm fees in lsdOut terms
    function getAmmFee(
        uint256 ethAmountIn,
        address lsdIn,
        address lsdOut
    ) public view returns (uint256, uint256, uint256) {
        uint256 baseFeeInEthTerms = (ethAmountIn * ammFeeConfig.baseFeeBps) / 10000;

        uint256 lsdInDynamicFeeBps = getLsdDynamicFeeBps(ethAmountIn, lsdIn, true);
        uint256 lsdOutDynamicFeeBps = getLsdDynamicFeeBps(ethAmountIn, lsdOut, false);

        if (lsdOut == wethAddress) {
            lsdOutDynamicFeeBps = _min(maxDynamicFeeBps, lsdOutDynamicFeeBps + ammFeeConfig.instantRedemptionFeeBps);
        }

        //Take the higher of two and cap at maxDynamicFeeBps
        uint256 dynamicFeeBps = _max(lsdInDynamicFeeBps, lsdOutDynamicFeeBps);
        uint256 dynamicFeeInEthTerms = (ethAmountIn * dynamicFeeBps) / 10000;

        uint256 baseFee = (baseFeeInEthTerms * 1e18) / getEthConversionRate(lsdOut);
        uint256 dynamicFee = (dynamicFeeInEthTerms * 1e18) / getEthConversionRate(lsdOut);

        return (baseFee, dynamicFee, dynamicFeeBps);
    }

    // Dynamic fee (inspired by GLP, with unshETH twist)
    // Fees are 0 when swaps help rebalance the vault (i.e. when difference to target is reduced post-swap)
    // When swaps worsen the distance to target, fees are applied
    // Fees are proportional to the square of the % distance to target (taking the average before and after the swap)
    // Small deviations are generally low fee
    // Large deviations are quadratically higher penalty (since co-variance of unshETH is quadratically increasing)
    // All deviations to target and normalized by the target weight (otherwise small LSDs won't be penalized at all)
    // Fees are capped at maxDynamicFeeBps
    function getLsdDynamicFeeBps(
        uint256 ethDelta,
        address lsd,
        bool increment
    ) public view returns (uint256) {
        uint256 lsdBalance = IERC20(lsd).balanceOf(vaultAddress);
        uint256 initialAmount = (lsdBalance * getEthConversionRate(lsd)) / 1e18; //lsd balance in ETH terms
        uint256 nextAmount;

        if (increment) {
            nextAmount = initialAmount + ethDelta;
        } else {
            nextAmount = initialAmount - _min(initialAmount, ethDelta);
        }

        uint256 targetAmount = (vault.getTargetAmount(lsd, 0) * getEthConversionRate(lsd)) / 1e18;
        uint256 initialDiff = _absDiff(initialAmount, targetAmount);
        uint256 nextDiff = _absDiff(nextAmount, targetAmount);

        //If action improves the distance to target, zero fee
        if (nextDiff < initialDiff) {
            return 0; //no fee
        }

        //If target is zero and we are moving away from it, charge max fee
        if (targetAmount == 0) {
            return maxDynamicFeeBps;
        }

        //Otherwise Fee = a*x + b*x^2, where x = averageDiff / targetAmount
        uint256 averageDiff = (initialDiff + nextDiff) / 2;
        uint256 x = (averageDiff * 1e18) / targetAmount;
        uint256 x2 = (x * x) / 1e18;

        uint256 dynamicFeeBps_x = (ammFeeConfig.dynamicFeeSlope_x * x) / 1e18;
        uint256 dynamicFeeBps_x2 = (ammFeeConfig.dynamicFeeSlope_x2 * x2) / 1e18;

        return _min(maxDynamicFeeBps, dynamicFeeBps_x + dynamicFeeBps_x2);
    }

    function getDepositFee(uint256 lsdAmountIn, address lsd) public view returns (uint256, uint256) {
        if (!depositFeeEnabled) {
            return (0, 0);
        }
        uint256 ethAmountIn = (lsdAmountIn * getEthConversionRate(lsd)) / 1e18;
        uint256 dynamicFeeBps = getLsdDynamicFeeBps(ethAmountIn, lsd, true);
        uint256 redeemFeeBps = vault.redeemFee();

        //If dynamic fee < redeem fee, then deposit fee = 0, otherwise deposit fee = dynamic fee - redeem fee
        uint256 depositFeeBps = dynamicFeeBps - _min(dynamicFeeBps, redeemFeeBps);

        uint256 depositFee = (lsdAmountIn * depositFeeBps) / 10000;
        uint256 protocolFee = (depositFee * (10000 - ammFeeConfig.unshethFeeShareBps)) / 10000;
        return (depositFee, protocolFee);
    }

    /*
   ============================================================================
   Swapping
   ============================================================================
   */

    function swapLsdToEth(
        uint256 amountIn,
        address lsdIn,
        uint256 minAmountOut
    ) external nonReentrant onlyWhenUnpaused returns (uint256, uint256, uint256) {
        //Transfer lsdIn from user to vault
        TransferHelper.safeTransferFrom(lsdIn, msg.sender, address(this), amountIn);
        (uint256 wethAmountOut, uint256 baseFee, uint256 dynamicFee) = _swapLsdToLsd(
            amountIn,
            lsdIn,
            wethAddress,
            minAmountOut
        );
        //Convert weth to ETH and send to user
        IWETH(wethAddress).withdraw(wethAmountOut);
        Address.sendValue(payable(msg.sender), wethAmountOut);
        return (wethAmountOut, baseFee, dynamicFee);
    }

    function swapEthToLsd(
        address lsdOut,
        uint256 minAmountOut
    ) external payable nonReentrant onlyWhenUnpaused returns (uint256, uint256, uint256) {
        //Convert ETH to weth and swap
        IWETH(wethAddress).deposit{ value: msg.value }();
        (uint256 lsdAmountOut, uint256 baseFee, uint256 dynamicFee) = _swapLsdToLsd(
            msg.value,
            wethAddress,
            lsdOut,
            minAmountOut
        );
        //Send lsdOut to user
        TransferHelper.safeTransfer(lsdOut, msg.sender, lsdAmountOut);
        return (lsdAmountOut, baseFee, dynamicFee);
    }

    function swapLsdToLsd(
        uint256 amountIn,
        address lsdIn,
        address lsdOut,
        uint256 minAmountOut
    ) external nonReentrant onlyWhenUnpaused returns (uint256, uint256, uint256) {
        //Transfer lsdIn from user to vdamm and swap
        TransferHelper.safeTransferFrom(lsdIn, msg.sender, address(this), amountIn);
        (uint256 lsdAmountOut, uint256 baseFee, uint256 dynamicFee) = _swapLsdToLsd(
            amountIn,
            lsdIn,
            lsdOut,
            minAmountOut
        );
        //Send lsdOut to user
        TransferHelper.safeTransfer(lsdOut, msg.sender, lsdAmountOut);
        return (lsdAmountOut, baseFee, dynamicFee);
    }

    // Converts lsd to another lsd.
    // Collects protocol fees in vdAMM contract, and keeps unshETH share of fees for unshETH holders.
    // Assumes lsdIn is already in vdamm contract, lsdAmountOut + protocol fees is kept in vdAMM contract
    // Returns lsdAmountOut.
    function _swapLsdToLsd(
        uint256 amountIn,
        address lsdIn,
        address lsdOut,
        uint256 minAmountOut
    ) internal returns (uint256, uint256, uint256) {
        (uint256 lsdAmountOut, uint256 baseFee, uint256 dynamicFee, uint256 protocolFee) = swapLsdToLsdCalcs(
            amountIn,
            lsdIn,
            lsdOut
        );
        require(lsdAmountOut >= minAmountOut, "Slippage limit reached");

        //Amount to take out from vault = amountOut + protocolFee from vault. unshETH share of fees are kept in the vault
        uint256 lsdAmountOutFromVault = lsdAmountOut + protocolFee;
        require(
            lsdAmountOutFromVault <= IERC20(lsdOut).balanceOf(vaultAddress),
            "Not enough lsdOut in vault"
        );

        //Transfer amountIn from vdAMM to the vault
        TransferHelper.safeTransfer(lsdIn, vaultAddress, amountIn);

        //Transfer lsdOut from vault to vdAMM
        TransferHelper.safeTransferFrom(lsdOut, vaultAddress, address(this), lsdAmountOutFromVault);

        //Return the lsdAmountOut (which subtracts protocolFee).  ProtocolFee is kept in vdAMM contract
        return (lsdAmountOut, baseFee, dynamicFee);
    }

    /*
    ============================================================================
    Other functions
    ============================================================================
    */

    function unchkIncr(uint256 i) private pure returns (uint256) {
        unchecked {
            return i + 1;
        }
    }

    function _min(uint256 _a, uint256 _b) private pure returns (uint256) {
        if (_a < _b) {
            return _a;
        } else {
            return _b;
        }
    }

    function _max(uint256 _a, uint256 _b) private pure returns (uint256) {
        if (_a > _b) {
            return _a;
        } else {
            return _b;
        }
    }

    function _absDiff(uint256 _a, uint256 _b) private pure returns (uint256) {
        if (_a > _b) {
            return _a - _b;
        } else {
            return _b - _a;
        }
    }

    //Allow receiving eth to the contract
    receive() external payable {}
}