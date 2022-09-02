// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.10;
pragma abicoder v2;
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./../external/IAToken.sol";
import "./../external/IPool.sol";
import "./../external/DataTypes.sol";
import "./../external/IAaveIncentivesController.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "./../interfaces/IProvider.sol";

contract AaveProvideraV2 is IProvider, Initializable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    uint256 public constant EXP_SCALE = 1e18;
    uint256 private constant MAX_UINT256 = type(uint256).max;

    address public override smartYield;

    // underlying token (ie. DAI)
    address public uToken; // IERC20

    // aave aToken
    address public override cToken;

    uint256 public totalUnRedeemed;

    EnumerableSetUpgradeable.AddressSet private whiteListAssets;

    modifier onlySmartYield() {
        require(msg.sender == smartYield, "AP: only smartYield");
        _;
    }

    function initialize(address aToken_, address smartYield_) public override initializer {
        cToken = aToken_;
        uToken = IAToken(aToken_).UNDERLYING_ASSET_ADDRESS();
        smartYield = smartYield_;
    }

    // externals

    // take underlyingAmount_ from from_
    function _takeUnderlying(address from_, uint256 underlyingAmount_) external override onlySmartYield {
        uint256 balanceBefore = IERC20Upgradeable(uToken).balanceOf(address(this));
        IERC20Upgradeable(uToken).safeTransferFrom(from_, address(this), underlyingAmount_);
        uint256 balanceAfter = IERC20Upgradeable(uToken).balanceOf(address(this));
        require(0 == (balanceAfter - balanceBefore - underlyingAmount_), "AP: _takeUnderlying amount");
    }

    // transfer away underlyingAmount_ to to_
    function _sendUnderlying(address to_, uint256 underlyingAmount_) external override onlySmartYield {
        uint256 balanceBefore = IERC20Upgradeable(uToken).balanceOf(to_);
        IERC20Upgradeable(uToken).safeTransfer(to_, underlyingAmount_);
        uint256 balanceAfter = IERC20Upgradeable(uToken).balanceOf(to_);
        require(0 == (balanceAfter - balanceBefore - underlyingAmount_), "AP: _sendUnderlying amount");
    }

    // deposit underlyingAmount_ with the liquidity provider, callable by smartYield or controller
    function _depositProvider(uint256 underlyingAmount_) external override onlySmartYield {
        _depositProviderInternal(underlyingAmount_);
        totalUnRedeemed = totalUnRedeemed + underlyingAmount_;
    }

    // deposit underlyingAmount_ with the liquidity provider, store resulting cToken balance in cTokenBalance
    function _depositProviderInternal(uint256 underlyingAmount_) internal {
        IERC20Upgradeable(uToken).safeApprove(address(IAToken(cToken).POOL()), underlyingAmount_);
        // For Aave V3
        // IPool(IAToken(cToken).POOL()).supply(uToken, underlyingAmount_, address(this), 0);
        // For Aave V2, works in V3 but not that it will be deprecated
        IPool(IAToken(cToken).POOL()).deposit(uToken, underlyingAmount_, address(this), 0);
    }

    // withdraw underlyingAmount_ from the liquidity provider, callable by smartYield
    function _withdrawProvider(uint256 underlyingAmount_) external override onlySmartYield {
        _withdrawProviderInternal(underlyingAmount_);
        totalUnRedeemed = totalUnRedeemed - underlyingAmount_;
    }

    function addTotalUnRedeemed(uint256 amount) external onlySmartYield {
        totalUnRedeemed = totalUnRedeemed + amount;
    }

    // withdraw underlyingAmount_ from the liquidity provider, store resulting cToken balance in cTokenBalance
    function _withdrawProviderInternal(uint256 underlyingAmount_) internal {
        uint256 actualUnderlyingAmount = IPool(IAToken(cToken).POOL()).withdraw(
            uToken,
            underlyingAmount_,
            address(this)
        );
        require(actualUnderlyingAmount == underlyingAmount_, "AP: _withdrawProvider withdraw");
    }

    function claimRewardsTo(address[] calldata assets, address to) external override onlySmartYield returns (uint256) {
        // For Aave V3
        // return IAaveIncentivesController(IAToken(cToken).getIncentivesController()).claimAllRewards(assets, to);
        // For Aave V2
        return
            IAaveIncentivesController(address(IAToken(cToken).getIncentivesController())).claimRewards(
                assets,
                MAX_UINT256,
                to
            );
    }

    // current total underlying balance, as measured by pool, without fees
    function underlyingBalance() external view virtual override returns (uint256) {
        // https://docs.aave.com/developers/the-core-protocol/atokens#eip20-methods
        // total underlying balance minus underlyingFees
        return IAToken(cToken).balanceOf(address(this));
    }

    function enableBorrowAsset(address asset) external override onlySmartYield {
        whiteListAssets.add(asset);
    }

    function disableBorrowAsset(address asset) external override onlySmartYield {
        whiteListAssets.remove(asset);
    }

    // borrow underlyingAmount_ from the liquidity provider, callable by smartYield
    function _borrowProvider(address borrowAsset, uint256 amount) external override onlySmartYield {
        require(whiteListAssets.contains(borrowAsset), "AP: asset is not allowed to be borrowed");
        IPool(IAToken(cToken).POOL()).borrow(borrowAsset, amount, 1, 0, address(this));
        IERC20Upgradeable(borrowAsset).safeTransfer(smartYield, amount);
    }

    function _repayProvider(address borrowAsset, uint256 _amount) external payable override onlySmartYield {
        IERC20Upgradeable(borrowAsset).safeApprove(address(IAToken(cToken).POOL()), _amount);
        IPool(IAToken(cToken).POOL()).repay(borrowAsset, _amount, 1, payable(address(this)));
    }

    function _getUserAccountDataProvider(address _user)
        external
        view
        override
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        )
    {
        return IPool(IAToken(cToken).POOL()).getUserAccountData(_user);
    }

    function _getReserveDataProvider(address _reserve)
        external
        view
        override
        returns (DataTypes.ReserveData memory reserveData)
    {
        return IPool(IAToken(cToken).POOL()).getReserveData(_reserve);
    }

    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external override onlySmartYield {
        IPool(IAToken(cToken).POOL()).setUserUseReserveAsCollateral(asset, useAsCollateral);
    }
}