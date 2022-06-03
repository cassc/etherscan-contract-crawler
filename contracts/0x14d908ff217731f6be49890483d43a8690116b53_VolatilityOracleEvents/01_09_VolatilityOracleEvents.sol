// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

import "./interfaces/IVolatilityOracle.sol";

contract VolatilityOracleEvents {
    /**
     * @notice Emitted every time IV is estimated through this helper contract
     * @param IV The estimated volatility, scaled by 1e18
     */
    event Estimated24H(uint256 IV);

    /// @notice The underlying volatility oracle
    IVolatilityOracle public immutable volatilityOracle;

    constructor(IVolatilityOracle _volatilityOracle) {
        volatilityOracle = _volatilityOracle;
    }

    /**
     * @notice Estimates 24-hour implied volatility for a Uniswap pool.
     * @param pool The pool to use for volatility estimate
     * @return IV The estimated volatility, scaled by 1e18. Also emitted in an event.
     */
    function estimate24H(IUniswapV3Pool pool) external returns (uint256 IV) {
        IV = volatilityOracle.estimate24H(pool);
        emit Estimated24H(IV);
    }

    fallback() external {
        address implementation = address(volatilityOracle);

        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}