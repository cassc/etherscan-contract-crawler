pragma solidity 0.8.15;

import "ERC4626.sol";
import "IERC20Metadata.sol";
import "SafeERC20.sol";
import "AssetConverter.sol";
import "CurveMetapoolLibrary.sol";
import "PricePerTokenMixin.sol";

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

contract WrappedERC4626CurveMetapoolConvex is ERC4626, PricePerTokenMixin {
    using CurveMetapoolLibrary for CurveMetapoolLibrary.CurveMetapool;
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Metadata;

    // The end pool
    CurveMetapoolLibrary.CurveMetapool public curveMetapool;

    IConvexBooster public immutable convexBooster;
    IConvexReward public immutable convexReward;

    AssetConverter public assetConverter;

    uint256 public poolAssetIndex;
    uint256 public poolAssetsCount;

    uint256 depositTokenDecimals;

    uint256 convexPoolId;

    IERC20 public immutable crv;
    IERC20 public immutable cvx;

    IERC20[] public rewardTokens;

    struct ConstructorParameters {
        CurveMetapoolLibrary.CurveMetapool curveMetapool;
        address crv;
        address cvx;
        address convexBooster;
        address convexReward;
        address assetConverter;
        uint256 convexPoolId;
        IERC20Metadata LPToken;
        IERC20Metadata token;
        string name;
        string symbol;
    }

    uint8 private immutable _decimals;

    constructor(ConstructorParameters memory params)
        ERC4626(params.token)
        ERC20(params.name, params.symbol)
    {
        require(params.curveMetapool.zapAddress != address(0), "Zero address provided");
        require(params.curveMetapool.poolAddress != address(0), "Zero address provided");
        require(params.crv != address(0), "Zero address provided");
        require(params.cvx != address(0), "Zero address provided");
        require(address(params.token) != address(0), "Zero address provided");
        require(address(params.LPToken) != address(0), "Zero address provided");
        require(params.convexBooster != address(0), "Zero address provided");
        require(params.convexReward != address(0), "Zero address provided");
        require(params.assetConverter != address(0), "Zero address provided");

        curveMetapool = params.curveMetapool;

        crv = IERC20(params.crv);
        cvx = IERC20(params.cvx);
        convexBooster = IConvexBooster(params.convexBooster);
        convexReward = IConvexReward(params.convexReward);

        assetConverter = AssetConverter(params.assetConverter);

        depositTokenDecimals = params.token.decimals();

        rewardTokens.push(cvx);
        rewardTokens.push(crv);

        cvx.safeIncreaseAllowance(address(assetConverter), type(uint256).max);
        crv.safeIncreaseAllowance(address(assetConverter), type(uint256).max);
        
        for (uint i = 0; i < convexReward.extraRewardsLength(); i++) {
            address rewardToken = IConvexRewardVirtual(
                convexReward.extraRewards(i)
            ).rewardToken();
            rewardTokens.push(IERC20(rewardToken));
            IERC20(rewardToken).safeIncreaseAllowance(
                address(assetConverter),
                type(uint256).max
            );
        }

        convexPoolId = params.convexPoolId;

        IERC20(asset()).safeIncreaseAllowance(
            curveMetapool.zapAddress,
            type(uint256).max
        );
        params.LPToken.safeIncreaseAllowance(
            curveMetapool.zapAddress,
            type(uint256).max
        );
        params.LPToken.safeIncreaseAllowance(
            address(convexBooster),
            type(uint256).max
        );
        _decimals = params.LPToken.decimals();
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

    function decimals() public view virtual override returns (uint8)
    {
        return _decimals;
    }

    function totalAssets() public view virtual override returns (uint256) {
        return convertToAssets(totalSupply());
    }

    function _convertMetapoolLpAmountToShares(uint256 lpAmount)
        internal
        view
        returns (uint256 shares)
    {
        // Current balance on Convex
        uint256 balance = convexReward.balanceOf(address(this));
        if (balance == 0)
            shares = lpAmount;
        else {
            shares = (lpAmount * totalSupply()) / balance;
        }
    }

    function _convertSharesToMetapoolLpAmount(uint256 shares)
        internal
        view
        returns (uint256 lpAmount)
    {
        if (totalSupply() == 0)
            return shares;
        else
            return
                (shares * convexReward.balanceOf(address(this))) /
                totalSupply();
    }

    function _convertToShares(uint256 assets, Math.Rounding rounding)
        internal
        view
        virtual
        override
        returns (uint256 shares)
    {
        assets = (assets * (10**18)) / (10**depositTokenDecimals);
        uint256 metapoolLpAmount = (assets * (10**decimals())) /
            curveMetapool.getVirtualPrice();
        return _convertMetapoolLpAmountToShares(metapoolLpAmount);
    }

    function _convertToAssets(uint256 shares, Math.Rounding rounding)
        internal
        view
        virtual
        override
        returns (uint256 assets)
    {
        uint256 metapoolLpAmount = _convertSharesToMetapoolLpAmount(shares);
        return
            (metapoolLpAmount *
                curveMetapool.getVirtualPrice() *
                (10**depositTokenDecimals)) /
            ((10**18) * (10**decimals()));
    }


    function _addLiquidityAndStake(uint256 amount)
        internal
        returns (uint256 shares)
    {
        uint256 metapoolLpAmount = curveMetapool.addLiquidity(amount);
        shares = _convertMetapoolLpAmountToShares(metapoolLpAmount);
        convexBooster.deposit(convexPoolId, metapoolLpAmount, true);
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

        uint256 metapoolLpAmount = _convertSharesToMetapoolLpAmount(shares);
        convexReward.withdrawAndUnwrap(metapoolLpAmount, false);
        assets = curveMetapool.removeLiquidity(metapoolLpAmount);

        _burn(owner, shares);
        IERC20(asset()).safeTransfer(receiver, assets);

        emit Withdraw(caller, receiver, owner, assets, shares);
    }

    function harvest() external returns(uint256 harvestedAmount) {
        convexReward.getReward();
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            uint256 balance = rewardTokens[i].balanceOf(address(this));
            if (balance > 0)
                harvestedAmount += assetConverter.swap(
                    address(rewardTokens[i]),
                    asset(),
                    rewardTokens[i].balanceOf(address(this))
                );
        }
        if (harvestedAmount > 0) {
            _addLiquidityAndStake(harvestedAmount);
        }
    }
}