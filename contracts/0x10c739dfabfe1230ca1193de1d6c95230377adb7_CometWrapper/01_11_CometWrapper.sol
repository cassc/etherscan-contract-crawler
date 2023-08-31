// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC4626} from "solmate/mixins/ERC4626.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {CometInterface, TotalsBasic} from "./vendor/CometInterface.sol";
import {CometHelpers} from "./CometHelpers.sol";
import {ICometRewards} from "./vendor/ICometRewards.sol";

/// @notice A vault contract that accepts deposits of a Comet token like cUSDCv3 as an asset
/// and mints shares which are the Wrapped Comet token.
contract CometWrapper is ERC4626, CometHelpers {
    using SafeTransferLib for ERC20;

    struct UserBasic {
        uint64 baseTrackingAccrued;
        uint64 baseTrackingIndex;
    }

    mapping(address => UserBasic) public userBasic;
    mapping(address => uint256) public rewardsClaimed;

    CometInterface public immutable comet;
    ICometRewards public immutable cometRewards;
    uint256 public immutable trackingIndexScale;
    uint256 internal immutable accrualDescaleFactor;

    constructor(ERC20 _asset, ICometRewards _cometRewards, string memory _name, string memory _symbol)
        ERC4626(_asset, _name, _symbol)
    {
        if (address(_cometRewards) == address(0)) revert ZeroAddress();
        // minimal validation that contract is CometRewards
        _cometRewards.rewardConfig(address(_asset));

        comet = CometInterface(address(_asset));
        cometRewards = _cometRewards;
        trackingIndexScale = comet.trackingIndexScale();
        accrualDescaleFactor = uint64(10 ** asset.decimals()) / BASE_ACCRUAL_SCALE;
    }

    /// @notice Returns total assets managed by the vault
    /// @return total assets
    function totalAssets() public view override returns (uint256) {
        uint64 baseSupplyIndex_ = accruedSupplyIndex();
        uint256 supply = totalSupply;
        return supply > 0 ? presentValueSupply(baseSupplyIndex_, supply) : 0;
    }

    /// @notice Deposits assets into the vault and gets shares (Wrapped Comet token) in return
    /// @param assets The amount of assets to be deposited by the caller
    /// @param receiver The recipient address of the minted shares
    /// @return shares The amount of shares that are minted to the receiver
    function deposit(uint256 assets, address receiver) public override returns (uint256 shares) {
        if (assets == 0) revert ZeroAssets();

        accrueInternal(receiver);
        int104 prevPrincipal = comet.userBasic(address(this)).principal;
        asset.safeTransferFrom(msg.sender, address(this), assets);
        shares = unsigned256(comet.userBasic(address(this)).principal - prevPrincipal);
        if (shares == 0) revert ZeroShares();
        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /// @notice Mints shares (Wrapped Comet) in exchange for Comet tokens
    /// @param shares The amount of shares to be minted for the receive
    /// @param receiver The recipient address of the minted shares
    /// @return assets The amount of assets that are deposited by the caller
    function mint(uint256 shares, address receiver) public override returns (uint256 assets) {
        if (shares == 0) revert ZeroShares();
        assets = convertToAssets(shares);
        if (assets == 0) revert ZeroAssets();

        accrueInternal(receiver);
        int104 prevPrincipal = comet.userBasic(address(this)).principal;
        asset.safeTransferFrom(msg.sender, address(this), assets);
        shares =  unsigned256(comet.userBasic(address(this)).principal - prevPrincipal);
        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /// @notice Withdraws assets (Comet) from the vault and burns corresponding shares (Wrapped Comet).
    /// Caller can only withdraw assets from owner if they have been given allowance to.
    /// @param assets The amount of assets to be withdrawn by the caller
    /// @param receiver The recipient address of the withdrawn assets
    /// @param owner The owner of the assets to be withdrawn
    /// @return shares The amount of shares of the owner that are burned
    function withdraw(uint256 assets, address receiver, address owner) public override returns (uint256 shares) {
        if (assets == 0) revert ZeroAssets();
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender];

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        accrueInternal(owner);
        int104 prevPrincipal = comet.userBasic(address(this)).principal;
        asset.safeTransfer(receiver, assets);
        shares =  unsigned256(prevPrincipal - comet.userBasic(address(this)).principal);
        if (shares == 0) revert ZeroShares();
        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    /// @notice Redeems shares (Wrapped Comet) in exchange for assets (Wrapped Comet).
    /// Caller can only withdraw assets from owner if they have been given allowance to.
    /// @param shares The amount of shares to be redeemed
    /// @param receiver The recipient address of the withdrawn assets
    /// @param owner The owner of the shares to be redeemed
    /// @return assets The amount of assets that is withdrawn and sent to the receiver
    function redeem(uint256 shares, address receiver, address owner) public override returns (uint256 assets) {
        if (shares == 0) revert ZeroShares();
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }
        // Asset transfers in Comet may lead to decrease of this contract's principal/shares by 1 more than the 
        // `shares` argument. Taking into account this quirk in Comet's transfer logic, we always decrease `shares`
        // by 1 before converting to assets and doing the transfer. We then proceed to burn the actual `shares` amount
        // that was decreased during the Comet transfer. 
        // In this way, any rounding error would be in favor of CometWrapper and CometWrapper will be protected
        // from insolvency due to lack of assets that can be withdrawn by users.
        assets = convertToAssets(shares-1);
        if (assets == 0) revert ZeroAssets();

        accrueInternal(owner);
        int104 prevPrincipal = comet.userBasic(address(this)).principal;
        asset.safeTransfer(receiver, assets);
        shares =  unsigned256(prevPrincipal - comet.userBasic(address(this)).principal);
        if (shares == 0) revert ZeroShares();
        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    /// @notice Transfer shares from caller to the recipient
    /// @param to The receiver of the shares (Wrapped Comet) to be transferred
    /// @param amount The amount of shares to be transferred
    /// @return bool Indicates success of the transfer
    function transfer(address to, uint256 amount) public override returns (bool) {
        transferInternal(msg.sender, to, amount);
        return true;
    }

    /// @notice Transfer shares from a specified source to a recipient
    /// @param from The source of the shares to be transferred
    /// @param to The receiver of the shares (Wrapped Comet) to be transferred
    /// @param amount The amount of shares to be transferred
    /// @return bool Indicates success of the transfer
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        uint256 allowed = msg.sender == from ? type(uint256).max : allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed < amount) revert LackAllowance();
        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        transferInternal(from, to, amount);
        return true;
    }

    function transferInternal(address from, address to, uint256 amount) internal {
        // Accrue rewards before transferring assets
        comet.accrueAccount(address(this));
        updateTrackingIndex(from);
        updateTrackingIndex(to);

        balanceOf[from] -= amount;
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);
    }

    /// @notice Total assets of an account that are managed by this vault
    /// @dev The asset balance is computed from an account's shares balance which mirrors how Comet
    /// computes token balances. This is done this way since balances are ever-increasing due to 
    /// interest accrual.
    /// @param account The address to be queried
    /// @return The total amount of assets held by an account
    function underlyingBalance(address account) public view returns (uint256) {
        uint64 baseSupplyIndex_ = accruedSupplyIndex();
        uint256 principal = balanceOf[account];
        return principal > 0 ? presentValueSupply(baseSupplyIndex_, principal) : 0;
    }

    /// @dev Updates an account's `baseTrackingAccrued` which keeps track of rewards accrued by the account.
    /// This uses the latest `trackingSupplyIndex` from Comet to compute for rewards accrual for accounts
    /// that supply the base asset to Comet.
    function updateTrackingIndex(address account) internal {
        UserBasic memory basic = userBasic[account];
        uint256 principal = balanceOf[account];
        (, uint64 trackingSupplyIndex,) = getSupplyIndices();

        if (principal >= 0) {
            uint256 indexDelta = uint256(trackingSupplyIndex - basic.baseTrackingIndex);
            basic.baseTrackingAccrued +=
                safe64(principal * indexDelta / trackingIndexScale / accrualDescaleFactor);
        }
        basic.baseTrackingIndex = trackingSupplyIndex;
        userBasic[account] = basic;
    }

    function accrueInternal(address account) internal {
        comet.accrueAccount(address(this));
        updateTrackingIndex(account);
    }

    /// @notice Get the reward owed to an account
    /// @dev This is designed to exactly match computation of rewards in Comet
    /// and uses the same configuration as CometRewards. It is a combination of both
    /// [`getRewardOwed`](https://github.com/compound-finance/comet/blob/63e98e5d231ef50c755a9489eb346a561fc7663c/contracts/CometRewards.sol#L110) and [`getRewardAccrued`](https://github.com/compound-finance/comet/blob/63e98e5d231ef50c755a9489eb346a561fc7663c/contracts/CometRewards.sol#L171).
    /// @param account The address to be queried
    /// @return The total amount of rewards owed to an account
    function getRewardOwed(address account) external returns (uint256) {
        ICometRewards.RewardConfig memory config = cometRewards.rewardConfig(address(comet));
        return getRewardOwedInternal(config, account);
    }

    function getRewardOwedInternal(ICometRewards.RewardConfig memory config, address account) internal returns (uint256) {
        UserBasic memory basic = accrueRewards(account);
        uint256 claimed = rewardsClaimed[account];
        uint256 accrued = basic.baseTrackingAccrued;

        if (config.shouldUpscale) {
            accrued *= config.rescaleFactor;
        } else {
            accrued /= config.rescaleFactor;
        }

        uint256 owed = accrued > claimed ? accrued - claimed : 0;

        return owed;
    }

    /// @notice Claims caller's rewards and sends them to recipient
    /// @dev Always calls CometRewards for updated configs
    /// @param to The address that will receive the rewards
    function claimTo(address to) external {
        address from = msg.sender;
        ICometRewards.RewardConfig memory config = cometRewards.rewardConfig(address(comet));
        uint256 owed = getRewardOwedInternal(config, from);

        if (owed != 0) {
            rewardsClaimed[from] += owed;
            emit RewardClaimed(from, to, config.token, owed);
            cometRewards.claimTo(address(comet), address(this), address(this), true);
            ERC20(config.token).safeTransfer(to, owed);
        }
    }

    /// @notice Accrues rewards for the account
    /// @dev Latest trackingSupplyIndex is fetched from Comet so we can compute accurate rewards.
    /// This mirrors the logic for rewards accrual in CometRewards so we properly account for users'
    /// rewards as if they had used Comet directly.
    /// @param account The address to whose rewards we want to accrue
    /// @return The UserBasic struct with updated baseTrackingIndex and/or baseTrackingAccrued fields
    function accrueRewards(address account) public returns (UserBasic memory) {
        UserBasic memory basic = userBasic[account];
        uint256 principal = balanceOf[account];
        comet.accrueAccount(address(this));
        (, uint64 trackingSupplyIndex,) = getSupplyIndices();

        if (principal >= 0) {
            uint256 indexDelta = uint256(trackingSupplyIndex - basic.baseTrackingIndex);
            basic.baseTrackingAccrued +=
                safe64((principal * indexDelta) / trackingIndexScale / accrualDescaleFactor);
        }
        basic.baseTrackingIndex = trackingSupplyIndex;
        userBasic[account] = basic;

        return basic;
    }

    /// @dev This returns latest baseSupplyIndex regardless of whether comet.accrueAccount has been called for the
    /// current block. This works like `Comet.accruedInterestedIndices` at but not including computation of
    /// `baseBorrowIndex` since we do not need that index in CometWrapper:
    /// https://github.com/compound-finance/comet/blob/63e98e5d231ef50c755a9489eb346a561fc7663c/contracts/Comet.sol#L383-L394
    function accruedSupplyIndex() internal view returns (uint64) {
        (uint64 baseSupplyIndex_,,uint40 lastAccrualTime) = getSupplyIndices();
        uint256 timeElapsed = uint256(getNowInternal() - lastAccrualTime);
        if (timeElapsed > 0) {
            uint256 utilization = comet.getUtilization();
            uint256 supplyRate = comet.getSupplyRate(utilization);
            baseSupplyIndex_ += safe64(mulFactor(baseSupplyIndex_, supplyRate * timeElapsed));
        }
        return baseSupplyIndex_;
    }

    /// @dev To maintain accuracy, we fetch `baseSupplyIndex` and `trackingSupplyIndex` directly from Comet.
    /// baseSupplyIndex is used on the principal to get the user's latest balance including interest accruals.
    /// trackingSupplyIndex is used to compute for rewards accruals.
    function getSupplyIndices() internal view returns (uint64 baseSupplyIndex_, uint64 trackingSupplyIndex_, uint40 lastAccrualTime_) {
        TotalsBasic memory totals = comet.totalsBasic();
        baseSupplyIndex_ = totals.baseSupplyIndex;
        trackingSupplyIndex_ = totals.trackingSupplyIndex;
        lastAccrualTime_ = totals.lastAccrualTime;
    }

    /// @notice Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
    /// scenario where all the conditions are met.
    /// @dev Treats shares as principal and computes for assets by taking into account interest accrual. Relies on latest
    /// `baseSupplyIndex` from Comet which is the global index used for interest accrual the from supply rate. 
    /// @param shares The amount of shares to be converted to assets
    /// @return The total amount of assets computed from the given shares
    function convertToAssets(uint256 shares) public view override returns (uint256) {
        uint64 baseSupplyIndex_ = accruedSupplyIndex();
        return shares > 0 ? presentValueSupply(baseSupplyIndex_, shares) : 0;
    }

    /// @notice Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
    /// scenario where all the conditions are met.
    /// @dev Assets are converted to shares by computing for the principal using the latest `baseSupplyIndex` from Comet.
    /// @param assets The amount of assets to be converted to shares
    /// @return The total amount of shares computed from the given assets
    function convertToShares(uint256 assets) public view override returns (uint256) {
        uint64 baseSupplyIndex_ = accruedSupplyIndex();
        return assets > 0 ? principalValueSupply(baseSupplyIndex_, assets) : 0;
    }

    /// @notice Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
    /// current on-chain conditions.
    /// @param shares The amount of shares to be converted to assets
    /// @return The total amount of assets required to mint the given shares
    function previewMint(uint256 shares) public view override returns (uint256) {
        return convertToAssets(shares);
    }

    /// @notice Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
    /// given current on-chain conditions.
    /// @param assets The amount of assets to be converted to shares
    /// @return The total amount of shares required to withdraw the given assets
    function previewWithdraw(uint256 assets) public view override returns (uint256) {
        return convertToShares(assets);
    }
}