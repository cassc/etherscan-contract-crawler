// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { ERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { IBedRockCore } from "../interfaces/IBedRockCore.sol";
import "../libraries/BedRockLibrary.sol";
import "../libraries/Maths.sol";
import "../libraries/OptimizedBalanceManager.sol";
import { BedRockPool } from "../core/BedRockPool.sol";
import { IPriceProvider } from "../interfaces/IPriceProvider.sol";
import { IAssetSourcer } from "../interfaces/IAssetSourcer.sol";
import { MockPriceProvider } from "../mocks/MockPriceProvider.sol";

contract BedRockCore is IBedRockCore, ERC20, BedRockPool, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using OptimizedBalanceManager for BalanceStore;

    uint256 public safeCounter;

    mapping(address => SafeConfig) private safeConfigs;
    mapping(address => SafeState) private safeStates;
    mapping(uint256 => address) public safeArray;
    mapping(address => BalanceStore) private balanceStores;
    mapping(address => bool) private cacheUpdating;

    IAssetSourcer assetSourcer;
    address feeTo;

    mapping(uint256 => PendingAsset) public withdrawRequests;
    uint256 public withdrawCounter;
    uint256 public withdrawCounterFront = 1;

    mapping(uint256 => PendingAsset) public lockedAssets;
    uint256 public lockedCounter;
    uint256 public lockedCounterFront = 1;

    uint256 private _totalAsset;

    constructor(address _assetSourcer, address _feeTo) ERC20("BedRock Token", "BEDROCK") {
        safeConfigs[address(0)] = SafeConfig(
            0, // : expectPrice
            address(0), // : priceProvider
            96, // 96 hours : feeFreePeriod
            9000, // 0.9 : hackThreshold
            72, // 72 hours : claimLockPeriod
            0, // 0% : depositFeePercent
            500, // 5% : claimFeePercent
            5000, // 50% : poolSavingPercent
            0
        );
        assetSourcer = IAssetSourcer(_assetSourcer);
        assetSourcer.initialize();
        feeTo = _feeTo;
    }

    modifier activeSafe(address token) {
        require(isActive(token), "Inactive Safe");
        _;
    }

    function isActive(address token) public view returns (bool) {
        return safeStates[token].active;
    }

    function createSafe(
        address token,
        uint256 expectPrice,
        address priceProvider
    ) external onlyOwner {
        if (priceProvider == address(0)) {
            priceProvider = address(new MockPriceProvider());
        }
        SafeConfig memory safeConfig = safeConfigs[address(0)];
        safeConfig.expectPrice = expectPrice;
        safeConfig.priceProvider = priceProvider;
        IPriceProvider(priceProvider).setPrice(expectPrice);
        safeConfigs[token] = safeConfig;

        safeStates[token] = SafeState(true, 0);

        safeCounter++;
        safeArray[safeCounter] = token;

        emit SafeCreated(token, expectPrice, priceProvider);
    }

    function activateSafe(address token, bool flag) external onlyOwner {
        SafeState storage safeState = safeStates[token];
        safeState.active = flag;
        emit SafeActivated(token, flag);
    }

    function getSafeConfig(address token) external view returns (SafeConfig memory) {
        return safeConfigs[token];
    }

    function updateSafeConfig(address token, SafeConfig memory safeConfig) external onlyOwner {
        safeConfigs[token] = safeConfig;
    }

    function swap(uint256 amount) external {
        _swap(amount);
        _burn(msg.sender, amount);
    }

    function deposit(address token, uint256 amount) external activeSafe(token) {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        SafeConfig storage safeConfig = safeConfigs[token];

        uint256 fee = (amount * safeConfig.depositFeePercent) / DENOMINATOR;
        _mintSafe(token, msg.sender, amount - fee);
        _onDeposit(token, amount - fee);
        if (fee > 0) {
            uint256 poolSavingPercent = safeConfig.poolSavingPercent;
            uint256 saveFee = (fee * poolSavingPercent) / DENOMINATOR;
            if (fee - saveFee > 0) {
                IERC20(token).safeTransfer(feeTo, fee - saveFee);
            }
            if (saveFee > 0) {
                _save(token, saveFee);
            }
        }
        emit Deposited(token, msg.sender, amount - fee);
    }

    function requestWithdraw(
        address token,
        uint256 amount,
        uint256 delay
    ) external activeSafe(token) {
        _burnSafe(token, msg.sender, amount);
        _onWithdraw(token, amount);
        SafeConfig storage safeConfig = safeConfigs[token];

        uint256 feePercent = withdrawFeePercent(token, delay);
        uint256 fee = (amount * feePercent) / DENOMINATOR;
        if (amount - fee > 0) {
            uint256 proceedTime = block.timestamp + 60 * delay;
            uint256 id = _createWithdrawRequest(token, msg.sender, amount - fee, proceedTime);
            emit WithdrawRequested(id, token, msg.sender, amount, amount - fee, delay);
        }
        if (fee > 0) {
            uint256 poolSavingPercent = safeConfig.poolSavingPercent;
            uint256 saveFee = (fee * poolSavingPercent) / DENOMINATOR;
            if (fee - saveFee > 0) {
                IERC20(token).safeTransfer(feeTo, fee - saveFee);
            }
            if (saveFee > 0) {
                _save(token, saveFee);
            }
        }
    }

    function requestClaim(address token, uint256 amount) external activeSafe(token) {
        bool hacked = isTokenHacked(token);
        require(hacked, "The stablecoin is not hacked");
        SafeConfig storage safeConfig = safeConfigs[token];
        uint256 lockAmount = (claimLockPercent(token) * amount) / DENOMINATOR;
        _onWithdraw(token, amount);
        _burnSafe(token, msg.sender, amount + lockAmount);
        uint256 unlockTime = block.timestamp + 3600 * safeConfig.claimLockPeriod;
        uint256 id = _createLockedAsset(token, msg.sender, lockAmount, unlockTime);
        emit AssetLocked(id, token, msg.sender, amount, lockAmount, unlockTime);

        uint256 claimFee = (amount * safeConfig.claimFeePercent) / DENOMINATOR;
        uint256 amountToProceed = _convertToUSD(amount - claimFee, token);
        uint256 saveAmount = (amount - claimFee) + ((claimFee * safeConfig.poolSavingPercent) / DENOMINATOR);

        _save(token, saveAmount);

        uint256 claimPercent = Maths.normalizeFraction(
            amountToProceed,
            _totalAsset - _convertToUSD(safeTotalSupply(token), token)
        );

        uint256 totalPaid = 0;
        for (uint256 i = 1; i <= safeCounter; i++) {
            if (safeArray[i] != token && safeStates[safeArray[i]].active) {
                uint256 paidAmount = _payout(token, safeArray[i], claimPercent);
                totalPaid += paidAmount;
            }
        }
        emit ClaimProceeded(token, msg.sender, amount, totalPaid);
    }

    function withdrawProceed(uint256 id) external {
        PendingAsset storage request = withdrawRequests[id];
        require(request.amount > 0, "No such request");
        require(request.releaseTime <= block.timestamp, "It is in locking period");
        _releaseWithdrawRequest(id);
    }

    function releaseLockedAsset(uint256 id) external {
        PendingAsset storage request = lockedAssets[id];
        require(request.amount > 0, "No such pending asset");
        require(request.releaseTime <= block.timestamp, "It is in locking period");
        _releaseLockedAsset(id);
    }

    function checkAllRelease() external {
        while (withdrawCounterFront <= withdrawCounter) {
            PendingAsset storage request = withdrawRequests[withdrawCounterFront];
            if (request.releaseTime > block.timestamp) {
                break;
            }
            withdrawCounterFront++;
            if (request.amount > 0) {
                _releaseWithdrawRequest(withdrawCounterFront - 1);
            }
        }
        while (lockedCounterFront <= lockedCounter) {
            PendingAsset storage request = lockedAssets[lockedCounterFront];
            if (request.releaseTime > block.timestamp) {
                break;
            }
            lockedCounterFront++;
            if (request.amount > 0) {
                _releaseLockedAsset(lockedCounterFront - 1);
            }
        }
    }

    function withdrawFeePercent(address token, uint256 delay) public view returns (uint256) {
        uint256 feeFreePeriod = safeConfigs[token].feeFreePeriod * 60;
        if (delay >= feeFreePeriod) return 0;
        return (DENOMINATOR * (feeFreePeriod - delay) * (feeFreePeriod - delay)) / (feeFreePeriod * feeFreePeriod);
    }

    function claimLockPercent(address token) public view returns (uint256) {
        uint256 hackedAmount = _convertToUSD(safeTotalSupply(token), token);
        uint256 unhackedAmount = _totalAsset - hackedAmount;
        if (hackedAmount > (unhackedAmount * MAX_PERCENT) / DENOMINATOR) return MAX_PERCENT;
        if (hackedAmount == 0) return 0;
        return (hackedAmount * DENOMINATOR) / unhackedAmount;
    }

    function safeBalanceOf(address token, address user) external view returns (uint256) {
        return balanceStores[token].getBalance(user);
    }

    function safeTotalSupply(address token) public view returns (uint256) {
        return balanceStores[token].totalSupply();
    }

    function isTokenHacked(address token) public view returns (bool) {
        SafeConfig storage safeConfig = safeConfigs[token];
        uint256 price = IPriceProvider(safeConfig.priceProvider).getPrice();
        return price <= (safeConfig.expectPrice * safeConfig.hackThreshold) / DENOMINATOR;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        uint256 ts = super.totalSupply();
        for (uint256 i = 1; i <= safeCounter; i++) {
            if (!safeStates[safeArray[i]].active) continue;
            BalanceStore storage store = balanceStores[safeArray[i]];
            ts += _convertToUSD(store.getTotalCacheReward(), safeArray[i]);
        }
        return ts;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        uint256 balance = super.balanceOf(account);
        for (uint256 i = 1; i <= safeCounter; i++) {
            if (!safeStates[safeArray[i]].active) continue;
            BalanceStore storage store = balanceStores[safeArray[i]];
            balance += _convertToUSD(store.getCacheReward(account), safeArray[i]);
        }
        return balance;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256
    ) internal override {
        if (from != address(0) && !cacheUpdating[from]) {
            _updateCacheReward(from);
        }
        if (to != address(0) && !cacheUpdating[to]) {
            _updateCacheReward(to);
        }
    }

    function _onDeposit(address token, uint256 amount) private {
        IERC20(token).safeApprove(address(assetSourcer), amount);
        assetSourcer.onDeposit(token, amount);
    }

    function _onWithdraw(address token, uint256 amount) private {
        assetSourcer.onWithdraw(token, amount);
    }

    function _updateCacheReward(address account) private {
        cacheUpdating[account] = true;
        for (uint256 i = 1; i <= safeCounter; i++) {
            if (!safeStates[safeArray[i]].active) continue;
            BalanceStore storage store = balanceStores[safeArray[i]];
            uint256 cacheReward = store.releaseCacheReward(account);
            if (cacheReward > 0) _mint(account, _convertToUSD(cacheReward, safeArray[i]));
        }
        cacheUpdating[account] = false;
    }

    function _payout(
        address token,
        address tokenForPay,
        uint256 claimPercent
    ) private returns (uint256) {
        BalanceStore storage store = balanceStores[tokenForPay];
        uint256 oldTotalSupply = store.totalSupply();
        store.multiplyAll(INTERNAL_DENOMINATOR - claimPercent);
        uint256 newTotalSupply = store.totalSupply();
        uint256 payAmount = oldTotalSupply - newTotalSupply;
        uint256 payAmountInUSD = _convertToUSD(payAmount, tokenForPay);
        _totalAsset -= payAmountInUSD;
        _onWithdraw(tokenForPay, payAmount);
        IERC20(tokenForPay).safeTransfer(msg.sender, payAmount);
        emit Paid(token, tokenForPay, msg.sender, payAmount);
        return payAmountInUSD;
    }

    function _mintSafe(
        address token,
        address user,
        uint256 amount
    ) private {
        BalanceStore storage store = balanceStores[token];
        store.mint(user, amount);
        uint256 amountInUSD = _convertToUSD(amount, token);
        _totalAsset += amountInUSD;
    }

    function _burnSafe(
        address token,
        address user,
        uint256 amount
    ) private {
        BalanceStore storage store = balanceStores[token];
        store.burn(user, amount);
        uint256 amountInUSD = _convertToUSD(amount, token);
        _totalAsset -= amountInUSD;
    }

    function _createWithdrawRequest(
        address token,
        address user,
        uint256 amount,
        uint256 releaseTime
    ) private returns (uint256) {
        withdrawCounter++;
        uint256 id = withdrawCounter;
        withdrawRequests[id] = PendingAsset(token, user, amount, releaseTime);
        return id;
    }

    function _releaseWithdrawRequest(uint256 id) private {
        address token = withdrawRequests[id].token;
        address user = withdrawRequests[id].user;
        uint256 amount = withdrawRequests[id].amount;
        delete withdrawRequests[id];
        IERC20(token).safeTransfer(user, amount);
        emit WithdrawProceeded(id);
    }

    function _createLockedAsset(
        address token,
        address user,
        uint256 amount,
        uint256 releaseTime
    ) private returns (uint256) {
        lockedCounter++;
        uint256 id = lockedCounter;
        lockedAssets[id] = PendingAsset(token, user, amount, releaseTime);
        return id;
    }

    function _releaseLockedAsset(uint256 id) private {
        address token = lockedAssets[id].token;
        address user = lockedAssets[id].user;
        uint256 amount = lockedAssets[id].amount;
        delete lockedAssets[id];
        _mintSafe(token, user, amount);
        emit LockedAssetReleased(id);
    }

    function _convertToUSD(uint256 amount, address token) private view returns (uint256) {
        return (amount * (10**STANDARD_DECIMALS)) / safeConfigs[token].expectPrice;
    }
}