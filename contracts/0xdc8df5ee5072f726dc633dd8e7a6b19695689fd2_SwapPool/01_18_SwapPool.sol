// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {EnumerableSetUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import {ILP} from "./interfaces/ILP.sol";
import {IETHPool} from "./interfaces/IETHPool.sol";
import {IAETHC} from "./interfaces/IAETHC.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import "./interfaces/IERC3156FlashBorrower.sol";
import "./util/TransferHelper.sol";
import "./interfaces/IETHHandler.sol";
import "./ETHHandler.sol";
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
        uint128 ankrethFee;
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
    event EthPoolChanged(address oldPool, address newPool);
    event FeesWithdrawn(address receiver, uint128 nativeAmount, uint128 ankrethAmount);
    event FeesUpdated(FeeType ftype, uint128 nativeAmount, uint128 ankrethAmount);
    event ThresholdChanged(uint24 oldValue, uint24 newValue);
    event PoolStake(uint256 amount);
    event PoolUnstake(uint256 amount);
    event NativeBalanceChanged(uint256 amount);
    event NativeReceived(uint256 amount, address sender);
    event MinUnstakeAmountUpdated(uint256 oldAmount, uint256 newAmount);

    uint24 public constant FEE_MAX = 10000;

    EnumerableSetUpgradeable.AddressSet internal managers_;
    EnumerableSetUpgradeable.AddressSet internal integrators_;
    EnumerableSetUpgradeable.AddressSet internal liquidityProviders_;

    IWETH public weth;
    IAETHC public ankreth;
    ILP public lpToken;

    uint256 public wethAmount;
    uint256 public ankrethAmount;

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
    uint256 public minUnstakeAmount;

    mapping(address => FeeAmounts) public managerRewardDebt;
    mapping(address => bool) public excludedFromFee;

    IETHPool public ethPool;

    bytes32 public constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

    IETHHandler public ethHandler;

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
        address _weth,
        address _ankreth,
        address _lpToken,
        bool _integratorLockEnabled,
        bool _providerLockEnabled
    ) public initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        weth = IWETH(_weth);
        ankreth = IAETHC(_ankreth);
        lpToken = ILP(_lpToken);
        ethHandler = new ETHHandler();

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
            weth.deposit{value : _amount}();
            wethAmount += _amount;
        }
    }

    function _addLiquidity(uint256 _amount, bool _useEth) internal virtual {
        uint256 totalSupply = lpToken.totalSupply();
        require(totalSupply != 0 || _amount > 1e18, "cannot add first time less than 1 token");

        if (_useEth) {
            require(_amount <= msg.value, "bad native value");
            weth.deposit{value : _amount}();
            if (msg.value > _amount) {
                _sendValue(msg.sender, msg.value - _amount);
            }
        } else {
            TransferHelper.safeTransferFrom(address(weth), msg.sender, address(this), _amount);
        }

        uint256 _mintAmount;
        if (totalSupply == 0) {
            _mintAmount = _amount;
            wethAmount = _amount;
        } else {
            uint256 allInweth = this.getAllLiquidity();
            _mintAmount = _amount * totalSupply / allInweth;
            wethAmount += _amount;
        }

        lpToken.mint(msg.sender, _mintAmount);
        emit LiquidityChange(msg.sender, _amount, wethAmount, true);
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
        return wethAmount + address(this).balance;
    }

    function getAllLiquidity() public view returns (uint256){
        return this.getAvailableLiquidity() + this.getPendingLiquidity();
    }

    function getPendingLiquidity() public view returns (uint256){
        return ethPool.getPendingUnstakesOf(address(this)) + this.ankrethAmount();
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
        uint256 wethBalance = wethAmount;
        require(wethBalance > 0, "SwapPool: liquidity pool is empty");

        uint256 allLiq = wethBalance + this.getPendingLiquidity();
        uint256 lpSupply = lpToken.totalSupply();
        uint256 amount0Removed = removedLp * allLiq / lpSupply;
        require(amount0Removed <= wethBalance, "SwapPool: not enough liquidity");

        lpToken.burn(msg.sender, removedLp);
        if (useEth) {
            weth.transfer(address(ethHandler), amount0Removed);
            ethHandler.withdraw(address(weth), amount0Removed);
            _sendValue(msg.sender, amount0Removed);
        } else {
            TransferHelper.safeTransfer(address(weth), msg.sender, amount0Removed);
        }
        wethBalance -= amount0Removed;
        wethAmount = wethBalance;
        emit LiquidityChange(msg.sender, amount0Removed, wethBalance, false);
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
        TransferHelper.safeTransferFrom(address(ankreth), msg.sender, address(this), amountIn);
        uint256 _ankrethBalance = ankrethAmount;

        if (!excludedFromFee[msg.sender]) {
            uint256 unstakeFeeAmt = (amountIn * unstakeFee) / FEE_MAX;
            amountIn -= unstakeFeeAmt;
            uint256 managerFeeAmt = (unstakeFeeAmt * managerFee) / FEE_MAX;
            uint256 ownerFeeAmt = (unstakeFeeAmt * ownerFee) / FEE_MAX;
            uint256 integratorFeeAmt;
            if (integratorLockEnabled) {
                integratorFeeAmt = (unstakeFeeAmt * integratorFee) / FEE_MAX;
                if (integratorFeeAmt > 0) {
                    TransferHelper.safeTransfer(address(ankreth), msg.sender, integratorFeeAmt);
                }
            }
            _ankrethBalance += amountIn + (unstakeFeeAmt - managerFeeAmt - ownerFeeAmt - integratorFeeAmt);

            ownerFeeCollected.ankrethFee += uint128(ownerFeeAmt);
            managerFeeCollected.ankrethFee += uint128(managerFeeAmt);
        } else {
            _ankrethBalance += amountIn;
        }

        // calculate if there is enough liquidity weth+balance to make swap
        bool enoughLiquidity;
        (amountOut, enoughLiquidity) = _getAmountOut(amountIn, true, true);
        require(enoughLiquidity, "Not enough liquidity");

        if (useEth) {
            weth.transfer(address(ethHandler), amountOut);
            ethHandler.withdraw(address(weth), amountOut);
            _sendValue(receiver, amountOut);
        } else {
            TransferHelper.safeTransfer(address(weth), receiver, amountOut);
        }

        wethAmount -= amountOut;
        emit Swap(msg.sender, receiver, amountIn, amountOut);

        // unstake logic
        if (_ankrethBalance >= minUnstakeAmount) {
            ethPool.unstakeAETH(_ankrethBalance);
            ankrethAmount = 0;
        } else {
            ankrethAmount = _ankrethBalance;
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
        amountOut = ankreth.sharesToBonds(amountIn);
        if (isSwap) {
            enoughLiquidity = amountOut <= wethAmount;
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
            amount1 = ownerFeeCollected.ankrethFee;
        } else {
            amount1 = uint128(amount1Raw);
        }
        if (amount0 > 0) {
            ownerFeeCollected.nativeFee -= amount0;
            if (useEth) {
                weth.withdraw(amount0);
                _sendValue(msg.sender, amount0);
            } else {
                TransferHelper.safeTransfer(address(weth), msg.sender, amount0);
            }
        }
        if (amount1 > 0) {
            ownerFeeCollected.ankrethFee -= amount1;
            TransferHelper.safeTransfer(address(ankreth), msg.sender, amount1);
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
            accFee.ankrethFee =
            _accFeePerManager.ankrethFee +
            (managerFeeCollected.ankrethFee - _alreadyUpdatedFees.ankrethFee) /
            uint128(managersLength);
            feeRewards.nativeFee = accFee.nativeFee - currentManagerRewardDebt.nativeFee;
            feeRewards.ankrethFee = accFee.ankrethFee - currentManagerRewardDebt.ankrethFee;
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
        feeRewards.ankrethFee = _accFeePerManager.ankrethFee - currentManagerRewardDebt.ankrethFee;
        if (feeRewards.nativeFee > 0) {
            currentManagerRewardDebt.nativeFee += feeRewards.nativeFee;
            _claimedManagerFees.nativeFee += feeRewards.nativeFee;
            if (useNative) {
                weth.withdraw(feeRewards.nativeFee);
                _sendValue(managerAddress, feeRewards.nativeFee);
            } else {
                TransferHelper.safeTransfer(address(weth), managerAddress, feeRewards.nativeFee);
            }
        }
        if (feeRewards.ankrethFee > 0) {
            currentManagerRewardDebt.ankrethFee += feeRewards.ankrethFee;
            _claimedManagerFees.ankrethFee += feeRewards.ankrethFee;
            TransferHelper.safeTransfer(address(ankreth), managerAddress, feeRewards.ankrethFee);
        }

        emit FeesWithdrawn(managerAddress, feeRewards.nativeFee, feeRewards.ankrethFee);
    }

    function _updateManagerFees() internal virtual {
        uint256 managersLength = managers_.length();
        _accFeePerManager.nativeFee +=
        (managerFeeCollected.nativeFee - _alreadyUpdatedFees.nativeFee) /
        uint128(managersLength);
        _accFeePerManager.ankrethFee +=
        (managerFeeCollected.ankrethFee - _alreadyUpdatedFees.ankrethFee) /
        uint128(managersLength);
        _alreadyUpdatedFees.nativeFee = managerFeeCollected.nativeFee;
        _alreadyUpdatedFees.ankrethFee = managerFeeCollected.ankrethFee;

        emit FeesUpdated(FeeType.MANAGER, _alreadyUpdatedFees.nativeFee, _alreadyUpdatedFees.ankrethFee);
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
                    managerRewardDebt[value].ankrethFee = _accFeePerManager.ankrethFee;
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

    function setETHPool(address newETHPool) external virtual onlyOwner {
        emit EthPoolChanged(address(ethPool), newETHPool);
        ethPool = IETHPool(newETHPool);
    }


    function setMinUnstakeAmount(uint256 amount) external virtual onlyOwner {
        emit MinUnstakeAmountUpdated(minUnstakeAmount, amount);
        minUnstakeAmount = amount;
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

    /*
        This method is used to account for assets on a contract. For example, if
        someone sends native BNB, it will be automatically added to the liquidity
        pool. This method also keeps wethAmount and ankrethAmount values synchornized
        with their actual balances.
    */
    function skim() public virtual {
        uint256 balance = address(this).balance;
        wethAmount = weth.balanceOf(address(this)) -
        ownerFeeCollected.nativeFee -
        managerFeeCollected.nativeFee +
        _claimedManagerFees.nativeFee;
        ankrethAmount = ankreth.balanceOf(address(this)) -
        ownerFeeCollected.ankrethFee -
        (managerFeeCollected.ankrethFee - _claimedManagerFees.ankrethFee);

        if (balance > 0) {
            weth.deposit{value : balance}();
            wethAmount += balance;
            emit NativeBalanceChanged(wethAmount);
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
        if (token != address(weth)) return 0;

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
        require(token == address(weth), "SwapPool: token_unsupported");
        require(amount <= flashLoanMaxAmount, "SwapPool: ceiling_exceeded");
        require(amount <= wethAmount);

        uint128 fee = flashFee(token, amount);
        require(fee > 0, "SwapPool: wrong_fee");

        uint256 total = amount + fee;
        if (token == address(weth)) {
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