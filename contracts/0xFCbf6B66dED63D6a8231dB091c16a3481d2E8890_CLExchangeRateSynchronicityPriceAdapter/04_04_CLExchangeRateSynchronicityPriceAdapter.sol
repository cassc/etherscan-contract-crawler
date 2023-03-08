// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ICLSynchronicityPriceAdapter} from "../dependencies/chainlink/ICLSynchronicityPriceAdapter.sol";
import {IExchangeRate} from "../interfaces/IExchangeRate.sol";
import {SafeCast} from "../dependencies/openzeppelin/contracts/SafeCast.sol";

/**
 * @title CLExchangeRateSynchronicityPriceAdapter
 * @notice Price adapter to calculate price using exchange rate
 */
contract CLExchangeRateSynchronicityPriceAdapter is
    ICLSynchronicityPriceAdapter,
    IExchangeRate
{
    using SafeCast for uint256;

    /**
     * @notice asset which provides exchange rate
     */
    address public immutable ASSET;

    /**
     * @param asset the address of ASSET
     */
    constructor(address asset) {
        ASSET = asset;
    }

    function getExchangeRate() public view virtual returns (uint256) {
        return IExchangeRate(ASSET).getExchangeRate();
    }

    /// @inheritdoc ICLSynchronicityPriceAdapter
    function latestAnswer() public view virtual override returns (int256) {
        return getExchangeRate().toInt256();
    }
}