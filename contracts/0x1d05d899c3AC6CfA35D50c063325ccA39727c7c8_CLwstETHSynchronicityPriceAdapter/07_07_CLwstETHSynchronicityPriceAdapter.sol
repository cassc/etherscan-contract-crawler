// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IEACAggregatorProxy} from "../interfaces/IEACAggregatorProxy.sol";
import {ICLSynchronicityPriceAdapter} from "../dependencies/chainlink/ICLSynchronicityPriceAdapter.sol";
import {ILido} from "../interfaces/ILido.sol";
import {SafeCast} from "../dependencies/openzeppelin/contracts/SafeCast.sol";

/**
 * @title CLwstETHSynchronicityPriceAdapter
 * @author BGD Labs
 * @notice Price adapter to calculate price of (Asset / Base) pair by using
 * @notice Chainlink Data Feeds for (Asset / Peg) and (Peg / Base) pairs.
 * @notice For example it can be used to calculate wstETH / ETH
 * @notice based on wstETH / stETH and stETH / ETH  feeds.
 */
contract CLwstETHSynchronicityPriceAdapter is ICLSynchronicityPriceAdapter {
    using SafeCast for uint256;
    /**
     * @notice Price feed for (Base / Peg) pair
     */
    IEACAggregatorProxy public immutable PEG_TO_BASE;

    /**
     * @notice Price feed for (Asset / Peg) pair
     */
    ILido public immutable ASSET_TO_PEG;

    /**
     * @notice Number of decimals in the output of this price adapter
     */
    uint8 public immutable DECIMALS;

    /**
     * @notice This is a parameter to bring the resulting answer with the proper precision.
     * @notice will be equal to 10 to the power of the sum decimals of feeds
     */
    int256 public immutable DENOMINATOR;

    /**
     * @notice Maximum number of resulting and feed decimals
     */
    uint8 public constant MAX_DECIMALS = 18;

    /**
     * @param pegToBaseAggregatorAddress the address of PEG / BASE feed
     * @param assetToPegAggregatorAddress the address of the ASSET / PEG feed
     * @param decimals precision of the answer
     */
    constructor(
        address pegToBaseAggregatorAddress,
        address assetToPegAggregatorAddress,
        uint8 decimals
    ) {
        PEG_TO_BASE = IEACAggregatorProxy(pegToBaseAggregatorAddress);
        ASSET_TO_PEG = ILido(assetToPegAggregatorAddress);

        if (decimals > MAX_DECIMALS) revert DecimalsAboveLimit();
        if (PEG_TO_BASE.decimals() > MAX_DECIMALS) revert DecimalsAboveLimit();
        if (ASSET_TO_PEG.decimals() > MAX_DECIMALS) revert DecimalsAboveLimit();

        DECIMALS = decimals;

        // equal to 10 to the power of the sum decimals of feeds
        unchecked {
            DENOMINATOR = int256(
                10**(PEG_TO_BASE.decimals() + ASSET_TO_PEG.decimals())
            );
        }
    }

    /// @inheritdoc ICLSynchronicityPriceAdapter
    function latestAnswer() public view virtual override returns (int256) {
        int256 assetToPegPrice = ASSET_TO_PEG
            .getPooledEthByShares(10**ASSET_TO_PEG.decimals())
            .toInt256();
        int256 pegToBasePrice = PEG_TO_BASE.latestAnswer();

        if (assetToPegPrice <= 0 || pegToBasePrice <= 0) {
            return 0;
        }

        return
            (assetToPegPrice * pegToBasePrice * int256(10**DECIMALS)) /
            (DENOMINATOR);
    }
}