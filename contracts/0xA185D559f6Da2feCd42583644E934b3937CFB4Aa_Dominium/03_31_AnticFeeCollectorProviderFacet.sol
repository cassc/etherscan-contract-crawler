//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IAnticFeeCollectorProvider} from "../interfaces/IAnticFeeCollectorProvider.sol";
import {LibAnticFeeCollectorProvider} from "../libraries/LibAnticFeeCollectorProvider.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";

/// @title Antic fee collector address provider facet
/// @author Amit Molek
/// @dev Please see `IAnticFeeCollectorProvider` for docs.
contract AnticFeeCollectorProviderFacet is IAnticFeeCollectorProvider {
    function transferAnticFeeCollector(address newCollector) external override {
        LibDiamond.enforceIsContractOwner();
        LibAnticFeeCollectorProvider._transferAnticFeeCollector(newCollector);
    }

    function changeAnticFee(uint16 newJoinFee, uint16 newSellFee)
        external
        override
    {
        LibDiamond.enforceIsContractOwner();
        LibAnticFeeCollectorProvider._changeAnticFee(newJoinFee, newSellFee);
    }

    function anticFeeCollector() external view override returns (address) {
        return LibAnticFeeCollectorProvider._anticFeeCollector();
    }

    function anticFees()
        external
        view
        override
        returns (uint16 joinFee, uint16 sellFee)
    {
        (joinFee, sellFee) = LibAnticFeeCollectorProvider._anticFees();
    }
}