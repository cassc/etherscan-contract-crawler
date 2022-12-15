// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

interface IXAsset {

    function getBaseToken() external view returns (address);

    /**
     * @dev Invest an amount of X-BASE-TOKEN in different assets.
     */
    function invest(address token, uint256 amount)
        external
        returns (uint256);

    /**
     * @dev Withdraws a number of shares from the XASSET
     */
    function withdraw(uint256 amount) external returns (uint256);

    /**
     * @dev Withdraws a number of shares from the XASSET
     */
    function withdrawFrom(address owner, uint256 shares) external returns (uint256);

    /**
     * @param amount - The amount of shares to calculate the value of
     * @return The value of amount shares in baseToken
     */
    function getValueForShares(uint256 amount) external view returns (uint256);

    /**
     * @return The price per one share of the XASSET
     */
    function getSharePrice() external view returns (uint256);

    /**
     * @return Returns the total amount of baseTokens that are invested in this XASSET
     */
    function getTVL() external view returns (uint256);

    /**
     * @return Total shares owned by address in this xAsset
     */
    function getTotalSharesOwnedBy(address account)
        external
        view
        returns (uint256);

    /**
     * @return Total value invested by address in this xAsset, in baseToken
     */
    function getTotalValueOwnedBy(address account)
        external
        view
        returns (uint256);

    /**
     * @return The token that keeps track of the shares of this XASSET
     */
    function shareToken() external view returns (address);
}