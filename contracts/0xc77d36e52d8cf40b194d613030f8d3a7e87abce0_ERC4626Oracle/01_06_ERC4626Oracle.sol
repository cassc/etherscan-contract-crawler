// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {AggregatorV3Interface} from "../interfaces/chainlink/AggregatorV3Interface.sol";
import {OracleErrors} from "../libraries/Errors.sol";

contract ERC4626Oracle is AggregatorV3Interface {
    IERC4626 public immutable token;
    uint8 public immutable tokenDecimals;

    AggregatorV3Interface public immutable assetOracle;
    uint256 public immutable version = 3;

    string private _description;

    constructor(string memory description_, address _assetOracle, address _token) {
        if (_assetOracle == address(0) || _token == address(0)) {
            revert OracleErrors.CANNOT_SET_TO_ADDRESS_ZERO();
        }
        if (bytes(description_).length == 0) {
            revert OracleErrors.CANNOT_SET_TO_EMPTY_STRING();
        }

        _description = description_;
        assetOracle = AggregatorV3Interface(_assetOracle);
        token = IERC4626(_token);
        tokenDecimals = token.decimals();
    }

    /**
     * @notice Get price of one token expressed in asset.
     */
    function latestRoundData() external view override returns (uint80, int256, uint256, uint256, uint80) {
        (uint80 roundId, int256 assetPrice, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            assetOracle.latestRoundData();

        if (assetPrice < 0) {
            revert OracleErrors.ORACLE_DATA_CANNOT_BE_LESS_THAN_ZERO();
        }

        return (
            roundId,
            int256(token.convertToAssets(10 ** tokenDecimals)) * assetPrice / int256(10 ** tokenDecimals),
            startedAt,
            updatedAt,
            answeredInRound
        );
    }

    /**
     * @notice Get price of one token expressed in asset.
     * @dev This function might not be supported by all oracles such as USK/USD KIBTAggregator, hence the use of try catch.
     */
    function getRoundData(uint80 _roundId) external view override returns (uint80, int256, uint256, uint256, uint80) {
        try assetOracle.getRoundData(_roundId) returns (
            uint80 roundId, int256 assetPrice, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound
        ) {
            if (assetPrice < 0) {
                revert OracleErrors.ORACLE_DATA_CANNOT_BE_LESS_THAN_ZERO();
            }

            return (
                roundId,
                int256(token.convertToAssets(10 ** tokenDecimals)) * assetPrice / int256(10 ** tokenDecimals),
                startedAt,
                updatedAt,
                answeredInRound
            );
        } catch {
            revert OracleErrors.GET_ROUND_DATA_NOT_SUPPORTED();
        }
    }

    /**
     * @notice Get description of oracle.
     */
    function description() external view override returns (string memory) {
        return _description;
    }

    /**
     * Returns the decimals that answers are formatted in. This should the the same as the decimals of the rebase Token itself
     */
    function decimals() external view returns (uint8) {
        return tokenDecimals;
    }
}