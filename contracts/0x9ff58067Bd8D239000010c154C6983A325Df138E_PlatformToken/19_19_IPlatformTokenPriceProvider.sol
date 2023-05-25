// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

/**
 * @title Interface from which all implementations of pricing should inherit
 */
interface IPlatformTokenPriceProvider {
    /**
     * @notice Returns the cost of the entered number of PROPC in USD
     * @param prop number of PROP (1 PROP == 10^18)
     * @return usdAmount number of USD (1 USD == 10^18)
     */
    function usdAmount(uint256 prop) external view returns (uint256);

    /**
     * @notice Returns the cost of the entered number of USD in PROP
     * @param usd number of USD (1 USD == 10^18)
     * @return tokenAmount number of PROP (1 PROP == 10^18)
     */
    function tokenAmount(uint256 usd) external view returns (uint256);
}