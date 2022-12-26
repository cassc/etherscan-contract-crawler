pragma solidity 0.8.15;

import "ERC4626.sol";
import "IERC20Metadata.sol";
import "SafeERC20.sol";
import "AssetConverter.sol";
import "PricePerTokenMixin.sol";
import {WrappedERC4626YearnCRV} from "WrappedERC4626YearnCRV.sol";



interface IConvexBooster {
    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _stake
    ) external returns (bool);
}

interface IConvexRewardVirtual {
    function rewardToken() external view returns (address);
}

interface IConvexReward {
    function withdrawAndUnwrap(uint256 amount, bool claim)
        external
        returns (bool);

    function getReward() external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function extraRewardsLength() external view returns (uint256);

    function extraRewards(uint256 i) external view returns (address);
}

abstract contract WrappedERC4626CurveConvex is ERC4626, PricePerTokenMixin {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Metadata;

    IConvexBooster public immutable convexBooster;
    IConvexReward public immutable convexReward;
    AssetConverter public immutable assetConverter;
    uint256 depositTokenDecimals;
    uint256 convexPoolId;
    uint256 currentBalanceAtConvex;
    bool stakeInYCRV;
    WrappedERC4626YearnCRV ycrvVault;

    IERC20 public immutable crv;
    IERC20[] public rewardTokens;
    uint8 private immutable _decimals;

    constructor(
        IERC20 _crv,
        IERC20 _cvx,
        bool _stakeInYCRV,
        WrappedERC4626YearnCRV _ycrvVault,
        IConvexBooster _convexBooster,
        IConvexReward _convexReward,
        IERC20Metadata _depositToken,
        IERC20Metadata _LPToken,
        AssetConverter _assetConverter,
        uint256 _convexPoolId,
        string memory name,
        string memory symbol
    ) ERC4626(_depositToken) ERC20(name, symbol) {
        require(address(_crv) != address(0), "Zero address provided");
        require(address(_cvx) != address(0), "Zero address provided");
        require(address(_ycrvVault) != address(0), "Zero address provided");
        require(address(_convexBooster) != address(0), "Zero address provided");
        require(address(_convexReward) != address(0), "Zero address provided");
        require(address(_depositToken) != address(0), "Zero address provided");
        require(address(_LPToken) != address(0), "Zero address provided");
        require(
            address(_assetConverter) != address(0),
            "Zero address provided"
        );

        crv = _crv;
        convexBooster = _convexBooster;
        convexReward = _convexReward;
        assetConverter = _assetConverter;
        ycrvVault = _ycrvVault;
        depositTokenDecimals = _depositToken.decimals();
        stakeInYCRV = _stakeInYCRV;
        convexPoolId = _convexPoolId;

        rewardTokens.push(_cvx);
        rewardTokens.push(_crv);

        _cvx.safeIncreaseAllowance(address(assetConverter), type(uint256).max);
        _crv.safeIncreaseAllowance(address(assetConverter), type(uint256).max);

        for (uint256 i = 0; i < convexReward.extraRewardsLength(); i++) {
            address rewardToken = IConvexRewardVirtual(
                convexReward.extraRewards(i)
            ).rewardToken();
            rewardTokens.push(IERC20(rewardToken));
            IERC20(rewardToken).safeIncreaseAllowance(
                address(assetConverter),
                type(uint256).max
            );
        }
        crv.safeIncreaseAllowance(address(ycrvVault), type(uint256).max);
        _decimals = _LPToken.decimals();
        _LPToken.safeIncreaseAllowance(address(convexBooster), type(uint256).max);
    }

    function maxDeposit(address)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return type(uint256).max;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function totalAssets() public view virtual override returns (uint256) {
        uint256 totalAssetsConvex = _convertLPAmountToAssets(
            convexReward.balanceOf(address(this))
        );
        uint256 totalAssetsycrv = (ycrvVault.convertToUSD(
            ycrvVault.balanceOf(address(this))
        ) * (10**depositTokenDecimals)) / (10**ycrvVault.decimals());
        return totalAssetsConvex + totalAssetsycrv;
    }

    function _convertLPAmountToAssets(uint256 lpAmount)
        internal
        view
        returns (uint256 shares)
    {
        return
            (lpAmount * _getVirtualPrice() * (10**depositTokenDecimals)) /
            ((10**18) * (10**decimals()));
    }

    function _convertAssetsToLPAmount(uint256 assets)
        internal
        view
        returns (uint256 lpAmount)
    {
        assets = (assets * (10**18)) / (10**depositTokenDecimals);
        return (assets * (10**decimals())) / _getVirtualPrice();
    }

    function _convertToShares(uint256 assets, Math.Rounding rounding)
        internal
        view
        virtual
        override
        returns (uint256 shares)
    {
        uint256 _totalAssets = totalAssets();
        return
            _totalAssets == 0
                ? _convertAssetsToLPAmount(assets)
                : (assets * totalSupply()) / _totalAssets;
    }

    function _convertToAssets(uint256 shares, Math.Rounding rounding)
        internal
        view
        virtual
        override
        returns (uint256 assets)
    {
        uint256 _totalSupply = totalSupply();
        return
            _totalSupply == 0
                ? _convertLPAmountToAssets(shares)
                : (shares * totalAssets()) / _totalSupply;
    }

    function _addLiquidity(uint256 assets)
        internal
        virtual
        returns (uint256 lpAmount)
    {}

    function _removeLiquidity(uint256 lpAmount)
        internal
        virtual
        returns (uint256 assets)
    {}

    function _getVirtualPrice() internal virtual view returns(uint256) {}

    function _addLiquidityAndStake(uint256 assets)
        internal
        returns (uint256 shares)
    {
        uint256 lpAmount = _addLiquidity(assets);
        shares = convertToShares(_convertLPAmountToAssets(lpAmount));
        convexBooster.deposit(convexPoolId, lpAmount, true);
        currentBalanceAtConvex += lpAmount;
    }

    function _deposit(
        address caller,
        address receiver,
        uint256 assets,
        uint256 shares
    ) internal virtual override {
        IERC20(asset()).safeTransferFrom(caller, address(this), assets);

        shares = _addLiquidityAndStake(assets);

        _mint(receiver, shares);

        emit Deposit(caller, receiver, assets, shares);
    }

    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal virtual override {
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }

        uint256 lpAmount = (shares * currentBalanceAtConvex) / totalSupply();
        convexReward.withdrawAndUnwrap(lpAmount, false);
        currentBalanceAtConvex -= lpAmount;
        assets = _removeLiquidity(lpAmount);

        uint256 ycrvlLpAmount = (shares * ycrvVault.balanceOf(address(this))) /
            totalSupply();
        if (ycrvlLpAmount > 0) {
            ycrvVault.redeem(ycrvlLpAmount, address(this), address(this));
            assets += assetConverter.swap(
                address(crv),
                asset(),
                crv.balanceOf(address(this))
            );
        }

        _burn(owner, shares);
        IERC20(asset()).safeTransfer(receiver, assets);

        emit Withdraw(caller, receiver, owner, assets, shares);
    }

    function harvest() external returns (uint256 harvestedAmount) {
        convexReward.getReward();
        uint256 prevTotalAssets = totalAssets();
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            IERC20 token = rewardTokens[i];
            uint256 balance = token.balanceOf(address(this));
            if (balance > 0) {
                if (stakeInYCRV) {
                    uint256 amount;
                    if (token == crv) {
                        amount = balance;
                    } else {
                        amount = assetConverter.swap(
                            address(token),
                            address(crv),
                            balance
                        );
                    }
                    ycrvVault.deposit(amount, address(this));
                } else {
                    assetConverter.swap(
                        address(rewardTokens[i]),
                        asset(),
                        rewardTokens[i].balanceOf(address(this))
                    );
                }
            }
        }
        uint256 balance = IERC20(asset()).balanceOf(address(this));
        if (balance > 0) {
            _addLiquidityAndStake(balance);
        }
        harvestedAmount = totalAssets() - prevTotalAssets;
    }
}