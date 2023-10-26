/**
 *Submitted for verification at Etherscan.io on 2023-09-28
*/

pragma solidity 0.6.7;

abstract contract ChainlinkTWAPLike {
    function getResultWithValidity()
        external
        view
        virtual
        returns (uint256, bool);

    function chainlinkObservations(
        uint256
    ) external view virtual returns (uint256, uint256);

    function earliestObservationIndex() external view virtual returns (uint256);

    function lastUpdateTime() external view virtual returns (uint256);
}

abstract contract UniV3TWAPLike {
    function getTwapPrice(
        uint32,
        uint32
    ) external view virtual returns (uint256);
}

// Custom converter feed for two twaps (Chainlink + UniV3).
// Will fetch the twap on chainlink TWAP, fetch a TWAP from Uni V3 of the same length and return converted value.
contract ConverterFeed {
    // --- State ---
    // Base feed you want to convert into another currency. ie: (RAI/ETH)
    UniV3TWAPLike public immutable uniV3TWAP;
    // Feed user for conversion. (i.e: Using the example above and ETH/USD willoutput RAI price in USD)
    ChainlinkTWAPLike public immutable chainlinkTWAP;
    // Scalling factor to accomodate for different numbers of decimal places
    uint256 public immutable converterFeedScalingFactor;

    constructor(
        address uniV3TWAP_,
        address chainlinkTWAP_,
        uint256 scalingFactor
    ) public {
        require(uniV3TWAP_ != address(0), "ConverterFeed/null-uni-v3-twap");
        require(
            chainlinkTWAP_ != address(0),
            "ConverterFeed/null-chainlink-twap"
        );
        require(scalingFactor > 0, "ConverterFeed/invalid-scaling-factor");

        uniV3TWAP = UniV3TWAPLike(uniV3TWAP_);
        chainlinkTWAP = ChainlinkTWAPLike(chainlinkTWAP_);
        converterFeedScalingFactor = scalingFactor;
    }

    // --- SafeMath ---
    function subtract(uint x, uint y) public pure returns (uint z) {
        z = x - y;
        require(z <= x, "uint-uint-sub-underflow");
    }

    // --- General Utils --
    function both(bool x, bool y) private pure returns (bool z) {
        assembly {
            z := and(x, y)
        }
    }

    function either(bool x, bool y) internal pure returns (bool z) {
        assembly {
            z := or(x, y)
        }
    }

    // --- Math ---
    function multiply(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    // --- Getters ---
    /**
     * @notice Fetch the latest medianPrice (for maxWindow) or revert if is is null
     **/
    function read() external view returns (uint256) {
        (uint256 value, bool valid) = getResultWithValidity();
        require(valid, "ConverterFeed/invalid-price-feed");
        return value;
    }

    /**
     * @notice Fetch the latest medianPrice and whether it is null or not
     **/
    function getResultWithValidity()
        public
        view
        returns (uint256 value, bool valid)
    {
        (uint256 clValue, bool clValid) = chainlinkTWAP.getResultWithValidity();
        uint256 firstObservationIndex = chainlinkTWAP
            .earliestObservationIndex();

        (uint firstObservationTimestamp, ) = chainlinkTWAP
            .chainlinkObservations(subtract(firstObservationIndex, 1));

        uint lastObservationTimestamp = chainlinkTWAP.lastUpdateTime();

        uint256 uniValue;
        bool uniValid;
        try
            uniV3TWAP.getTwapPrice(
                uint32(block.timestamp - firstObservationTimestamp),
                uint32(block.timestamp - lastObservationTimestamp)
            )
        returns (uint256 uniValue_) {
            uniValue = uniValue_;
            uniValid = true;
        } catch {}
        value = multiply(clValue, uniValue) / converterFeedScalingFactor;
        valid = both(both(clValid, uniValid), value > 0);
    }
}