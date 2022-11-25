//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IAdminPanel
 * @author gotbit
 */

interface IAdminPanel {
    /// @dev Adds nft address to whitelist
    /// @param nft_ nft address to add to whitelist
    function addToWhitelist(address nft_) external;

    /// @dev Removes nft adderess from whitelist
    /// @param nft_ nft address to be removed from whitelist
    function removeFromWhitelist(address nft_) external;

    /// @dev Allows to know does nft address belongs to whitelist or not
    /// @param nft_ nft address to check inside whitelist
    /// @return doesBelongsToWhitelist ture if address belongs to whitelist, false if not
    function belongsToWhitelist(address nft_) external view returns (bool);

    /// @dev Adds token to whitelist
    /// @param newToken token address to be added
    function addToken(address newToken) external;

    /// @dev Removes token from whitelist
    /// @param token token addres to be removed
    function removeToken(address token) external;

    /// @dev Allows to know token address belongs to token whitelist
    /// @param token token address to check inside whitelist
    /// @return doesBelongToTokenWhitelist is true when you can buy or sell with this token
    function validTokens(address token) external view returns (bool);

    /// @dev Allows to get fee reveiver address
    /// @return feeAddress address who receives fee
    function feeAddress() external view returns (address);

    /// @dev Allows to get fee amount x 1000
    /// @return feeX1000 fee amount muled on 1000
    function feeX1000() external view returns (uint256);

    /// @dev Allows admin to grant selected address a fee setter role
    /// @param newFeeSetter is address who can set fee amount and fee address
    function grantFeeSetterRole(address newFeeSetter) external;

    /// @dev Allows admin to grant selected address a whitelist setter role
    /// @param newWhitelistSetter is address who can add/remove payable
    /// tokens and nft's addresses to/from whitelist
    function grantWhitelistSetterRole(address newWhitelistSetter) external;

    /// @dev Allows admin to revoke fee setter from role selected address
    /// @param feeSetter is address who could not set fee amount and fee address
    function revokeFeeSetterRole(address feeSetter) external;

    /// @dev Allows admin to revoke a whitelist setter role from selected address
    /// @param whitelistSetter is address who could not add/remove payable
    /// tokens and nft's addresses to/from whitelist
    function revokeWhitelistSetterRole(address whitelistSetter) external;

    /// @dev Allows to get all tokens existing in whitelist
    /// @return addresses array of all whitelisted tokens adresses
    function getTokensList() external view returns (address[] memory);

    /// @dev Allows to get all nfts existing in whitelist
    /// @return addresses array of all whitelisted nfts addresses
    function getNFTsList() external view returns (address[] memory);
}