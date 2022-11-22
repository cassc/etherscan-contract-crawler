pragma solidity 0.8.15;

import "ERC4626.sol";
import "IERC20Metadata.sol";
import "SafeERC20.sol";
import "AssetConverter.sol";
import "CurveLibrary.sol";
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

contract WrappedERC4626CurvePoolConvex is ERC4626, PricePerTokenMixin {
    using CurveLibrary for CurveLibrary.CurvePool;
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Metadata;

    CurveLibrary.CurvePool public curvePool;

    IConvexBooster public immutable convexBooster;
    IConvexReward public immutable convexReward;

    AssetConverter public immutable assetConverter;

    uint256 public poolAssetIndex;
    uint256 public poolAssetsCount;

    uint256 lpTokenDecimals;
    uint256 depositTokenDecimals;

    uint256 convexPoolId;

    IERC20 public immutable crv;
    IERC20 public immutable cvx;

    IERC20[] public rewardTokens;

    constructor(
        CurveLibrary.CurvePool memory _curvePool,
        address _crv,
        address _cvx,
        address _convexBooster,
        address _convexReward,
        address _assetConverter,
        uint256 _convexPoolId,
        string memory name,
        string memory symbol
    ) ERC4626(IERC20Metadata(_curvePool.depositToken)) ERC20(name, symbol) {
        require(_curvePool.poolAddress != address(0), "Zero address provided");
        require(address(_curvePool.LPToken) != address(0), "Zero address provided");
        require(address(_curvePool.depositToken) != address(0), "Zero address provided");
        require(_convexBooster != address(0), "Zero address provided");
        require(_convexReward != address(0), "Zero address provided");
        require(_assetConverter != address(0), "Zero address provided");
        
        curvePool = _curvePool;
        crv = IERC20(_crv);
        cvx = IERC20(_cvx);
        convexBooster = IConvexBooster(_convexBooster);
        convexReward = IConvexReward(_convexReward);
        assetConverter = AssetConverter(_assetConverter);

        lpTokenDecimals = curvePool.LPToken.decimals();
        depositTokenDecimals = _curvePool.depositToken.decimals();

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

        convexPoolId = _convexPoolId;

        IERC20(asset()).safeIncreaseAllowance(curvePool.poolAddress, type(uint256).max);
        curvePool.LPToken.safeIncreaseAllowance(
            address(convexBooster),
            type(uint256).max
        );
        curvePool.LPToken.safeIncreaseAllowance(
            curvePool.poolAddress,
            type(uint256).max
        );
    }

    function totalAssets() public view virtual override returns (uint256) {
        return convertToAssets(totalSupply());
    }

    function _convertLpAmountToShares(uint256 lpAmount)
        internal
        view
        returns (uint256 shares)
    {
        // Current balance on Convex
        uint256 balance = convexReward.balanceOf(address(this));
        if (balance == 0)
            shares = (lpAmount * (10**decimals())) / (10**lpTokenDecimals);
        else {
            shares = (lpAmount * totalSupply()) / balance;
            require(shares > 0, "Too low LP amount");
        }
    }

    function _convertSharesToLpAmount(uint256 shares)
        internal
        view
        returns (uint256 lpAmount)
    {
        if (totalSupply() == 0)
            return (shares * (10**lpTokenDecimals)) / (10**decimals());
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
        return
            _convertLpAmountToShares(
                (assets * (10**lpTokenDecimals)) / curvePool.getVirtualPrice()
            );
    }

    function _convertToAssets(uint256 shares, Math.Rounding rounding)
        internal
        view
        virtual
        override
        returns (uint256 assets)
    {
        uint256 lpAmount = _convertSharesToLpAmount(shares);
        return
            (lpAmount *
                curvePool.getVirtualPrice() *
                (10**depositTokenDecimals)) /
            ((10**18) * (10**lpTokenDecimals));
    }

    function _addLiquidityAndStake(uint256 amount)
        internal
        returns (uint256 shares)
    {
        uint256 lpAmount = curvePool.addLiquidity(amount);
        shares = _convertLpAmountToShares(lpAmount);
        convexBooster.deposit(convexPoolId, lpAmount, true);
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
        
        uint256 lpAmount = _convertSharesToLpAmount(shares);
        convexReward.withdrawAndUnwrap(lpAmount, false);
        assets = curvePool.removeLiquidity(lpAmount);

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