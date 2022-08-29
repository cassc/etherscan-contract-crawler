// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {SafeMath, SafeERC20} from "contracts/libraries/Imports.sol";
import {IZap} from "contracts/lpaccount/Imports.sol";
import {
    IAssetAllocation,
    IDetailedERC20,
    IERC20
} from "contracts/common/Imports.sol";
import {
    Curve3poolUnderlyerConstants
} from "contracts/protocols/curve/3pool/Constants.sol";

abstract contract CurveZapBase is Curve3poolUnderlyerConstants, IZap {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address internal constant CRV_ADDRESS =
        0xD533a949740bb3306d119CC777fa900bA034cd52;

    address internal immutable SWAP_ADDRESS;
    uint256 internal immutable DENOMINATOR;
    uint256 internal immutable SLIPPAGE;
    uint256 internal immutable N_COINS;

    constructor(
        address swapAddress,
        uint256 denominator,
        uint256 slippage,
        uint256 nCoins
    ) public {
        SWAP_ADDRESS = swapAddress;
        DENOMINATOR = denominator;
        SLIPPAGE = slippage;
        N_COINS = nCoins;
    }

    /// @param amounts array of underlyer amounts
    function deployLiquidity(uint256[] calldata amounts) external override {
        require(amounts.length == N_COINS, "INVALID_AMOUNTS");

        uint256 totalNormalizedDeposit = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            if (amounts[i] == 0) continue;

            uint256 deposit = amounts[i];
            address underlyerAddress = _getCoinAtIndex(i);
            uint8 decimals = IDetailedERC20(underlyerAddress).decimals();

            uint256 normalizedDeposit =
                deposit.mul(10**uint256(18)).div(10**uint256(decimals));
            totalNormalizedDeposit = totalNormalizedDeposit.add(
                normalizedDeposit
            );

            IERC20(underlyerAddress).safeApprove(SWAP_ADDRESS, 0);
            IERC20(underlyerAddress).safeApprove(SWAP_ADDRESS, amounts[i]);
        }

        uint256 minAmount =
            _calcMinAmount(totalNormalizedDeposit, _getVirtualPrice());
        _addLiquidity(amounts, minAmount);
        _depositToGauge();
    }

    /**
     * @param amount LP token amount
     * @param index underlyer index
     */
    function unwindLiquidity(uint256 amount, uint8 index) external override {
        require(index < N_COINS, "INVALID_INDEX");
        uint256 lpBalance = _withdrawFromGauge(amount);
        address underlyerAddress = _getCoinAtIndex(index);
        uint8 decimals = IDetailedERC20(underlyerAddress).decimals();
        uint256 minAmount =
            _calcMinAmountUnderlyer(lpBalance, _getVirtualPrice(), decimals);
        _removeLiquidity(lpBalance, index, minAmount);
    }

    function claim() external override {
        _claim();
    }

    function sortedSymbols() public view override returns (string[] memory) {
        // N_COINS is not available as a public function
        // so we have to hardcode the number here
        string[] memory symbols = new string[](N_COINS);
        for (uint256 i = 0; i < symbols.length; i++) {
            address underlyerAddress = _getCoinAtIndex(i);
            symbols[i] = IDetailedERC20(underlyerAddress).symbol();
        }
        return symbols;
    }

    function _getVirtualPrice() internal view virtual returns (uint256);

    function _getCoinAtIndex(uint256 i) internal view virtual returns (address);

    function _addLiquidity(uint256[] calldata amounts_, uint256 minAmount)
        internal
        virtual;

    function _removeLiquidity(
        uint256 lpBalance,
        uint8 index,
        uint256 minAmount
    ) internal virtual;

    function _depositToGauge() internal virtual;

    function _withdrawFromGauge(uint256 amount)
        internal
        virtual
        returns (uint256);

    function _claim() internal virtual;

    /**
     * @dev normalizedDepositAmount the amount in same units as virtual price (18 decimals)
     * @dev virtualPrice the "price", in 18 decimals, per big token unit of the LP token
     * @return required minimum amount of LP token (in token wei)
     */
    function _calcMinAmount(
        uint256 normalizedDepositAmount,
        uint256 virtualPrice
    ) internal view returns (uint256) {
        uint256 idealLpTokenAmount =
            normalizedDepositAmount.mul(1e18).div(virtualPrice);
        // allow some slippage/MEV
        return
            idealLpTokenAmount.mul(DENOMINATOR.sub(SLIPPAGE)).div(DENOMINATOR);
    }

    /**
     * @param lpTokenAmount the amount in the same units as Curve LP token (18 decimals)
     * @param virtualPrice the "price", in 18 decimals, per big token unit of the LP token
     * @param decimals the number of decimals for underlyer token
     * @return required minimum amount of underlyer (in token wei)
     */
    function _calcMinAmountUnderlyer(
        uint256 lpTokenAmount,
        uint256 virtualPrice,
        uint8 decimals
    ) internal view returns (uint256) {
        // TODO: grab LP Token decimals explicitly?
        uint256 normalizedUnderlyerAmount =
            lpTokenAmount.mul(virtualPrice).div(1e18);
        uint256 underlyerAmount =
            normalizedUnderlyerAmount.mul(10**uint256(decimals)).div(
                10**uint256(18)
            );

        // allow some slippage/MEV
        return underlyerAmount.mul(DENOMINATOR.sub(SLIPPAGE)).div(DENOMINATOR);
    }

    function _createErc20AllocationArray(uint256 extraAllocations)
        internal
        pure
        returns (IERC20[] memory)
    {
        IERC20[] memory allocations = new IERC20[](extraAllocations.add(4));
        allocations[0] = IERC20(CRV_ADDRESS);
        allocations[1] = IERC20(DAI_ADDRESS);
        allocations[2] = IERC20(USDC_ADDRESS);
        allocations[3] = IERC20(USDT_ADDRESS);
        return allocations;
    }
}