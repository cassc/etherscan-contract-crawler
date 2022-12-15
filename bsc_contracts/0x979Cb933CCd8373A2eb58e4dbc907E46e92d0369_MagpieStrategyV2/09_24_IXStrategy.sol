// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IXStrategy {

    /**
     * @dev Convert amount of token to baseToken
     */
    function convert(address token, uint256 amount) view external returns (uint256);

    /**
     * @dev Returns baseToken amount of all assets owned by the XAsset
     */
    function getTotalAssetValue() external view returns (uint256);

    /**
     * @dev Invests and returns the amount invested, in baseTokens
     */
    function invest(
        address token,
        uint256 amount,
        uint256 minAmount
    ) external returns (uint256);

    /**
     * @dev Calculates the right amount of assets to convert for the amount of baseTokens
     * @return The number of baseToken converted so the xAsset should burn the shares
     */
    function withdraw(
        uint256 amount,
        uint256 minAmount
    ) external returns (uint256);

    /**
    * @dev Compounds the yield
    */
    function compound() external;

}