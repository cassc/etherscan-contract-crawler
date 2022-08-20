// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;

pragma abicoder v2;

import "../interfaces/IMarginEngine.sol";
import "../interfaces/IVAMM.sol";
import "../interfaces/IPeriphery.sol";
import "../utils/TickMath.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../core_libraries/SafeTransferLib.sol";
import "../core_libraries/Tick.sol";
import "../core_libraries/FixedAndVariableMath.sol";
import "../storage/PeripheryStorage.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "hardhat/console.sol";

/// @dev inside mint or burn check if the position already has margin deposited and add it to the cumulative balance

contract Periphery is
    PeripheryStorage,
    IPeriphery,
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using SafeCast for uint256;
    using SafeCast for int256;
    uint256 internal constant Q96 = 2**96;

    using SafeTransferLib for IERC20Minimal;

    modifier vammOwnerOnly(IVAMM vamm) {
        require(address(vamm) != address(0), "vamm addr zero");
        address vammOwner = OwnableUpgradeable(address(vamm)).owner();
        require(msg.sender == vammOwner, "only vamm owner");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(IWETH weth_) external override initializer {
        require(address(weth_) != address(0), "weth addr zero");
        _weth = weth_;

        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    // To authorize the owner to upgrade the contract we implement _authorizeUpgrade with the onlyOwner modifier.
    // ref: https://forum.openzeppelin.com/t/uups-proxies-tutorial-solidity-javascript/7786
    function _authorizeUpgrade(address) internal override onlyOwner {}

    /// @inheritdoc IPeriphery
    function lpMarginCaps(IVAMM vamm) external view override returns (int256) {
        return _lpMarginCaps[vamm];
    }

    /// @inheritdoc IPeriphery
    function lpMarginCumulatives(IVAMM vamm)
        external
        view
        override
        returns (int256)
    {
        return _lpMarginCumulatives[vamm];
    }

    function weth() external view override returns (IWETH) {
        return _weth;
    }

    /// @notice Computes the amount of liquidity received for a given notional amount and price range
    /// @dev Calculates amount1 / (sqrt(upper) - sqrt(lower)).
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param notionalAmount The amount of notional being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForNotional(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 notionalAmount
    ) public pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        return
            FullMath
                .mulDiv(notionalAmount, Q96, sqrtRatioBX96 - sqrtRatioAX96)
                .toUint128();
    }

    function setLPMarginCap(IVAMM vamm, int256 lpMarginCapNew)
        external
        override
        vammOwnerOnly(vamm)
    {
        _lpMarginCaps[vamm] = lpMarginCapNew;
        emit MarginCap(vamm, _lpMarginCaps[vamm]);
    }

    function setLPMarginCumulative(IVAMM vamm, int256 lpMarginCumulative)
        external
        override
        vammOwnerOnly(vamm)
    {
        _lpMarginCumulatives[vamm] = lpMarginCumulative;
    }

    function accountLPMarginCap(
        IVAMM vamm,
        bytes32 encodedPosition,
        int256 newMargin,
        bool isLPBefore,
        bool isLPAfter
    ) internal {
        if (isLPAfter) {
            // added some liquidity, need to account for margin
            _lpMarginCumulatives[vamm] -= _lastAccountedMargin[encodedPosition];
            _lastAccountedMargin[encodedPosition] = newMargin;
            _lpMarginCumulatives[vamm] += _lastAccountedMargin[encodedPosition];
        } else {
            if (isLPBefore) {
                _lpMarginCumulatives[vamm] -= _lastAccountedMargin[
                    encodedPosition
                ];
                _lastAccountedMargin[encodedPosition] = 0;
            }
        }

        require(
            _lpMarginCumulatives[vamm] <= _lpMarginCaps[vamm],
            "lp cap limit"
        );
    }

    function settlePositionAndWithdrawMargin(
        IMarginEngine marginEngine,
        address owner,
        int24 tickLower,
        int24 tickUpper
    ) public override {
        marginEngine.settlePosition(owner, tickLower, tickUpper);

        updatePositionMargin(marginEngine, tickLower, tickUpper, 0, true); // fully withdraw
    }

    function updatePositionMargin(
        IMarginEngine marginEngine,
        int24 tickLower,
        int24 tickUpper,
        int256 marginDelta,
        bool fullyWithdraw
    ) public payable override {
        Position.Info memory position = marginEngine.getPosition(
            msg.sender,
            tickLower,
            tickUpper
        );

        bool isAlpha = marginEngine.isAlpha();
        IVAMM vamm = marginEngine.vamm();
        bytes32 encodedPosition = keccak256(
            abi.encodePacked(
                msg.sender,
                address(vamm),
                address(marginEngine),
                tickLower,
                tickUpper
            )
        );

        if (isAlpha && position._liquidity > 0) {
            if (_lastAccountedMargin[encodedPosition] == 0) {
                _lastAccountedMargin[encodedPosition] = position.margin;
            }
        }

        IERC20Minimal underlyingToken = marginEngine.underlyingToken();

        if (fullyWithdraw) {
            marginDelta = -position.margin;
        }

        if (address(underlyingToken) == address(_weth)) {
            if (marginDelta < 0) {
                marginEngine.updatePositionMargin(
                    msg.sender,
                    tickLower,
                    tickUpper,
                    marginDelta
                );
            } else {
                if (marginDelta > 0) {
                    underlyingToken.safeTransferFrom(
                        msg.sender,
                        address(this),
                        marginDelta.toUint256()
                    );
                }

                if (msg.value > 0) {
                    _weth.deposit{value: msg.value}();
                    marginDelta += msg.value.toInt256();
                }

                uint256 allowance = underlyingToken.allowance(
                    address(this),
                    address(marginEngine)
                );

                underlyingToken.safeIncreaseAllowanceTo(
                    address(marginEngine),
                    marginDelta.toUint256()
                );

                marginEngine.updatePositionMargin(
                    msg.sender,
                    tickLower,
                    tickUpper,
                    marginDelta
                );
            }
        } else {
            if (marginDelta > 0) {
                underlyingToken.safeTransferFrom(
                    msg.sender,
                    address(this),
                    marginDelta.toUint256()
                );

                uint256 allowance = underlyingToken.allowance(
                    address(this),
                    address(marginEngine)
                );

                underlyingToken.safeIncreaseAllowanceTo(
                    address(marginEngine),
                    marginDelta.toUint256()
                );
            }
            marginEngine.updatePositionMargin(
                msg.sender,
                tickLower,
                tickUpper,
                marginDelta
            );
        }

        position = marginEngine.getPosition(msg.sender, tickLower, tickUpper);

        if (isAlpha && position._liquidity > 0) {
            accountLPMarginCap(
                vamm,
                encodedPosition,
                position.margin,
                true,
                true
            );
        }
    }

    /// @notice Add liquidity to an initialized pool
    function mintOrBurn(MintOrBurnParams memory params)
        public
        payable
        override
        returns (int256 positionMarginRequirement)
    {
        Tick.checkTicks(params.tickLower, params.tickUpper);

        IVAMM vamm = params.marginEngine.vamm();

        Position.Info memory position = params.marginEngine.getPosition(
            msg.sender,
            params.tickLower,
            params.tickUpper
        );

        bool isAlpha = params.marginEngine.isAlpha();
        bytes32 encodedPosition = keccak256(
            abi.encodePacked(
                msg.sender,
                address(vamm),
                address(params.marginEngine),
                params.tickLower,
                params.tickUpper
            )
        );

        bool isLPBefore = position._liquidity > 0;
        if (isAlpha && isLPBefore) {
            if (_lastAccountedMargin[encodedPosition] == 0) {
                _lastAccountedMargin[encodedPosition] = position.margin;
            }
        }

        IVAMM.VAMMVars memory v = vamm.vammVars();
        bool vammUnlocked = v.sqrtPriceX96 != 0;

        // get sqrt ratios

        uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(params.tickLower);
        uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(params.tickUpper);

        // initialize the vamm at midTick

        if (!vammUnlocked) {
            int24 midTick = (params.tickLower + params.tickUpper) / 2;
            uint160 sqrtRatioAtMidTickX96 = TickMath.getSqrtRatioAtTick(
                midTick
            );
            vamm.initializeVAMM(sqrtRatioAtMidTickX96);
        }

        if (params.marginDelta != 0 || msg.value > 0) {
            updatePositionMargin(
                params.marginEngine,
                params.tickLower,
                params.tickUpper,
                params.marginDelta,
                false // _fullyWithdraw
            );
        }

        // compute the liquidity amount for the amount of notional (amount1) specified

        uint128 liquidity = getLiquidityForNotional(
            sqrtRatioAX96,
            sqrtRatioBX96,
            params.notional
        );

        positionMarginRequirement = 0;
        if (params.isMint) {
            positionMarginRequirement = vamm.mint(
                msg.sender,
                params.tickLower,
                params.tickUpper,
                liquidity
            );
        } else {
            // invoke a burn
            positionMarginRequirement = vamm.burn(
                msg.sender,
                params.tickLower,
                params.tickUpper,
                liquidity
            );
        }

        position = params.marginEngine.getPosition(
            msg.sender,
            params.tickLower,
            params.tickUpper
        );

        bool isLPAfter = position._liquidity > 0;

        if (isAlpha && (isLPBefore || isLPAfter)) {
            accountLPMarginCap(
                vamm,
                encodedPosition,
                position.margin,
                isLPBefore,
                isLPAfter
            );
        }
    }

    function swap(SwapPeripheryParams memory params)
        public
        payable
        override
        returns (
            int256 _fixedTokenDelta,
            int256 _variableTokenDelta,
            uint256 _cumulativeFeeIncurred,
            int256 _fixedTokenDeltaUnbalanced,
            int256 _marginRequirement,
            int24 _tickAfter
        )
    {
        Tick.checkTicks(params.tickLower, params.tickUpper);

        IVAMM vamm = params.marginEngine.vamm();

        if ((params.tickLower == 0) && (params.tickUpper == 0)) {
            int24 tickSpacing = vamm.tickSpacing();
            IVAMM.VAMMVars memory v = vamm.vammVars();
            /// @dev assign default values to the upper and lower ticks

            int24 tickLower = v.tick - tickSpacing;
            int24 tickUpper = v.tick + tickSpacing;
            if (tickLower < TickMath.MIN_TICK) {
                tickLower = TickMath.MIN_TICK;
            }

            if (tickUpper > TickMath.MAX_TICK) {
                tickUpper = TickMath.MAX_TICK;
            }

            /// @audit add unit tests, checks of tickLower/tickUpper divisiblilty by tickSpacing
            params.tickLower = tickLower;
            params.tickUpper = tickUpper;
        }

        // if margin delta is positive, top up position margin

        if (params.marginDelta > 0 || msg.value > 0) {
            updatePositionMargin(
                params.marginEngine,
                params.tickLower,
                params.tickUpper,
                params.marginDelta.toInt256(),
                false // _fullyWithdraw
            );
        }

        int256 amountSpecified;

        if (params.isFT) {
            amountSpecified = params.notional.toInt256();
        } else {
            amountSpecified = -params.notional.toInt256();
        }

        IVAMM.SwapParams memory swapParams = IVAMM.SwapParams({
            recipient: msg.sender,
            amountSpecified: amountSpecified,
            sqrtPriceLimitX96: params.sqrtPriceLimitX96 == 0
                ? (
                    !params.isFT
                        ? TickMath.MIN_SQRT_RATIO + 1
                        : TickMath.MAX_SQRT_RATIO - 1
                )
                : params.sqrtPriceLimitX96,
            tickLower: params.tickLower,
            tickUpper: params.tickUpper
        });

        (
            _fixedTokenDelta,
            _variableTokenDelta,
            _cumulativeFeeIncurred,
            _fixedTokenDeltaUnbalanced,
            _marginRequirement
        ) = vamm.swap(swapParams);
        _tickAfter = vamm.vammVars().tick;
    }

    function rolloverWithMint(
        IMarginEngine marginEngine,
        address owner,
        int24 tickLower,
        int24 tickUpper,
        MintOrBurnParams memory paramsNewPosition
    ) external payable override returns (int256 newPositionMarginRequirement) {
        require(paramsNewPosition.isMint, "only mint");

        settlePositionAndWithdrawMargin(
            marginEngine,
            owner,
            tickLower,
            tickUpper
        );

        newPositionMarginRequirement = mintOrBurn(paramsNewPosition);
    }

    function rolloverWithSwap(
        IMarginEngine marginEngine,
        address owner,
        int24 tickLower,
        int24 tickUpper,
        SwapPeripheryParams memory paramsNewPosition
    )
        external
        payable
        override
        returns (
            int256 _fixedTokenDelta,
            int256 _variableTokenDelta,
            uint256 _cumulativeFeeIncurred,
            int256 _fixedTokenDeltaUnbalanced,
            int256 _marginRequirement,
            int24 _tickAfter
        )
    {
        settlePositionAndWithdrawMargin(
            marginEngine,
            owner,
            tickLower,
            tickUpper
        );

        (
            _fixedTokenDelta,
            _variableTokenDelta,
            _cumulativeFeeIncurred,
            _fixedTokenDeltaUnbalanced,
            _marginRequirement,
            _tickAfter
        ) = swap(paramsNewPosition);
    }

    function getCurrentTick(IMarginEngine marginEngine)
        external
        view
        override
        returns (int24 currentTick)
    {
        IVAMM vamm = marginEngine.vamm();
        currentTick = vamm.vammVars().tick;
    }
}