// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;

import "../interfaces/IMarginEngine.sol";
import "../interfaces/IVAMM.sol";
import "../utils/CustomErrors.sol";
import "../interfaces/IWETH.sol";

interface IPeriphery is CustomErrors {
    // events

    /// @dev emitted after new lp margin cap is set
    event MarginCap(IVAMM vamm, int256 lpMarginCapNew);

    // structs

    struct MintOrBurnParams {
        IMarginEngine marginEngine;
        int24 tickLower;
        int24 tickUpper;
        uint256 notional;
        bool isMint;
        int256 marginDelta;
    }

    struct SwapPeripheryParams {
        IMarginEngine marginEngine;
        bool isFT;
        uint256 notional;
        uint160 sqrtPriceLimitX96;
        int24 tickLower;
        int24 tickUpper;
        uint256 marginDelta;
    }

    /// @dev "constructor" for proxy instances
    function initialize(IWETH weth_) external;

    // view functions

    function getCurrentTick(IMarginEngine marginEngine)
        external
        view
        returns (int24 currentTick);

    /// @param vamm VAMM for which to get the lp cap in underlying tokens
    /// @return Notional Cap for liquidity providers that mint or burn via periphery (enforced in the core if isAlpha is set to true)
    function lpMarginCaps(IVAMM vamm) external view returns (int256);

    /// @param vamm VAMM for which to get the lp notional cumulative in underlying tokens
    /// @return Total amount of notional supplied by the LPs to a given VAMM via the periphery
    function lpMarginCumulatives(IVAMM vamm) external view returns (int256);

    function weth() external view returns (IWETH);

    // non-view functions

    function mintOrBurn(MintOrBurnParams memory params)
        external
        payable
        returns (int256 positionMarginRequirement);

    function swap(SwapPeripheryParams memory params)
        external
        payable
        returns (
            int256 _fixedTokenDelta,
            int256 _variableTokenDelta,
            uint256 _cumulativeFeeIncurred,
            int256 _fixedTokenDeltaUnbalanced,
            int256 _marginRequirement,
            int24 _tickAfter
        );

    function updatePositionMargin(
        IMarginEngine marginEngine,
        int24 tickLower,
        int24 tickUpper,
        int256 marginDelta,
        bool fullyWithdraw
    ) external payable;

    function setLPMarginCap(IVAMM vamm, int256 lpMarginCapNew) external;

    function setLPMarginCumulative(IVAMM vamm, int256 lpMarginCumulative)
        external;

    function settlePositionAndWithdrawMargin(
        IMarginEngine marginEngine,
        address owner,
        int24 tickLower,
        int24 tickUpper
    ) external;

    function rolloverWithMint(
        IMarginEngine marginEngine,
        address owner,
        int24 tickLower,
        int24 tickUpper,
        MintOrBurnParams memory paramsNewPosition
    ) external payable returns (int256 newPositionMarginRequirement);

    function rolloverWithSwap(
        IMarginEngine marginEngine,
        address owner,
        int24 tickLower,
        int24 tickUpper,
        SwapPeripheryParams memory paramsNewPosition
    )
        external
        payable
        returns (
            int256 _fixedTokenDelta,
            int256 _variableTokenDelta,
            uint256 _cumulativeFeeIncurred,
            int256 _fixedTokenDeltaUnbalanced,
            int256 _marginRequirement,
            int24 _tickAfter
        );
}