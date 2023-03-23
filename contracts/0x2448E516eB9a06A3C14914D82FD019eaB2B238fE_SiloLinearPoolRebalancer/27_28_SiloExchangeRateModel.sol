// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@balancer-labs/v2-pool-utils/contracts/lib/ExternalCallLib.sol";
import "@balancer-labs/v2-solidity-utils/contracts/math/FixedPoint.sol";

import "./interfaces/IInterestRateModel.sol";
import "./interfaces/ISilo.sol";
import "./interfaces/ISiloRepository.sol";

// solhint-disable not-rely-on-time

// Created in order to decrease exchange rate timelag when wrapping and unwrapping tokens
// between Silo Linear Pools and the Silo Protocol.
contract SiloExchangeRateModel {
    using FixedPoint for uint256;

    function _calculateExchangeValue(ISilo silo, address underlyingAsset) internal view returns (uint256) {
        ISilo.AssetStorage memory state = _getAssetStorage(silo, underlyingAsset);
        ISilo.AssetInterestData memory interestData = _getInterestData(silo, underlyingAsset);
        uint256 lastTimestamp = interestData.interestRateTimestamp;

        uint256 totalDeposits = state.totalDeposits;
        uint256 totalShares = state.collateralToken.totalSupply();

        // If interest has not yet been accrued to storage in this block, calculate it manually.
        // We copy the core behavior of Silo's `_accrueInterest` function but without updating any storage:
        // https://github.com/silo-finance/silo-core-v1/blob/70621494b23d333e67442485d7c743ee6e7d22db/contracts/BaseSilo.sol#L666
        // solhint-disable-previous-line max-line-length
        if (lastTimestamp != block.timestamp) {
            uint256 rcomp = _getCompoundInterestRate(silo, underlyingAsset);
            uint256 protocolShareFee = _getProtocolShareFee(silo);

            uint256 protocolFeesCached = interestData.protocolFees;
            uint256 protocolShare;
            uint256 depositorsShare;

            uint256 accruedInterest = state.totalBorrowAmount.mulDown(rcomp);

            // Silo chooses to do a bunch of unchecked math here.
            // https://github.com/silo-finance/silo-core-v1/blob/70621494b23d333e67442485d7c743ee6e7d22db/contracts/BaseSilo.sol#L699
            // solhint-disable-previous-line max-line-length
            {
                protocolShare = (accruedInterest * protocolShareFee) / FixedPoint.ONE;

                // newProtocolFees = protocolFeesCached + protocolShare
                if (protocolFeesCached + protocolShare < protocolFeesCached) {
                    protocolShare = type(uint256).max - protocolFeesCached;
                }

                depositorsShare = accruedInterest - protocolShare;
            }

            totalDeposits = totalDeposits.add(depositorsShare);
        }

        // Note that the exchange rate returned by this function is always scaled to 18 decimals. All Silo ShareTokens
        // match their respective underlying assets' ERC20 decimals, and Silo uses 18-decimal precision for all
        // internal math including interest rates and fees. We match that behavior using the FixedPoint math library,
        // which will upscale the result of this division to 1e18 decimals.
        // solhint-disable max-line-length
        // token decimals: https://github.com/silo-finance/silo-core-v1/blob/70621494b23d333e67442485d7c743ee6e7d22db/contracts/utils/ShareToken.sol#L44
        // internal precision: https://github.com/silo-finance/silo-core-v1/blob/70621494b23d333e67442485d7c743ee6e7d22db/contracts/lib/Solvency.sol#L39
        // solhint-enable max-line-length
        return totalDeposits.divDown(totalShares);
    }

    function _getInterestData(ISilo silo, address mainTokenAddress)
        private
        view
        returns (ISilo.AssetInterestData memory)
    {
        try silo.interestData(mainTokenAddress) returns (ISilo.AssetInterestData memory interestData) {
            return interestData;
        } catch (bytes memory revertData) {
            // By maliciously reverting here, Aave (or any other contract in the call stack) could trick the Pool into
            // reporting invalid data to the query mechanism for swaps/joins/exits.
            // We then check the revert data to ensure this doesn't occur.
            ExternalCallLib.bubbleUpNonMaliciousRevert(revertData);
        }
    }

    function _getAssetStorage(ISilo silo, address mainTokenAddress) private view returns (ISilo.AssetStorage memory) {
        try silo.assetStorage(mainTokenAddress) returns (ISilo.AssetStorage memory assetStorage) {
            return assetStorage;
        } catch (bytes memory revertData) {
            // By maliciously reverting here, Aave (or any other contract in the call stack) could trick the Pool into
            // reporting invalid data to the query mechanism for swaps/joins/exits.
            // We then check the revert data to ensure this doesn't occur.
            ExternalCallLib.bubbleUpNonMaliciousRevert(revertData);
        }
    }

    function _getCompoundInterestRate(ISilo silo, address mainTokenAddress) private view returns (uint256) {
        IInterestRateModel siloModel = _getModel(silo, mainTokenAddress);
        // rcomp: compound interest rate from the last update until now
        // Use getCompoundInterestRate() instead of getCompoundInterestRateAndUpdate becasue we are operating within
        //      a view function and cannot manipute state
        try siloModel.getCompoundInterestRate(address(silo), mainTokenAddress, block.timestamp) returns (
            uint256 rcomp
        ) {
            return rcomp;
        } catch (bytes memory revertData) {
            // By maliciously reverting here, Aave (or any other contract in the call stack) could trick the Pool into
            // reporting invalid data to the query mechanism for swaps/joins/exits.
            // We then check the revert data to ensure this doesn't occur.
            ExternalCallLib.bubbleUpNonMaliciousRevert(revertData);
        }
    }

    function _getProtocolShareFee(ISilo silo) private view returns (uint256) {
        ISiloRepository repository = _getSiloRepository(silo);
        try repository.protocolShareFee() returns (uint256 protocolShareFee) {
            return protocolShareFee;
        } catch (bytes memory revertData) {
            // By maliciously reverting here, Aave (or any other contract in the call stack) could trick the Pool into
            // reporting invalid data to the query mechanism for swaps/joins/exits.
            // We then check the revert data to ensure this doesn't occur.
            ExternalCallLib.bubbleUpNonMaliciousRevert(revertData);
        }
    }

    // Gets the interest rate model for a given asset
    function _getModel(ISilo silo, address mainTokenAddress) private view returns (IInterestRateModel) {
        ISiloRepository repository = _getSiloRepository(silo);
        try repository.getInterestRateModel(address(silo), mainTokenAddress) returns (IInterestRateModel model) {
            return model;
        } catch (bytes memory revertData) {
            // By maliciously reverting here, Aave (or any other contract in the call stack) could trick the Pool into
            // reporting invalid data to the query mechanism for swaps/joins/exits.
            // We then check the revert data to ensure this doesn't occur.
            ExternalCallLib.bubbleUpNonMaliciousRevert(revertData);
        }
    }

    function _getSiloRepository(ISilo silo) private view returns (ISiloRepository) {
        try silo.siloRepository() returns (ISiloRepository repository) {
            return repository;
        } catch (bytes memory revertData) {
            // By maliciously reverting here, Aave (or any other contract in the call stack) could trick the Pool into
            // reporting invalid data to the query mechanism for swaps/joins/exits.
            // We then check the revert data to ensure this doesn't occur.
            ExternalCallLib.bubbleUpNonMaliciousRevert(revertData);
        }
    }

    function _convertWrappedToMain(
        ISilo silo,
        address mainToken,
        uint256 wrappedAmount
    ) internal view returns (uint256) {
        uint256 rate = _calculateExchangeValue(silo, mainToken);
        return wrappedAmount.mulDown(rate);
    }
}