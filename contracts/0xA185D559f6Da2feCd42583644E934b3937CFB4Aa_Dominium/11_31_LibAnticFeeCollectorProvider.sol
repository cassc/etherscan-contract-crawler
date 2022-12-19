//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {StorageAnticFeeCollectorProvider} from "../storage/StorageAnticFeeCollectorProvider.sol";

/// @author Amit Molek
/// @dev Please see `IAnticFeeCollectorProvider` for docs
library LibAnticFeeCollectorProvider {
    event AnticFeeCollectorTransferred(
        address indexed previousCollector,
        address indexed newCollector
    );

    event AnticFeeChanged(
        uint16 oldJoinFee,
        uint16 newJoinFee,
        uint16 oldSellFee,
        uint16 newSellFee
    );

    function _transferAnticFeeCollector(address _newCollector) internal {
        require(
            _newCollector != address(0),
            "FeeCollector: Fee collector can't be zero address"
        );

        StorageAnticFeeCollectorProvider.DiamondStorage
            storage ds = StorageAnticFeeCollectorProvider.diamondStorage();

        require(
            _newCollector != ds.anticFeeCollector,
            "FeeCollector: Same collector"
        );

        emit AnticFeeCollectorTransferred(ds.anticFeeCollector, _newCollector);

        ds.anticFeeCollector = _newCollector;
    }

    function _changeAnticFee(uint16 newJoinFee, uint16 newSellFee) internal {
        StorageAnticFeeCollectorProvider.DiamondStorage
            storage ds = StorageAnticFeeCollectorProvider.diamondStorage();

        require(
            newJoinFee != ds.joinFeePercentage,
            "FeeCollector: Same join fee"
        );
        require(
            newSellFee != ds.sellFeePercentage,
            "FeeCollector: Same sell fee"
        );

        require(
            newJoinFee <=
                StorageAnticFeeCollectorProvider.MAX_ANTIC_FEE_PERCENTAGE,
            "FeeCollector: Invalid Antic join fee percentage"
        );

        require(
            newSellFee <=
                StorageAnticFeeCollectorProvider.MAX_ANTIC_FEE_PERCENTAGE,
            "FeeCollector: Invalid Antic sell/receive fee percentage"
        );

        emit AnticFeeChanged(
            ds.joinFeePercentage,
            newJoinFee,
            ds.sellFeePercentage,
            newSellFee
        );

        ds.joinFeePercentage = newJoinFee;
        ds.sellFeePercentage = newSellFee;
    }

    function _anticFeeCollector() internal view returns (address) {
        StorageAnticFeeCollectorProvider.DiamondStorage
            storage ds = StorageAnticFeeCollectorProvider.diamondStorage();

        return ds.anticFeeCollector;
    }

    function _anticFees()
        internal
        view
        returns (uint16 joinFee, uint16 sellFee)
    {
        StorageAnticFeeCollectorProvider.DiamondStorage
            storage ds = StorageAnticFeeCollectorProvider.diamondStorage();

        joinFee = ds.joinFeePercentage;
        sellFee = ds.sellFeePercentage;
    }
}