// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {EnumerableSetUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import {ILP} from "./interfaces/ILP.sol";
import {IBNBPool} from "./interfaces/IBNBPool.sol";
import {IABNBC} from "./interfaces/IABNBC.sol";
import {IWBNB} from "./interfaces/IWBNB.sol";
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
        uint128 ankrbnbFee;
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
        uint256 nativeReserve,
        bool indexed added
    );
    event Swap(
        address indexed sender,
        address indexed receiver,
        uint256 amountIn,
        uint256 amountOut
    );
    event FlashLoan(address indexed receiver, address token, uint256 amount, uint256 fee);
    event FlashLoanMaxChanged(uint256 oldAmount, uint256 newAmount);
    event BNBPoolChanged(address oldPool, address newPool);
    event FeesWithdrawn(address receiver, uint128 nativeAmount, uint128 ankrbnbAmount);
    event FeesUpdated(FeeType ftype, uint128 nativeAmount, uint128 ankrbnbAmount);
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
    IABNBC public ankrbnb;
    ILP public lpToken;

    uint256 public wbnbAmount;
    uint256 public ankrbnbAmount;

    uint24 public ownerFee;
    uint24 public managerFee;
    uint24 public integratorFee;
    uint24 public stakeFee;
    uint24 public unstakeFee;
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

    modifier wrapNative() {
        _wrapNative();
        _;
    }

    function initialize(
        address _wbnb,
        address _ankrbnb,
        address _abnbb,
        address _lpToken,
        bool _integratorLockEnabled,
        bool _providerLockEnabled
    ) public initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        wbnb = IWBNB(_wbnb);
        ankrbnb = IABNBC(_ankrbnb);
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

    function _wrapNative() internal {
        uint256 _amount = address(this).balance;
        if (_amount > 0) {
            wbnb.deposit{value : _amount}();
            wbnbAmount += _amount;
        }
    }

    function _addLiquidity(uint256 _amount, bool _useEth) internal virtual {
        uint256 totalSupply = lpToken.totalSupply();
        require(totalSupply != 0 || _amount > 1e18, "cannot add first time less than 1 token");

        if (_useEth) {
            require(_amount <= msg.value, "bad native value");
            wbnb.deposit{value : _amount}();
            if (msg.value > _amount) {
                _sendValue(msg.sender, msg.value - _amount);
            }
        } else {
            TransferHelper.safeTransferFrom(address(wbnb), msg.sender, address(this), _amount);
        }

        uint256 _mintAmount;
        if (totalSupply == 0) {
            _mintAmount = _amount;
            wbnbAmount = _amount;
        } else {
            uint256 allInWBNB = this.getAllLiquidity();
            _mintAmount = _amount * totalSupply / allInWBNB;
            wbnbAmount += _amount;
        }

        lpToken.mint(msg.sender, _mintAmount);
        emit LiquidityChange(msg.sender, _amount, wbnbAmount, true);
        _wrapNative();
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
        require(percent > 0 && percent <= 1e18, "percent should be more than 0 and less than 1e18");
        // max percent(100%) is -> 10 ** 18
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

    function getAvailableLiquidity() public view returns (uint256){
        return wbnbAmount + address(this).balance;
    }

    function getAllLiquidity() public view returns (uint256){
        return this.getAvailableLiquidity() + this.getPendingLiquidity();
    }

    function getPendingLiquidity() public view returns (uint256){
        return bnbPool.pendingUnstakesOf(address(this)) + this.ankrbnbAmount();
    }

    function getAvailableLiquidityForProvider(address provider) public view returns (uint256){
        uint256 _liqAmount = lpToken.balanceOf(provider) * this.getAllLiquidity() / lpToken.totalSupply();
        uint256 _availLiqAmount = this.getAvailableLiquidity();
        if (_liqAmount >= _availLiqAmount) {
            return _availLiqAmount;
        }

        return _liqAmount;
    }

    function getPendingLiquidityForProvider(address provider) public view returns (uint256){
        uint256 _liqAmount = lpToken.balanceOf(provider) * this.getAllLiquidity() / lpToken.totalSupply();
        uint256 _availLiqAmount = this.getAvailableLiquidity();
        if (_liqAmount > _availLiqAmount) {
            return _availLiqAmount - _liqAmount;
        }
        return 0;
    }

    function _removeLiquidity(uint256 removedLp, bool useEth) wrapNative internal virtual {
        uint256 wbnbBalance = wbnbAmount;
        require(wbnbBalance > 0, "SwapPool: liquidity pool is empty");

        uint256 allLiq = wbnbBalance + this.getPendingLiquidity();
        uint256 lpSupply = lpToken.totalSupply();
        uint256 amount0Removed = removedLp * allLiq / lpSupply;
        require(amount0Removed <= wbnbBalance, "SwapPool: not enough liquidity");

        lpToken.burn(msg.sender, removedLp);
        if (useEth) {
            wbnb.transfer(address(bnbHandler), amount0Removed);
            bnbHandler.withdraw(address(wbnb), amount0Removed);
            _sendValue(msg.sender, amount0Removed);
        } else {
            TransferHelper.safeTransfer(address(wbnb), msg.sender, amount0Removed);
        }
        wbnbBalance -= amount0Removed;
        wbnbAmount = wbnbBalance;
        emit LiquidityChange(msg.sender, amount0Removed, wbnbBalance, false);
    }

    function swapEth(
        uint256 amountIn,
        address receiver
    ) external virtual onlyIntegrator nonReentrant returns (uint256 amountOut) {
        return _swap(amountIn, receiver, true);
    }

    function swap(
        uint256 amountIn,
        address receiver
    ) external virtual onlyIntegrator nonReentrant returns (uint256 amountOut) {
        return _swap(amountIn, receiver, false);
    }

    function _swap(
        uint256 amountIn,
        address receiver,
        bool useEth
    ) internal wrapNative virtual returns (uint256 amountOut) {
        TransferHelper.safeTransferFrom(address(ankrbnb), msg.sender, address(this), amountIn);
        uint256 _ankrbnbBalance = ankrbnbAmount;

        if (!excludedFromFee[msg.sender]) {
            uint256 unstakeFeeAmt = (amountIn * unstakeFee) / FEE_MAX;
            amountIn -= unstakeFeeAmt;
            uint256 managerFeeAmt = (unstakeFeeAmt * managerFee) / FEE_MAX;
            uint256 ownerFeeAmt = (unstakeFeeAmt * ownerFee) / FEE_MAX;
            uint256 integratorFeeAmt;
            if (integratorLockEnabled) {
                integratorFeeAmt = (unstakeFeeAmt * integratorFee) / FEE_MAX;
                if (integratorFeeAmt > 0) {
                    TransferHelper.safeTransfer(address(ankrbnb), msg.sender, integratorFeeAmt);
                }
            }
            _ankrbnbBalance += amountIn + (unstakeFeeAmt - managerFeeAmt - ownerFeeAmt - integratorFeeAmt);

            ownerFeeCollected.ankrbnbFee += uint128(ownerFeeAmt);
            managerFeeCollected.ankrbnbFee += uint128(managerFeeAmt);
        } else {
            _ankrbnbBalance += amountIn;
        }

        // calculate if there is enough liquidity wbnb+balance to make swap
        bool enoughLiquidity;
        (amountOut, enoughLiquidity) = _getAmountOut(amountIn, true, true);
        require(enoughLiquidity, "Not enough liquidity");

        if (useEth) {
            wbnb.transfer(address(bnbHandler), amountOut);
            bnbHandler.withdraw(address(wbnb), amountOut);
            _sendValue(receiver, amountOut);
        } else {
            TransferHelper.safeTransfer(address(wbnb), receiver, amountOut);
        }

        wbnbAmount -= amountOut;
        emit Swap(msg.sender, receiver, amountIn, amountOut);

        // unstake logic
        if (_ankrbnbBalance >= ankrbnb.bondsToShares(bnbPool.getMinimumStake())) {
            ankrbnb.approve(abnbb, _ankrbnbBalance);
            bnbPool.unstakeCerts(_ankrbnbBalance);
            ankrbnbAmount = 0;
        } else {
            ankrbnbAmount = _ankrbnbBalance;
        }
    }

    function getAmountOut(
        uint256 amountIn,
        bool isExcludedFromFee
    ) public view virtual returns (uint256 amountOut, bool enoughLiquidity) {
        return _getAmountOut(amountIn, isExcludedFromFee, false);
    }


    function _getAmountOut(
        uint256 amountIn,
        bool isExcludedFromFee,
        bool isSwap
    ) internal view returns (uint256 amountOut, bool enoughLiquidity) {
        if (!isExcludedFromFee) {
            uint256 unstakeFeeAmt = (amountIn * unstakeFee) / FEE_MAX;
            amountIn -= unstakeFeeAmt;
        }
        amountOut = ankrbnb.sharesToBonds(amountIn);
        if (isSwap) {
            enoughLiquidity = amountOut <= wbnbAmount;
        } else {
            enoughLiquidity = amountOut <= this.getAvailableLiquidity();
        }
    }

    function _sendValue(address receiver, uint256 amount) internal virtual {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success,) = payable(receiver).call{value : amount}("");
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
            amount1 = ownerFeeCollected.ankrbnbFee;
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
            ownerFeeCollected.ankrbnbFee -= amount1;
            TransferHelper.safeTransfer(address(ankrbnb), msg.sender, amount1);
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
            accFee.ankrbnbFee =
            _accFeePerManager.ankrbnbFee +
            (managerFeeCollected.ankrbnbFee - _alreadyUpdatedFees.ankrbnbFee) /
            uint128(managersLength);
            feeRewards.nativeFee = accFee.nativeFee - currentManagerRewardDebt.nativeFee;
            feeRewards.ankrbnbFee = accFee.ankrbnbFee - currentManagerRewardDebt.ankrbnbFee;
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
        feeRewards.ankrbnbFee = _accFeePerManager.ankrbnbFee - currentManagerRewardDebt.ankrbnbFee;
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
        if (feeRewards.ankrbnbFee > 0) {
            currentManagerRewardDebt.ankrbnbFee += feeRewards.ankrbnbFee;
            _claimedManagerFees.ankrbnbFee += feeRewards.ankrbnbFee;
            TransferHelper.safeTransfer(address(ankrbnb), managerAddress, feeRewards.ankrbnbFee);
        }

        emit FeesWithdrawn(managerAddress, feeRewards.nativeFee, feeRewards.ankrbnbFee);
    }

    function _updateManagerFees() internal virtual {
        uint256 managersLength = managers_.length();
        _accFeePerManager.nativeFee +=
        (managerFeeCollected.nativeFee - _alreadyUpdatedFees.nativeFee) /
        uint128(managersLength);
        _accFeePerManager.ankrbnbFee +=
        (managerFeeCollected.ankrbnbFee - _alreadyUpdatedFees.ankrbnbFee) /
        uint128(managersLength);
        _alreadyUpdatedFees.nativeFee = managerFeeCollected.nativeFee;
        _alreadyUpdatedFees.ankrbnbFee = managerFeeCollected.ankrbnbFee;

        emit FeesUpdated(FeeType.MANAGER, _alreadyUpdatedFees.nativeFee, _alreadyUpdatedFees.ankrbnbFee);
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
                    managerRewardDebt[value].ankrbnbFee = _accFeePerManager.ankrbnbFee;
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
        require(newFee <= FEE_MAX, "Unsupported size of fee!");
        if (feeType == FeeType.OWNER) {
            require(msg.sender == owner(), "only owner can call this function");
            require(newFee + managerFee + integratorFee <= FEE_MAX, "fee sum is more than 100%");
            emit FeeChanged(feeType, ownerFee, newFee);
            ownerFee = newFee;
        } else if (feeType == FeeType.MANAGER) {
            require(newFee + ownerFee + integratorFee <= FEE_MAX, "fee sum is more than 100%");
            emit FeeChanged(feeType, managerFee, newFee);
            managerFee = newFee;
        } else if (feeType == FeeType.INTEGRATOR) {
            require(newFee + ownerFee + managerFee <= FEE_MAX, "fee sum is more than 100%");
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

    function approveToBNBPool() external virtual {
        TransferHelper.safeApprove(address(ankrbnb), address(bnbPool), type(uint256).max);
    }

    /*
        This method is used to account for assets on a contract. For example, if
        someone sends native BNB, it will be automatically added to the liquidity
        pool. This method also keeps wbnbAmount and ankrbnbAmount values synchornized
        with their actual balances.
    */
    function skim() public virtual {
        uint256 balance = address(this).balance;
        wbnbAmount = wbnb.balanceOf(address(this)) -
        ownerFeeCollected.nativeFee -
        managerFeeCollected.nativeFee +
        _claimedManagerFees.nativeFee;
        ankrbnbAmount = ankrbnb.balanceOf(address(this)) -
        ownerFeeCollected.ankrbnbFee -
        (managerFeeCollected.ankrbnbFee - _claimedManagerFees.ankrbnbFee);

        if (balance > 0) {
            wbnb.deposit{value : balance}();
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
        if (token != address(wbnb)) return 0;

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
    ) external wrapNative nonReentrant returns (bool) {
        require(flashLoanFee > 0 && flashLoanFixedFee > 0, "SwapPool: fees_not_set");
        require(token == address(wbnb), "SwapPool: token_unsupported");
        require(amount <= flashLoanMaxAmount, "SwapPool: ceiling_exceeded");
        require(amount <= wbnbAmount);

        uint128 fee = flashFee(token, amount);
        require(fee > 0, "SwapPool: wrong_fee");

        uint256 total = amount + fee;
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