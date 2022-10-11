// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IAggregatorV3Interface.sol";
import "../interfaces/IUniswapV2Oracle.sol";

contract JPEGOraclesAggregator is Ownable {
    error Unauthorized();
    error InvalidOracleResults();
    error ZeroAddress();

    IUniswapV2Oracle public jpegOracle;

    mapping(address => IAggregatorV3Interface) public floorMap;

    constructor(IUniswapV2Oracle _jpegOracle) {
        if (address(_jpegOracle) == address(0))
            revert ZeroAddress();

        jpegOracle = _jpegOracle;
    }

    /// @notice Can only be called by whitelisted addresses.
    /// @return The floor value for the collection, in ETH.
    function getFloorETH() external view returns (uint256) {
        IAggregatorV3Interface aggregator = floorMap[msg.sender];
        if (address(aggregator) == address(0))
            revert Unauthorized();

        return _normalizeAggregatorAnswer(aggregator);
    }

    /// @notice Updates (if necessary) and returns the current JPEG/ETH price
    /// @return result The current JPEG/ETH price
    function consultJPEGPriceETH(address _token) external returns (uint256 result) {
        result = jpegOracle.consultAndUpdateIfNecessary(_token, 1 ether);
        if (result == 0) revert InvalidOracleResults();
    }

    /// @notice Allows the owner to whitelist addresses for the getFloorETH function
    function addFloorOracle(IAggregatorV3Interface _oracle, address _vault) external onlyOwner {
        if (address(_vault) == address(0))
            revert ZeroAddress();
        floorMap[_vault] = _oracle;
    }

    /// @dev Fetches and converts to 18 decimals precision the latest answer of a Chainlink aggregator
    /// @param aggregator The aggregator to fetch the answer from
    /// @return The latest aggregator answer, normalized
    function _normalizeAggregatorAnswer(IAggregatorV3Interface aggregator)
        internal
        view
        returns (uint256)
    {
        (, int256 answer, , uint256 timestamp, ) = aggregator.latestRoundData();

        if (answer == 0 || timestamp == 0) revert InvalidOracleResults();

        uint8 decimals = aggregator.decimals();

        unchecked {
            //converts the answer to have 18 decimals
            return
                decimals > 18
                    ? uint256(answer) / 10**(decimals - 18)
                    : uint256(answer) * 10**(18 - decimals);
        }
    }
}