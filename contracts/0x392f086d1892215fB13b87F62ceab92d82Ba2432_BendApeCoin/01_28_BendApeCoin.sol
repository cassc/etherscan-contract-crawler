// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;
import {ERC4626Upgradeable, IERC4626Upgradeable, IERC20MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import {IERC20Upgradeable, SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {MathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

import {IApeCoinStaking} from "./interfaces/IApeCoinStaking.sol";
import {IStakeManager} from "./interfaces/IStakeManager.sol";
import {IBendApeCoin} from "./interfaces/IBendApeCoin.sol";
import {IStakeProxy} from "./interfaces/IStakeProxy.sol";

contract BendApeCoin is ERC4626Upgradeable, IBendApeCoin, OwnableUpgradeable {
    using MathUpgradeable for uint256;
    uint256 public constant APE_COIN_POOL_ID = 0;
    uint256 private constant APE_COIN_PRECISION = 1e18;
    uint256 private constant MIN_DEPOSIT = 1 * APE_COIN_PRECISION;
    uint256 private constant MAX_FEE = 1000;
    uint256 private constant PERCENTAGE_FACTOR = 1e4;

    IApeCoinStaking public apeStaking;
    IStakeManager public stakeManager;

    address public feeRecipient;
    uint256 public fee;

    uint256 public minCompoundAmount;
    uint256 public minCompoundInterval;

    uint256 public pendingDepositAmount;

    uint256 public lastDepositTime;
    uint256 public lastClaimTime;

    function initialize(
        IApeCoinStaking apeStaking_,
        IERC20MetadataUpgradeable apeCoin_,
        IStakeManager stakeManager_
    ) external initializer {
        __Ownable_init();
        __ERC20_init("BendDAO Staked ApeCoin", "bstAPE");
        __ERC4626_init(apeCoin_);
        apeStaking = apeStaking_;
        stakeManager = stakeManager_;
        apeCoin_.approve(address(apeStaking_), type(uint256).max);
        minCompoundAmount = MIN_DEPOSIT;
    }

    function updateMinCompoundAmount(uint256 minAmount) external override onlyOwner {
        minCompoundAmount = minAmount;
    }

    function updateMinCompoundInterval(uint256 minInteval) external override onlyOwner {
        minCompoundInterval = minInteval;
    }

    function updateFeeRecipient(address feeRecipient_) external override onlyOwner {
        require(feeRecipient_ != address(0), "BendApeCoin: fee recipient can't be zero address");
        feeRecipient = feeRecipient_;
    }

    function updateFee(uint256 fee_) external override onlyOwner {
        require(fee_ <= MAX_FEE, "BendApeCoin: fee overflow");
        fee = fee_;
    }

    function totalAssets() public view override(ERC4626Upgradeable, IERC4626Upgradeable) returns (uint256) {
        uint256 stakedAmount = apeStaking.addressPosition(address(this)).stakedAmount;
        uint256 pendingRewardsAmount = _pendingRewards();
        return stakedAmount + pendingRewardsAmount + pendingDepositAmount;
    }

    function _pendingRewards() internal view returns (uint256) {
        uint256 pendingRewardsAmount = apeStaking.pendingRewards(APE_COIN_POOL_ID, address(this), 0);
        uint256 feeAmount = pendingRewardsAmount.mulDiv(fee, PERCENTAGE_FACTOR, MathUpgradeable.Rounding.Down);
        return pendingRewardsAmount - feeAmount;
    }

    function _deposit(
        address caller,
        address receiver,
        uint256 assets,
        uint256 shares
    ) internal override(ERC4626Upgradeable) {
        // transfer ape coin from caller
        super._deposit(caller, receiver, assets, shares);
        // increase pending amount
        pendingDepositAmount += assets;

        if (_pendingRewards() >= minCompoundAmount && block.timestamp >= lastClaimTime + minCompoundInterval) {
            _claimApeCoin();
        }

        if (pendingDepositAmount >= minCompoundAmount && block.timestamp >= lastDepositTime + minCompoundInterval) {
            _depositApeCoin();
        }
    }

    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal override(ERC4626Upgradeable) {
        if (pendingDepositAmount < assets) {
            _claimApeCoin();
        }
        if (pendingDepositAmount < assets) {
            _withdrawApeCoin(assets - pendingDepositAmount);
        }

        // transfer ape coin to receiver
        super._withdraw(caller, receiver, owner, assets, shares);
        // decrease pending amount
        pendingDepositAmount -= assets;

        if (pendingDepositAmount >= minCompoundAmount && block.timestamp >= lastDepositTime + minCompoundInterval) {
            _depositApeCoin();
        }
    }

    function _depositApeCoin() internal {
        if (pendingDepositAmount > 0) {
            apeStaking.depositSelfApeCoin(pendingDepositAmount);
            // clear pending amount
            pendingDepositAmount = 0;
            lastDepositTime = block.timestamp;
        }
    }

    function _withdrawApeCoin(uint256 amount) internal {
        IERC20Upgradeable _asset = IERC20Upgradeable(asset());
        uint256 prebalance = _asset.balanceOf(address(this));
        apeStaking.withdrawSelfApeCoin(amount);
        uint256 withdrawnAmount = _asset.balanceOf(address(this)) - prebalance;
        // withdraw ape coin from ape staking, increase pending amount
        pendingDepositAmount += withdrawnAmount;
    }

    function _claimApeCoin() internal {
        uint256 rewardAmount = apeStaking.pendingRewards(APE_COIN_POOL_ID, address(this), 0);
        if (rewardAmount > 0) {
            IERC20Upgradeable _asset = IERC20Upgradeable(asset());
            uint256 preBalance = _asset.balanceOf(address(this));
            apeStaking.claimSelfApeCoin();
            rewardAmount = _asset.balanceOf(address(this)) - preBalance;
            uint256 feeAmount = rewardAmount.mulDiv(fee, PERCENTAGE_FACTOR, MathUpgradeable.Rounding.Down);
            if (feeAmount > 0 && feeRecipient != address(0)) {
                SafeERC20Upgradeable.safeTransfer(_asset, feeRecipient, feeAmount);
                rewardAmount -= feeAmount;
            }
            // claim ape coin from ape staking, increase pending amount
            pendingDepositAmount += rewardAmount;
            lastClaimTime = block.timestamp;
        }
    }

    function compound() external override {
        _claimApeCoin();
        _depositApeCoin();
    }

    function claimAndDeposit(address[] calldata proxies) external returns (uint256) {
        return _claimAndDepositFor(proxies, msg.sender);
    }

    function _claimAndDepositFor(address[] calldata proxies, address staker) internal returns (uint256 shares) {
        IERC20Upgradeable apeCoin = IERC20Upgradeable(asset());
        uint256 balanceBefore = apeCoin.balanceOf(staker);
        for (uint256 i = 0; i < proxies.length; i++) {
            stakeManager.claimFor(IStakeProxy(proxies[i]), staker);
        }
        uint256 rewards = apeCoin.balanceOf(staker) - balanceBefore;
        if (rewards > 0) {
            require(rewards <= maxDeposit(staker), "ERC4626: deposit more than max");
            shares = previewDeposit(rewards);
            _deposit(staker, staker, rewards, shares);
        }
    }

    function assetBalanceOf(address account) external view override returns (uint256) {
        return convertToAssets(balanceOf(account));
    }

    function deposit(uint256, address) public pure override(ERC4626Upgradeable, IERC4626Upgradeable) returns (uint256) {
        revert("BendApeCoin: not supported");
    }

    function mint(uint256, address) public pure override(ERC4626Upgradeable, IERC4626Upgradeable) returns (uint256) {
        revert("BendApeCoin: not supported");
    }
}