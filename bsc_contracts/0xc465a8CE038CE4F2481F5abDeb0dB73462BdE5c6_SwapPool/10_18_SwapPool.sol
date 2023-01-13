// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { EnumerableSetUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import { ILP } from "./interfaces/ILP.sol";
import { IBNBPool } from "./interfaces/IBNBPool.sol";
import { IABNBC } from "./interfaces/IABNBC.sol";
import { IWBNB } from "./interfaces/IWBNB.sol";
import "./interfaces/IERC3156FlashBorrower.sol";
import "./util/TransferHelper.sol";
import "./interfaces/IBNBHandler.sol";
import "./BNBHandler.sol";
import "hardhat/console.sol";

enum UserType {
    MANAGER,
    LIQUIDITY_PROVIDER,
    INTEGRATOR
}

enum FeeType {
    OWNER,
    MANAGER,
    INTEGRATOR,
    STAKE,
    UNSTAKE,
    FLASH_LOAN,
    FLASH_LOAN_FIXED
}

struct FeeAmounts {
    uint128 nativeFee;
    uint128 abnbcFee;
}

// solhint-disable max-states-count
contract SwapPool is OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    event UserTypeChanged(address indexed user, UserType indexed utype, bool indexed added);
    event FeeChanged(FeeType indexed utype, uint256 oldFee, uint24 newFee);
    event IntegratorLockEnabled(bool indexed enabled);
    event ProviderLockEnabled(bool indexed enabled);
    event ExcludedFromFee(address indexed user, bool indexed excluded);
    event LiquidityChange(
        address indexed user,
        uint256 nativeAmount,
        uint256 stakingAmount,
        uint256 nativeReserve,
        uint256 stakingReserve,
        bool indexed added
    );
    event Swap(
        address indexed sender,
        address indexed receiver,
        bool indexed nativeToCeros,
        uint256 amountIn,
        uint256 amountOut
    );
    event FlashLoan(address indexed receiver, address token, uint256 amount, uint256 fee);
    event FlashLoanMaxChanged(uint256 oldAmount, uint256 newAmount);
    event BNBPoolChanged(address oldPool, address newPool);
    event FeesWithdrawn(address receiver, uint128 nativeAmount, uint128 abnbcAmount);
    event FeesUpdated(FeeType ftype, uint128 nativeAmount, uint128 abnbcAmount);
    event ThresholdChanged(uint24 oldValue, uint24 newValue);
    event PoolStake(uint256 amount);
    event PoolUnstake(uint256 amount);
    event NativeBalanceChanged(uint256 amount);
    event NativeReceived(uint256 amount, address sender);

    uint24 public constant FEE_MAX = 10000;

    EnumerableSetUpgradeable.AddressSet internal managers_;
    EnumerableSetUpgradeable.AddressSet internal integrators_;
    EnumerableSetUpgradeable.AddressSet internal liquidityProviders_;

    IWBNB public wbnb;
    IABNBC public abnbc;
    ILP public lpToken;

    uint256 public wbnbAmount;
    uint256 public abnbcAmount;

    uint24 public ownerFee;
    uint24 public managerFee;
    uint24 public integratorFee;
    uint24 public stakeFee;
    uint24 public unstakeFee;
    uint24 public threshold;
    uint24 public flashLoanFee;

    bool public integratorLockEnabled;
    bool public providerLockEnabled;

    FeeAmounts public ownerFeeCollected;

    FeeAmounts public managerFeeCollected;
    FeeAmounts internal _accFeePerManager;
    FeeAmounts internal _alreadyUpdatedFees;
    FeeAmounts internal _claimedManagerFees;

    uint128 public flashLoanFixedFee;
    uint128 public flashLoanMaxAmount;

    mapping(address => FeeAmounts) public managerRewardDebt;
    mapping(address => bool) public excludedFromFee;

    IBNBPool public bnbPool;

    bytes32 public constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

    address public abnbb;
    IBNBHandler public bnbHandler;

    modifier onlyOwnerOrManager() {
        require(
            msg.sender == owner() || managers_.contains(msg.sender),
            "only owner or manager can call this function"
        );
        _;
    }

    modifier onlyManager() {
        require(managers_.contains(msg.sender), "only manager can call this function");
        _;
    }

    modifier onlyIntegrator() {
        if (integratorLockEnabled) {
            require(integrators_.contains(msg.sender), "only integrators can call this function");
        }
        _;
    }

    modifier onlyProvider() {
        if (providerLockEnabled) {
            require(
                liquidityProviders_.contains(msg.sender),
                "only liquidity providers can call this function"
            );
        }
        _;
    }

    function initialize(
        address _wbnb,
        address _abnbc,
        address _abnbb,
        address _lpToken,
        bool _integratorLockEnabled,
        bool _providerLockEnabled
    ) public initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        wbnb = IWBNB(_wbnb);
        abnbc = IABNBC(_abnbc);
        abnbb = _abnbb;
        lpToken = ILP(_lpToken);
        bnbHandler = new BNBHandler();

        integratorLockEnabled = _integratorLockEnabled;
        emit IntegratorLockEnabled(_integratorLockEnabled);

        providerLockEnabled = _providerLockEnabled;
        emit ProviderLockEnabled(_providerLockEnabled);
    }

    function setFlashLoanMaxAmount(uint128 amount) external onlyOwner {
        emit FlashLoanMaxChanged(flashLoanMaxAmount, amount);
        flashLoanMaxAmount = amount;
    }

    function addLiquidityEth() external payable virtual onlyProvider nonReentrant {
        _addLiquidity(msg.value, true);
    }

    function addLiquidity(uint256 _amount) external virtual onlyProvider nonReentrant {
        _addLiquidity(_amount, false);
    }

    function _addLiquidity(uint256 _amount, bool useEth) internal virtual {
        if (useEth) {
            wbnb.deposit{ value: _amount }();

            if (msg.value > _amount) {
                uint256 diff = msg.value - _amount;

                _sendValue(msg.sender, diff);
            }
        } else {
            TransferHelper.safeTransferFrom(address(wbnb), msg.sender, address(this), _amount);
        }

        if (wbnbAmount == 0) {
            require(_amount > 1e18, "cannot add first time less than 1 token");

            wbnbAmount = _amount;
        } else {
            wbnbAmount += _amount;
        }

        lpToken.mint(msg.sender, _amount);

        emit LiquidityChange(msg.sender, _amount, 0, wbnbAmount, abnbcAmount, true);
    }

    function removeLiquidity(uint256 lpAmount) external virtual nonReentrant {
        _removeLiquidityLp(lpAmount, false);
    }

    function removeLiquidityEth(uint256 lpAmount) external virtual nonReentrant {
        _removeLiquidityLp(lpAmount, true);
    }

    function removeLiquidityPercent(uint256 percent) external virtual nonReentrant {
        _removeLiquidityPercent(percent, false);
    }

    function removeLiquidityPercentEth(uint256 percent) external virtual nonReentrant {
        _removeLiquidityPercent(percent, true);
    }

    function _removeLiquidityPercent(uint256 percent, bool useEth) internal virtual {
        require(percent > 0 && percent <= 1e18, "percent should be more than 0 and less than 1e18"); // max percent(100%) is -> 10 ** 18
        uint256 balance = lpToken.balanceOf(msg.sender);
        uint256 removedLp = (balance * percent) / 1e18;
        _removeLiquidity(removedLp, useEth);
    }

    function _removeLiquidityLp(uint256 removedLp, bool useEth) internal virtual {
        uint256 balance = lpToken.balanceOf(msg.sender);
        if (removedLp == type(uint256).max) {
            removedLp = balance;
        } else {
            require(removedLp <= balance, "you want to remove more than your lp balance");
        }
        require(removedLp > 0, "lp amount should be more than 0");
        _removeLiquidity(removedLp, useEth);
    }

    function _removeLiquidity(uint256 removedLp, bool useEth) internal virtual {
        uint256 totalSupply = lpToken.totalSupply();
        lpToken.burn(msg.sender, removedLp);
        uint256 amount0Removed = removedLp;

        wbnbAmount -= amount0Removed;

        if (useEth) {
            wbnb.withdraw(amount0Removed);
            _sendValue(msg.sender, amount0Removed);
        } else {
            TransferHelper.safeTransfer(address(wbnb), msg.sender, amount0Removed);
        }

        emit LiquidityChange(
            msg.sender,
            amount0Removed,
            0,
            wbnbAmount,
            abnbcAmount,
            false
        );
    }

    function swapEth(
        bool wbnbToABNBC,
        uint256 amount,
        address receiver
    ) external payable virtual onlyIntegrator nonReentrant returns (uint256 amountOut) {
        uint256 amountIn;

        if (wbnbToABNBC) {
            amountIn = msg.value;
        } else {
            require(msg.value == 0, "no need to send value if swapping aBNBc to Native");
            amountIn = amount;
        }

        return _swap(wbnbToABNBC, amountIn, receiver, true);
    }

    function swap(
        bool wbnbToABNBC,
        uint256 amountIn,
        address receiver
    ) external virtual onlyIntegrator nonReentrant returns (uint256 amountOut) {
        return _swap(wbnbToABNBC, amountIn, receiver, false);
    }

    function _swap(
        bool wbnbcToABNBC,
        uint256 amountIn,
        address receiver,
        bool useEth
    ) internal virtual returns (uint256 amountOut) {
        if (wbnbcToABNBC) {
            if (useEth) {
                wbnb.deposit{ value: amountIn }();
            } else {
                TransferHelper.safeTransferFrom(address(wbnb), msg.sender, address(this), amountIn);
            }
            if (!excludedFromFee[msg.sender]) {
                uint256 stakeFeeAmt = (amountIn * stakeFee) / FEE_MAX;
                amountIn -= stakeFeeAmt;
                uint256 managerFeeAmt = (stakeFeeAmt * managerFee) / FEE_MAX;
                uint256 ownerFeeAmt = (stakeFeeAmt * ownerFee) / FEE_MAX;
                uint256 integratorFeeAmt;
                if (integratorLockEnabled) {
                    integratorFeeAmt = (stakeFeeAmt * integratorFee) / FEE_MAX;
                    if (integratorFeeAmt > 0) {
                        TransferHelper.safeTransfer(address(wbnb), msg.sender, integratorFeeAmt);
                    }
                }
                wbnbAmount +=
                amountIn +
                (stakeFeeAmt - managerFeeAmt - ownerFeeAmt - integratorFeeAmt);

                ownerFeeCollected.nativeFee += uint128(ownerFeeAmt);
                managerFeeCollected.nativeFee += uint128(managerFeeAmt);
            } else {
                wbnbAmount += amountIn;
            }
            (amountOut,) = getAmountOut(true, amountIn, true);
            require(abnbcAmount >= amountOut, "Not enough liquidity");
            abnbcAmount -= amountOut;
            TransferHelper.safeTransfer(address(abnbc), receiver, amountOut);
            emit Swap(msg.sender, receiver, wbnbcToABNBC, amountIn, amountOut);
        } else {
            TransferHelper.safeTransferFrom(address(abnbc), msg.sender, address(this), amountIn);
            if (!excludedFromFee[msg.sender]) {
                uint256 unstakeFeeAmt = (amountIn * unstakeFee) / FEE_MAX;
                amountIn -= unstakeFeeAmt;
                uint256 managerFeeAmt = (unstakeFeeAmt * managerFee) / FEE_MAX;
                uint256 ownerFeeAmt = (unstakeFeeAmt * ownerFee) / FEE_MAX;
                uint256 integratorFeeAmt;
                if (integratorLockEnabled) {
                    integratorFeeAmt = (unstakeFeeAmt * integratorFee) / FEE_MAX;
                    if (integratorFeeAmt > 0) {
                        TransferHelper.safeTransfer(address(abnbc), msg.sender, integratorFeeAmt);
                    }
                }
                abnbcAmount +=
                amountIn +
                (unstakeFeeAmt - managerFeeAmt - ownerFeeAmt - integratorFeeAmt);

                ownerFeeCollected.abnbcFee += uint128(ownerFeeAmt);
                managerFeeCollected.abnbcFee += uint128(managerFeeAmt);
            } else {
                abnbcAmount += amountIn;
            }
            (amountOut,) = getAmountOut(false, amountIn, true);
            require(wbnbAmount >= amountOut, "Not enough liquidity");
            wbnbAmount -= amountOut;

            if (useEth) {
                wbnb.transfer(address(bnbHandler), amountOut);
                bnbHandler.withdraw(address(wbnb), amountOut);
                _sendValue(receiver, amountOut);
            } else {
                TransferHelper.safeTransfer(address(wbnb), receiver, amountOut);
            }

            emit Swap(msg.sender, receiver, wbnbcToABNBC, amountIn, amountOut);

            uint256 abnbcBal = abnbc.balanceOf(address(this));

            // 0.5 aBNBc
            if (abnbcBal >= 5e17) {
                abnbc.approve(abnbb, abnbcBal);
                bnbPool.unstakeCerts(abnbcBal);
                abnbcAmount -= abnbcBal;

                skim();
            }
        }
    }

    function getAmountOut(
        bool wrappedToABNBC,
        uint256 amountIn,
        bool isExcludedFromFee
    ) public view virtual returns (uint256 amountOut, bool enoughLiquidity) {
        uint256 ratio = abnbc.ratio();
        if (wrappedToABNBC) {
            if (!isExcludedFromFee) {
                uint256 stakeFeeAmt = (amountIn * stakeFee) / FEE_MAX;
                amountIn -= stakeFeeAmt;
            }
            amountOut = (amountIn * ratio) / 1e18;
            enoughLiquidity = abnbcAmount >= amountOut;
        } else {
            if (!isExcludedFromFee) {
                uint256 unstakeFeeAmt = (amountIn * unstakeFee) / FEE_MAX;
                amountIn -= unstakeFeeAmt;
            }
            amountOut = (amountIn * 1e18) / ratio;
            enoughLiquidity = wbnbAmount >= amountOut;
        }
    }

    function _sendValue(address receiver, uint256 amount) internal virtual {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = payable(receiver).call{ value: amount }("");
        require(success, "unable to send value, recipient may have reverted");
    }

    function withdrawOwnerFeeEth(uint256 amount0, uint256 amount1)
    external
    virtual
    onlyOwner
    nonReentrant
    {
        _withdrawOwnerFee(amount0, amount1, true);
    }

    function withdrawOwnerFee(uint256 amount0, uint256 amount1)
    external
    virtual
    onlyOwner
    nonReentrant
    {
        _withdrawOwnerFee(amount0, amount1, false);
    }

    function _withdrawOwnerFee(
        uint256 amount0Raw,
        uint256 amount1Raw,
        bool useEth
    ) internal virtual {
        uint128 amount0;
        uint128 amount1;
        if (amount0Raw == type(uint256).max) {
            amount0 = ownerFeeCollected.nativeFee;
        } else {
            amount0 = uint128(amount0Raw);
        }
        if (amount1Raw == type(uint256).max) {
            amount1 = ownerFeeCollected.abnbcFee;
        } else {
            amount1 = uint128(amount1Raw);
        }
        if (amount0 > 0) {
            ownerFeeCollected.nativeFee -= amount0;
            if (useEth) {
                wbnb.withdraw(amount0);
                _sendValue(msg.sender, amount0);
            } else {
                TransferHelper.safeTransfer(address(wbnb), msg.sender, amount0);
            }
        }
        if (amount1 > 0) {
            ownerFeeCollected.abnbcFee -= amount1;
            TransferHelper.safeTransfer(address(abnbc), msg.sender, amount1);
        }

        emit FeesWithdrawn(msg.sender, amount0, amount1);
    }

    function getRemainingManagerFee(address managerAddress)
    external
    view
    virtual
    returns (FeeAmounts memory feeRewards)
    {
        if (managers_.contains(managerAddress)) {
            uint256 managersLength = managers_.length();
            FeeAmounts memory currentManagerRewardDebt = managerRewardDebt[managerAddress];
            FeeAmounts memory accFee;
            accFee.nativeFee =
            _accFeePerManager.nativeFee +
            (managerFeeCollected.nativeFee - _alreadyUpdatedFees.nativeFee) /
            uint128(managersLength);
            accFee.abnbcFee =
            _accFeePerManager.abnbcFee +
            (managerFeeCollected.abnbcFee - _alreadyUpdatedFees.abnbcFee) /
            uint128(managersLength);
            feeRewards.nativeFee = accFee.nativeFee - currentManagerRewardDebt.nativeFee;
            feeRewards.abnbcFee = accFee.abnbcFee - currentManagerRewardDebt.abnbcFee;
        }
    }

    function withdrawManagerFee() external virtual onlyManager nonReentrant {
        _withdrawManagerFee(msg.sender, false);
    }

    function withdrawManagerFeeEth() external virtual onlyManager nonReentrant {
        _withdrawManagerFee(msg.sender, true);
    }

    function _withdrawManagerFee(address managerAddress, bool useNative) internal virtual {
        FeeAmounts memory feeRewards;
        FeeAmounts storage currentManagerRewardDebt = managerRewardDebt[managerAddress];
        _updateManagerFees();
        feeRewards.nativeFee = _accFeePerManager.nativeFee - currentManagerRewardDebt.nativeFee;
        feeRewards.abnbcFee = _accFeePerManager.abnbcFee - currentManagerRewardDebt.abnbcFee;
        if (feeRewards.nativeFee > 0) {
            currentManagerRewardDebt.nativeFee += feeRewards.nativeFee;
            _claimedManagerFees.nativeFee += feeRewards.nativeFee;
            if (useNative) {
                wbnb.withdraw(feeRewards.nativeFee);
                _sendValue(managerAddress, feeRewards.nativeFee);
            } else {
                TransferHelper.safeTransfer(address(wbnb), managerAddress, feeRewards.nativeFee);
            }
        }
        if (feeRewards.abnbcFee > 0) {
            currentManagerRewardDebt.abnbcFee += feeRewards.abnbcFee;
            _claimedManagerFees.abnbcFee += feeRewards.abnbcFee;
            TransferHelper.safeTransfer(address(abnbc), managerAddress, feeRewards.abnbcFee);
        }

        emit FeesWithdrawn(managerAddress, feeRewards.nativeFee, feeRewards.abnbcFee);
    }

    function _updateManagerFees() internal virtual {
        uint256 managersLength = managers_.length();
        _accFeePerManager.nativeFee +=
        (managerFeeCollected.nativeFee - _alreadyUpdatedFees.nativeFee) /
        uint128(managersLength);
        _accFeePerManager.abnbcFee +=
        (managerFeeCollected.abnbcFee - _alreadyUpdatedFees.abnbcFee) /
        uint128(managersLength);
        _alreadyUpdatedFees.nativeFee = managerFeeCollected.nativeFee;
        _alreadyUpdatedFees.abnbcFee = managerFeeCollected.abnbcFee;

        emit FeesUpdated(FeeType.MANAGER, _alreadyUpdatedFees.nativeFee, _alreadyUpdatedFees.abnbcFee);
    }

    function add(address value, UserType utype) public virtual returns (bool) {
        require(value != address(0), "cannot add address(0)");
        bool success = false;
        if (utype == UserType.MANAGER) {
            require(msg.sender == owner(), "Only owner can add manager");
            if (!managers_.contains(value)) {
                uint256 managersLength = managers_.length();
                if (managersLength != 0) {
                    _updateManagerFees();
                    managerRewardDebt[value].nativeFee = _accFeePerManager.nativeFee;
                    managerRewardDebt[value].abnbcFee = _accFeePerManager.abnbcFee;
                }
                success = managers_.add(value);
            }
        } else if (utype == UserType.LIQUIDITY_PROVIDER) {
            require(managers_.contains(msg.sender), "Only manager can add liquidity provider");
            success = liquidityProviders_.add(value);
        } else {
            require(managers_.contains(msg.sender), "Only manager can add integrator");
            success = integrators_.add(value);
        }
        if (success) {
            emit UserTypeChanged(value, utype, true);
        }
        return success;
    }

    function setFee(uint24 newFee, FeeType feeType) external virtual onlyOwnerOrManager {
        require(newFee < FEE_MAX * 10, "Unsupported size of fee!");
        if (feeType == FeeType.OWNER) {
            require(msg.sender == owner(), "only owner can call this function");
            require(newFee + managerFee + integratorFee < FEE_MAX, "fee sum is more than 100%");
            emit FeeChanged(feeType, ownerFee, newFee);
            ownerFee = newFee;
        } else if (feeType == FeeType.MANAGER) {
            require(newFee + ownerFee + integratorFee < FEE_MAX, "fee sum is more than 100%");
            emit FeeChanged(feeType, managerFee, newFee);
            managerFee = newFee;
        } else if (feeType == FeeType.INTEGRATOR) {
            require(newFee + ownerFee + managerFee < FEE_MAX, "fee sum is more than 100%");
            emit FeeChanged(feeType, integratorFee, newFee);
            integratorFee = newFee;
        } else if (feeType == FeeType.STAKE) {
            emit FeeChanged(feeType, stakeFee, newFee);
            stakeFee = newFee;
        } else if (feeType == FeeType.FLASH_LOAN) {
            emit FeeChanged(feeType, flashLoanFee, newFee);
            flashLoanFee = newFee;
        } else if (feeType == FeeType.FLASH_LOAN_FIXED) {
            emit FeeChanged(feeType, flashLoanFixedFee, newFee);
            flashLoanFixedFee = newFee;
        } else {
            emit FeeChanged(feeType, unstakeFee, newFee);
            unstakeFee = newFee;
        }
    }

    function setThreshold(uint24 newThreshold) external virtual onlyManager {
        require(newThreshold < FEE_MAX / 2, "threshold shuold be less than 50%");
        emit ThresholdChanged(threshold, newThreshold);

        threshold = newThreshold;
    }

    function setBNBPool(address newBNBPool) external virtual onlyOwner {
        emit BNBPoolChanged(address(bnbPool), newBNBPool);
        bnbPool = IBNBPool(newBNBPool);
    }

    function enableIntegratorLock(bool enable) external virtual onlyOwnerOrManager {
        integratorLockEnabled = enable;
        emit IntegratorLockEnabled(enable);
    }

    function enableProviderLock(bool enable) external virtual onlyOwnerOrManager {
        providerLockEnabled = enable;
        emit ProviderLockEnabled(enable);
    }

    function excludeFromFee(address value, bool exclude) external virtual onlyOwnerOrManager {
        excludedFromFee[value] = exclude;
        emit ExcludedFromFee(value, exclude);
    }

    function triggerRebalanceAnkr() external virtual nonReentrant onlyManager {
        skim();
        uint256 ratio = abnbc.ratio();
        uint256 amountAInNative = wbnbAmount;
        uint256 amountBInNative = (abnbcAmount * 1e18) / ratio;
        uint256 wholeAmount = amountAInNative + amountBInNative;
        bool isStake = amountAInNative > amountBInNative;
        if (!isStake) {
            uint256 temp = amountAInNative;
            amountAInNative = amountBInNative;
            amountBInNative = temp;
        }
        require(
            (amountBInNative * FEE_MAX) / wholeAmount < threshold,
            "the proportions are not less than threshold"
        );
        uint256 amount = (amountAInNative - amountBInNative) / 2;
        if (isStake) {
            wbnbAmount -= amount;
            wbnb.withdraw(amount);
            bnbPool.stakeAndClaimCerts{ value: amount }();

            emit PoolStake(amount);
        } else {
            uint256 _abnbcAmount = (amount * ratio) / 1e18;
            abnbcAmount -= _abnbcAmount;
            bnbPool.unstakeCerts(_abnbcAmount);

            emit PoolUnstake(_abnbcAmount);
        }
    }

    function approveToMaticPool() external virtual {
        TransferHelper.safeApprove(address(abnbc), address(bnbPool), type(uint256).max);
    }

    /*
        This method is used to account for assets on a contract. For example, if
        someone sends native BNB, it will be automatically added to the liquidity
        pool. This method also keeps wbnbAmount and abnbcAmount values synchornized
        with their actual balances.
    */
    function skim() public virtual {
        uint256 balance = address(this).balance;
        wbnbAmount = wbnb.balanceOf(address(this)) -
            ownerFeeCollected.nativeFee -
            managerFeeCollected.nativeFee +
            _claimedManagerFees.nativeFee;
        abnbcAmount = abnbc.balanceOf(address(this)) -
        ownerFeeCollected.abnbcFee -
        (managerFeeCollected.abnbcFee - _claimedManagerFees.abnbcFee);

        if (balance > 0) {
            wbnb.deposit{ value: balance }();
            wbnbAmount += balance;
            emit NativeBalanceChanged(wbnbAmount);
        }
    }

    function remove(address value, UserType utype) public virtual nonReentrant returns (bool) {
        require(value != address(0), "cannot remove address(0)");
        bool success = false;
        if (utype == UserType.MANAGER) {
            require(msg.sender == owner(), "Only owner can remove manager");
            if (managers_.contains(value)) {
                _withdrawManagerFee(value, false);
                delete managerRewardDebt[value];
                success = managers_.remove(value);
            }
        } else if (utype == UserType.LIQUIDITY_PROVIDER) {
            require(managers_.contains(msg.sender), "Only manager can remove liquidity provider");
            success = liquidityProviders_.remove(value);
        } else {
            require(managers_.contains(msg.sender), "Only manager can remove integrator");
            success = integrators_.remove(value);
        }
        if (success) {
            emit UserTypeChanged(value, utype, false);
        }
        return success;
    }

    function contains(address value, UserType utype) external view virtual returns (bool) {
        if (utype == UserType.MANAGER) {
            return managers_.contains(value);
        } else if (utype == UserType.LIQUIDITY_PROVIDER) {
            return liquidityProviders_.contains(value);
        } else {
            return integrators_.contains(value);
        }
    }

    function length(UserType utype) external view virtual returns (uint256) {
        if (utype == UserType.MANAGER) {
            return managers_.length();
        } else if (utype == UserType.LIQUIDITY_PROVIDER) {
            return liquidityProviders_.length();
        } else {
            return integrators_.length();
        }
    }

    function at(uint256 index, UserType utype) external view virtual returns (address) {
        if (utype == UserType.MANAGER) {
            return managers_.at(index);
        } else if (utype == UserType.LIQUIDITY_PROVIDER) {
            return liquidityProviders_.at(index);
        } else {
            return integrators_.at(index);
        }
    }

    function flashFee(address token, uint256 amount) public view returns (uint128) {
        if (uint128(amount) != amount) return 0;
        if (!(token == address(abnbc) || token == address(wbnb))) return 0;

        uint128 fee = uint128(amount) * flashLoanFee / 10000;

        if (fee < flashLoanFixedFee) {
            return flashLoanFixedFee;
        }

        return fee;
    }

    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external nonReentrant returns (bool) {
        require(flashLoanFee > 0 && flashLoanFixedFee > 0, "SwapPool: fees_not_set");
        require(token == address(abnbc) || token == address(wbnb), "SwapPool: token_unsupported");
        require(amount <= flashLoanMaxAmount, "SwapPool: ceiling_exceeded");

        uint128 fee = flashFee(token, amount);
        require(fee > 0, "SwapPool: wrong_fee");

        uint256 total = amount + fee;

        if (token == address(abnbc)) {
            ownerFeeCollected.abnbcFee += fee;
        }

        if (token == address(wbnb)) {
            ownerFeeCollected.nativeFee += fee;
        }

        emit FlashLoan(address(receiver), token, amount, fee);

        TransferHelper.safeTransfer(token, address(receiver), amount);
        require(receiver.onFlashLoan(msg.sender, token, amount, fee, data) == CALLBACK_SUCCESS, "Flash/callback-failed");
        TransferHelper.safeTransferFrom(token, address(receiver), address(this), total);

        return true;
    }

    receive() external payable virtual {}
}