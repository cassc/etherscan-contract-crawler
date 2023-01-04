// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IBasePriceOracle.sol";
import "./interfaces/IOracleManager.sol";

/**
 * @title OracleManager
 * @author LombardFi
 * @notice The Oracle Manager stores oracle implementations.
 * @dev External contracts can call `getPrice` to get the price of an asset.
 */
contract OracleManager is IOracleManager, Ownable {
    /**
     * @notice Active oracle implementations.
     * @dev Stored in priority order.
     */
    IBasePriceOracle[] public oracles;

    /**
     * @notice The number of active oracle implementations.
     */
    uint256 public numOracles;

    /**
     * @notice The ERC20 in which the price is quoted.
     */
    address public immutable quoteAsset;

    /**
     * @notice The minimum number of supported oracles.
     */
    uint256 public constant MIN_SUPPORTED_ORACLES = 1;

    /**
     * @notice The maximum number of supported oracles.
     */
    uint256 public constant MAX_SUPPORTED_ORACLES = 10;

    /**
     * @notice Sets the ERC20 in which the price is quoted.
     * @param _quoteAsset the address of the quote token.
     */
    constructor(address _quoteAsset) {
        require(
            _quoteAsset != address(0),
            "OracleManager::invalid quote asset"
        );
        quoteAsset = _quoteAsset;
    }

    /**
     * @notice Returns the price of the asset quoted in terms of the base asset.
     * @dev Iterates through `oracles` in order, and calls `IBasePriceOracle.getPrice()` if the oracle supports the asset.
     * Reverts if no oracle supports by asset.
     * @param _asset the address of the asset to quote.
     * @return The price of the asset in wad.
     */
    function getPrice(address _asset) external view returns (uint256) {
        // Base case
        address _quoteAsset = quoteAsset;
        if (_asset == _quoteAsset) {
            return 1e18;
        }

        // Iterate oracles ranked by priority
        uint256 _numOracles = numOracles;
        for (uint256 i = 0; i < _numOracles; ) {
            IBasePriceOracle oracle = oracles[i];

            // If the implementation supports the asset, use the oracle to get the price
            if (oracle.supportsAsset(_asset, _quoteAsset)) {
                (bool success, uint256 price) = oracle.getPrice(
                    _asset,
                    _quoteAsset
                );

                if (success) {
                    return price;
                }
            }

            unchecked {
                ++i;
            }
        }
        // If no oracle supports the asset, revert
        revert("OracleManager::not supported");
    }

    /**
     * @notice Sets the oracle implementations.
     * @dev First it zeroes out the `oracles` array in storage.
     * It copies elements from `_oracles` then updates `numOracles`.
     * 10 >= number of oracles > 0.
     * Can be called only by the owner.
     * @param _oracles an array of `IBasePriceOracle` implementations.
     */
    function setOracles(IBasePriceOracle[] memory _oracles) external onlyOwner {
        uint256 updatedNumOracles = _oracles.length;
        require(
            updatedNumOracles >= MIN_SUPPORTED_ORACLES,
            "OracleManager::too few oracles"
        );
        require(
            updatedNumOracles <= MAX_SUPPORTED_ORACLES,
            "OracleManager::too many oracles"
        );

        // Delete old storage
        // This loop is not required but is good for data sanity
        uint256 oldNumOracles = numOracles;
        for (uint256 i = 0; i < oldNumOracles; ) {
            // `pop()` removes the element and decrements the length
            oracles.pop();

            unchecked {
                ++i;
            }
        }

        // Now that the entire `oracles` array is zeroed out
        // Write the new implementations
        for (uint256 i = 0; i < updatedNumOracles; ) {
            require(
                address(_oracles[i]) != address(0),
                "OracleManager::zero address"
            );
            oracles.push(_oracles[i]);

            unchecked {
                ++i;
            }
        }

        // Update the number of oracles.
        numOracles = updatedNumOracles;

        emit SetOracles(msg.sender, _oracles);
    }

    /**
     * @notice Retrieves the oracle implementations.
     * @dev Used for off-chain data retrieval.
     * @return _oracles The current active oracle implementations in iteration order.
     */
    function getOracles()
        external
        view
        returns (IBasePriceOracle[] memory _oracles)
    {
        return oracles;
    }
}