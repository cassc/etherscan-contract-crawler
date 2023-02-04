//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SignedMath.sol";

import "./interfaces/IFeeModel.sol";
import "./libraries/CodecLib.sol";
import "./libraries/StorageLib.sol";
import "./libraries/TransferLib.sol";

/// @dev This set of methods process the result of an execution, update the internal accounting and transfer funds if required
library ExecutionProcessorLib {
    using SafeCast for uint256;
    using Math for uint256;
    using SignedMath for int256;
    using TransferLib for ERC20;
    using CodecLib for uint256;

    event PositionUpserted(
        Symbol indexed symbol,
        address indexed trader,
        PositionId indexed positionId,
        uint256 openQuantity,
        uint256 openCost,
        int256 collateral,
        uint256 totalFees,
        uint256 txFees,
        int256 realisedPnL
    );

    event PositionLiquidated(
        Symbol indexed symbol,
        address indexed trader,
        PositionId indexed positionId,
        uint256 openQuantity,
        uint256 openCost,
        int256 collateral,
        int256 realisedPnL
    );

    event PositionClosed(
        Symbol indexed symbol,
        address indexed trader,
        PositionId indexed positionId,
        uint256 closedQuantity,
        uint256 closedCost,
        int256 collateral,
        uint256 totalFees,
        uint256 txFees,
        int256 realisedPnL
    );

    event PositionDelivered(
        Symbol indexed symbol,
        address indexed trader,
        PositionId indexed positionId,
        address to,
        uint256 deliveredQuantity,
        uint256 deliveryCost,
        uint256 totalFees
    );

    error Undercollateralised(PositionId positionId);
    error PositionIsTooSmall(uint256 openCost, uint256 minCost);

    uint256 public constant MIN_DEBT_MULTIPLIER = 5;

    function deliverPosition(
        Symbol symbol,
        PositionId positionId,
        address trader,
        uint256 deliverableQuantity,
        uint256 deliveryCost,
        address payer,
        ERC20 quoteToken,
        address to
    ) internal {
        delete StorageLib.getPositionNotionals()[positionId];

        mapping(PositionId => uint256) storage balances = StorageLib.getPositionBalances();
        (, uint256 protocolFees) = balances[positionId].decodeU128();
        delete balances[positionId];

        if (protocolFees > 0) {
            quoteToken.transferOut(payer, ConfigStorageLib.getTreasury(), protocolFees);
        }

        emit PositionDelivered(symbol, trader, positionId, to, deliverableQuantity, deliveryCost, protocolFees);
    }

    function updateCollateral(Symbol symbol, PositionId positionId, address trader, int256 cost, int256 amount)
        internal
    {
        (uint256 openQuantity, uint256 openCost) = StorageLib.getPositionNotionals()[positionId].decodeU128();
        (int256 collateral, uint256 protocolFees, uint256 fee) =
            _applyFees(trader, symbol, positionId, cost.abs() + amount.abs());

        openCost = uint256(int256(openCost) + cost);
        collateral = collateral + amount;

        _updatePosition(symbol, positionId, trader, openQuantity, openCost, collateral, protocolFees, fee, 0);
    }

    function increasePosition(
        Symbol symbol,
        PositionId positionId,
        address trader,
        uint256 size,
        uint256 cost,
        int256 collateralDelta,
        ERC20 quoteToken,
        address to,
        uint256 minCost
    ) internal {
        (uint256 openQuantity, uint256 openCost) = StorageLib.getPositionNotionals()[positionId].decodeU128();
        int256 positionCollateral;
        uint256 protocolFees;
        uint256 fee;

        // For a new position
        if (openQuantity == 0) {
            fee = _fee(trader, symbol, positionId, cost);
            positionCollateral = collateralDelta - int256(fee);
            protocolFees = fee;
        } else {
            (positionCollateral, protocolFees, fee) = _applyFees(trader, symbol, positionId, cost);
            positionCollateral = positionCollateral + collateralDelta;

            // When increasing positions, the user can request to withdraw part (or all) the free collateral
            if (collateralDelta < 0 && address(this) != to) {
                quoteToken.transferOut(address(this), to, uint256(-collateralDelta));
            }
        }

        openCost = openCost + cost;
        _validateMinCost(openCost, minCost);
        openQuantity = openQuantity + size;

        _updatePosition(symbol, positionId, trader, openQuantity, openCost, positionCollateral, protocolFees, fee, 0);
    }

    function decreasePosition(
        Symbol symbol,
        PositionId positionId,
        address trader,
        uint256 size,
        uint256 cost,
        int256 collateralDelta,
        ERC20 quoteToken,
        address to,
        uint256 minCost
    ) internal {
        (uint256 openQuantity, uint256 openCost) = StorageLib.getPositionNotionals()[positionId].decodeU128();
        (int256 collateral, uint256 protocolFees, uint256 fee) = _applyFees(trader, symbol, positionId, cost);

        int256 pnl;
        {
            // Proportion of the openCost based on the size of the fill respective of the overall position size
            uint256 closedCost = (size * openCost).ceilDiv(openQuantity);
            pnl = int256(cost) - int256(closedCost);
            openCost = openCost - closedCost;
            _validateMinCost(openCost, minCost);
            openQuantity = openQuantity - size;

            // Crystallised PnL is accounted on the collateral
            collateral = collateral + pnl + collateralDelta;
        }

        // When decreasing positions, the user can request to withdraw part (or all) the proceedings
        if (collateralDelta < 0 && address(this) != to) {
            quoteToken.transferOut(address(this), to, uint256(-collateralDelta));
        }

        _updatePosition(symbol, positionId, trader, openQuantity, openCost, collateral, protocolFees, fee, pnl);
    }

    function closePosition(
        Symbol symbol,
        PositionId positionId,
        address trader,
        uint256 cost,
        ERC20 quoteToken,
        address to
    ) internal {
        mapping(PositionId => uint256) storage notionals = StorageLib.getPositionNotionals();
        (uint256 openQuantity, uint256 openCost) = notionals[positionId].decodeU128();
        (int256 collateral, uint256 protocolFees, uint256 fee) = _applyFees(trader, symbol, positionId, cost);

        int256 pnl = int256(cost) - int256(openCost);

        // Crystallised PnL is accounted on the collateral
        collateral = collateral + pnl;

        delete notionals[positionId];
        delete StorageLib.getPositionBalances()[positionId];

        if (protocolFees > 0) {
            quoteToken.transferOut(address(this), ConfigStorageLib.getTreasury(), protocolFees);
        }
        if (collateral > 0 && to != address(this)) {
            quoteToken.transferOut(address(this), to, uint256(collateral));
        }

        emit PositionClosed(symbol, trader, positionId, openQuantity, openCost, collateral, protocolFees, fee, pnl);
    }

    function liquidatePosition(Symbol symbol, PositionId positionId, address trader, uint256 size, uint256 cost)
        internal
    {
        mapping(PositionId => uint256) storage notionals = StorageLib.getPositionNotionals();
        mapping(PositionId => uint256) storage balances = StorageLib.getPositionBalances();
        (uint256 openQuantity, uint256 openCost) = notionals[positionId].decodeU128();
        (int256 collateral, int256 protocolFees) = balances[positionId].decodeI128();

        // Proportion of the openCost based on the size of the fill respective of the overall position size
        uint256 closedCost = size == openQuantity ? openCost : (size * openCost).ceilDiv(openQuantity);
        int256 pnl = int256(cost) - int256(closedCost);
        openCost = openCost - closedCost;
        openQuantity = openQuantity - size;

        // Crystallised PnL is accounted on the collateral
        collateral = collateral + pnl;

        notionals[positionId] = CodecLib.encodeU128(openQuantity, openCost);
        balances[positionId] = CodecLib.encodeI128(collateral, protocolFees);
        emit PositionLiquidated(symbol, trader, positionId, openQuantity, openCost, collateral, pnl);
    }

    // ============= Private functions ================

    function _applyFees(address trader, Symbol symbol, PositionId positionId, uint256 cost)
        private
        view
        returns (int256 collateral, uint256 protocolFees, uint256 fee)
    {
        int256 iProtocolFees;
        (collateral, iProtocolFees) = StorageLib.getPositionBalances()[positionId].decodeI128();
        protocolFees = uint256(iProtocolFees);
        fee = _fee(trader, symbol, positionId, cost);
        if (fee > 0) {
            collateral = collateral - int256(fee);
            protocolFees = protocolFees + fee;
        }
    }

    function _fee(address trader, Symbol symbol, PositionId positionId, uint256 cost) private view returns (uint256) {
        IFeeModel feeModel = StorageLib.getInstrumentFeeModel()[symbol];
        return address(feeModel) != address(0) ? feeModel.calculateFee(trader, positionId, cost) : 0;
    }

    function _updatePosition(
        Symbol symbol,
        PositionId positionId,
        address trader,
        uint256 openQuantity,
        uint256 openCost,
        int256 collateral,
        uint256 protocolFees,
        uint256 fee,
        int256 pnl
    ) private {
        StorageLib.getPositionNotionals()[positionId] = CodecLib.encodeU128(openQuantity, openCost);
        StorageLib.getPositionBalances()[positionId] = CodecLib.encodeI128(collateral, int256(protocolFees));
        emit PositionUpserted(symbol, trader, positionId, openQuantity, openCost, collateral, protocolFees, fee, pnl);
    }

    function _validateMinCost(uint256 openCost, uint256 minCost) private pure {
        if (openCost < minCost * MIN_DEBT_MULTIPLIER) {
            revert PositionIsTooSmall(openCost, minCost * MIN_DEBT_MULTIPLIER);
        }
    }
}