pragma solidity 0.8.15;

import "ERC4626.sol";
import "IERC20Metadata.sol";
import "SafeERC20.sol";
import "PricePerTokenMixin.sol";
import "AssetConverter.sol";

interface IStargateLPStaking {
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function userInfo(uint256 _pid, address user) external view returns(uint256 amount, uint256 rewardDebt);
}

interface IStargateRouter {
    function addLiquidity(
        uint256 _poolId,
        uint256 _amountLD,
        address _to
    ) external;
    function instantRedeemLocal(
        uint16 _srcPoolId,
        uint256 _amountLP,
        address _to
    ) external returns (uint256 amountSD);
}

interface IStargatePool is IERC20Metadata {
    function totalLiquidity() external view returns(uint256);
}

contract WrappedERC4626Stargate is ERC4626, PricePerTokenMixin {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Metadata;
    using SafeERC20 for IStargatePool;

    uint16 stargatePoolId;
    uint256 stargateFarmPid;

    IStargatePool stargateLpToken;

    IStargateRouter stargateRouter;
    IStargateLPStaking stargateLPStaking;

    AssetConverter assetConverter;

    IERC20 rewardToken;

    struct ConstructorParams {
        uint16 stargatePoolId;
        uint256 stargateFarmId;
        IERC20Metadata depositToken;
        IStargatePool stargateLpToken;
        IStargateRouter stargateRouter;
        IStargateLPStaking stargateLPStaking;
        AssetConverter assetConverter;
        IERC20 rewardToken;
        string name;
        string symbol;
    }

    constructor(ConstructorParams memory params) ERC4626(params.depositToken) ERC20(params.name, params.symbol) {
        stargatePoolId = params.stargatePoolId;
        stargateFarmPid = params.stargateFarmId;

        stargateLpToken = params.stargateLpToken;
        stargateRouter = params.stargateRouter;
        stargateLPStaking = params.stargateLPStaking;

        assetConverter = params.assetConverter;
        rewardToken = params.rewardToken;

        params.rewardToken.safeIncreaseAllowance(address(assetConverter), type(uint256).max);
        params.depositToken.safeIncreaseAllowance(address(stargateRouter), type(uint256).max);
        params.stargateLpToken.safeIncreaseAllowance(address(stargateLPStaking), type(uint256).max);
    }

    function totalAssets() public view virtual override returns (uint256) {
        return convertToAssets(totalSupply());
    }

    function _convertToShares(uint256 assets, Math.Rounding rounding)
        internal
        view
        virtual
        override
        returns (uint256 shares)
    {
        uint256 lpAmount = assets * stargateLpToken.totalSupply() / stargateLpToken.totalLiquidity();
        shares = _convertLpAmountToShares(lpAmount);
    }

    function _convertToAssets(uint256 shares, Math.Rounding rounding)
        internal
        view
        virtual
        override
        returns (uint256 assets)
    {

        uint256 lpAmount = _convertSharesToLpAmount(shares);
        assets = lpAmount * stargateLpToken.totalLiquidity() / stargateLpToken.totalSupply();
    }

    function _convertLpAmountToShares(uint256 lpAmount)
        internal
        view
        returns (uint256 shares)
    {
        (uint256 balance,) = stargateLPStaking.userInfo(stargateFarmPid, address(this));
        if (balance == 0)
            shares = (lpAmount * (10**decimals())) / (10**stargateLpToken.decimals());
        else {
            shares = (lpAmount * totalSupply()) / balance;
        }
    }

    function _convertSharesToLpAmount(uint256 shares)
        internal
        view
        returns (uint256 lpAmount)
    {
        if (totalSupply() == 0)
            return (shares * (10**stargateLpToken.decimals())) / (10**decimals());
        else {
            (uint256 balance,) = stargateLPStaking.userInfo(stargateFarmPid, address(this));
            return
                (shares * balance) /
                totalSupply();
        }
    }

    function _addLiquidityAndStake(uint256 amount)
        internal
        returns (uint256 shares)
    {

        uint256 prevLpBalance = stargateLpToken.balanceOf(address(this));
        stargateRouter.addLiquidity(stargatePoolId, amount, address(this));
        uint256 lpAmount = stargateLpToken.balanceOf(address(this)) - prevLpBalance;
        shares = _convertLpAmountToShares(lpAmount);
        stargateLPStaking.deposit(stargateFarmPid, lpAmount);
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
        stargateLPStaking.withdraw(stargateFarmPid, lpAmount);
        assets = stargateRouter.instantRedeemLocal(stargatePoolId, lpAmount, receiver);

        _burn(owner, shares);

        emit Withdraw(caller, receiver, owner, assets, shares);
    }

    function harvest() external returns(uint256 harvestedAmount) {
        stargateLPStaking.deposit(stargateFarmPid, 0);
        uint256 balance = rewardToken.balanceOf(address(this));
        if (balance > 0)
            harvestedAmount = assetConverter.swap(
                address(rewardToken),
                asset(),
                balance);
            _addLiquidityAndStake(harvestedAmount);
    }
}