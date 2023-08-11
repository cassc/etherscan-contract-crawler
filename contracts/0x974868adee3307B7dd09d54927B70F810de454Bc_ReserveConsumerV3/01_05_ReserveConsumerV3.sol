// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./IReserveConsumerV3.sol";

contract ReserveConsumerV3 is Initializable, IReserveConsumerV3 {
    AggregatorV3Interface internal reserveFeed;

    function initialize(address _aggregatorInterface) external initializer {
        reserveFeed = AggregatorV3Interface(
            _aggregatorInterface
        );
    }

    function decimals() external view override returns (uint8) {
        return reserveFeed.decimals();
    }

    /**
     * Returns the latest reserve
     */
    function getLatestReserve() external view returns (int) {
        // prettier-ignore
        (
        /*uint80 roundID*/,
        int reserve,
        /*uint startedAt*/,
        /*uint timeStamp*/,
        /*uint80 answeredInRound*/
        ) = reserveFeed.latestRoundData();

        return reserve;
    }

}