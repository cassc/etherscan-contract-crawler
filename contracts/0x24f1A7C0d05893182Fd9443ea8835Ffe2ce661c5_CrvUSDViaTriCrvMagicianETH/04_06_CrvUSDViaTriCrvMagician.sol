// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IMagician.sol";
import "../_common/libraries/CrvUSDToWethViaTriCrvPoolLib.sol";

interface ICrvPoolLike {
    // solhint-disable func-name-mixedcase
    function get_dx(uint256 i, uint256 j, uint256 dy) external view returns (uint256);
    function get_dy(uint256 i, uint256 j, uint256 dx) external view returns (uint256);
}

/// @dev crvUSD Magician
/// IT IS NOT PART OF THE PROTOCOL. SILO CREATED THIS TOOL, MOSTLY AS AN EXAMPLE.
abstract contract CrvUSDViaTriCrvMagician is IMagician {
    using CrvUSDToWethViaTriCrvPoolLib for uint256;

    error InvalidAsset();
    error InvalidCalculationResult();

    // solhint-disable var-name-mixedcase
    address immutable public TRI_CRV_POOL;

    IERC20 immutable public WETH;
    IERC20 immutable public CRV_USD;
    // solhint-enable var-name-mixedcase

    constructor(
        address _triCrvPool,
        address _weth,
        address _crvUsd
    ) {
        TRI_CRV_POOL = _triCrvPool;
        WETH = IERC20(_weth);
        CRV_USD = IERC20(_crvUsd);
    }

    /// @inheritdoc IMagician
    function towardsNative(address _asset, uint256 _crvUsdToSell)
        external
        virtual
        returns (address tokenOut, uint256 amountOut)
    {
        // crvUSD -> WETH
        if (_asset != address(CRV_USD)) revert InvalidAsset();

        amountOut = _crvUsdToSell.crvUsdToWethViaTriCrv(TRI_CRV_POOL, CRV_USD);

        tokenOut = address(WETH);
    }

    /// @inheritdoc IMagician
    function towardsAsset(address _asset, uint256 _crvUsdToBuy)
        external
        virtual
        returns (address tokenOut, uint256 wethIn)
    {
        // WETH -> crvUSD
        if (_asset != address(CRV_USD)) revert InvalidAsset();

        wethIn = _getDx(_crvUsdToBuy);

        uint256 expectedCrvUsd = ICrvPoolLike(TRI_CRV_POOL).get_dy(
            CrvUSDToWethViaTriCrvPoolLib.WETH_INDEX,
            CrvUSDToWethViaTriCrvPoolLib.CRV_USD_INDEX,
            wethIn
        );

        // get_dx returns such a WETH amount that when we will do an exchange,
        // we receive ~0.0001% less than we need for the liquidation. It is dust,
        // the liquidation will fail as we need to repay the exact amount.
        // To compensate for this, we will increase WETH a little bit.
        // It is fine if we will buy ~0.0001% more.
        if (expectedCrvUsd < _crvUsdToBuy) {
            uint256 oneCrvUsd = 1e18;

            uint256 wethForOneCrv = ICrvPoolLike(TRI_CRV_POOL).get_dy(
                CrvUSDToWethViaTriCrvPoolLib.CRV_USD_INDEX,
                CrvUSDToWethViaTriCrvPoolLib.WETH_INDEX,
                oneCrvUsd
            );

            // it is impossible that we will need to spend ETH close to uint256 max
            unchecked { wethIn += wethForOneCrv / 1e3; }
        }

        wethIn.wethToCrvUsdViaTriCrv(TRI_CRV_POOL, WETH);

        tokenOut = address(CRV_USD);
    }

    function _getDx(uint256 _crvToBuy) internal view returns (uint256 wethIn) {
        return ICrvPoolLike(TRI_CRV_POOL).get_dx(
            CrvUSDToWethViaTriCrvPoolLib.WETH_INDEX,
            CrvUSDToWethViaTriCrvPoolLib.CRV_USD_INDEX,
            _crvToBuy
        );
    }
}