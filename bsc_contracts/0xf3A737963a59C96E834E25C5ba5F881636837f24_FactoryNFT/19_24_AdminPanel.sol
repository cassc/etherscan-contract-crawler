//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title AdminPanel
 * @author gotbit
 */

import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import './interfaces/IAdminPanel.sol';

contract AdminPanel is IAdminPanel, Initializable, AccessControlUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant FEESETTER_ROLE = keccak256('FEESETTER');
    bytes32 public constant WHITELISTSETTER_ROLE = keccak256('WHITELISTSETTER');

    EnumerableSet.AddressSet private NFTs;
    EnumerableSet.AddressSet private _validTokens;

    uint256 public feeX1000;
    address public feeAddress;

    event AddedToWhitelist(uint256 indexed timestamp, address nft);
    event RemovedFromWhitelist(uint256 indexed timestamp, address nft);

    function init(
        address weth,
        address feeAddress_,
        uint256 feeX1000_
    ) public initializer {
        _validTokens.add(weth);
        feeAddress = feeAddress_;
        feeX1000 = feeX1000_;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        __AccessControl_init();
    }

    /// @dev Adds nft address to whitelist
    /// @param nft_ nft address to add to whitelist
    function addToWhitelist(address nft_) external onlyRole(WHITELISTSETTER_ROLE) {
        require(!NFTs.contains(nft_), 'Address already in whitelist');
        NFTs.add(nft_);
        emit AddedToWhitelist(block.timestamp, nft_);
    }

    /// @dev Removes nft adderess from whitelist
    /// @param nft_ nft address to be removed from whitelist
    function removeFromWhitelist(address nft_) external onlyRole(WHITELISTSETTER_ROLE) {
        require(NFTs.contains(nft_), 'Address does not exist in whitelist');
        NFTs.remove(nft_);
        emit RemovedFromWhitelist(block.timestamp, nft_);
    }

    /// @dev Allows to know does nft address belongs to whitelist or not
    /// @param nft_ nft address to check inside whitelist
    /// @return doesBelongsToWhitelist ture if address belongs to whitelist, false if not
    function belongsToWhitelist(address nft_) external view returns (bool) {
        return NFTs.contains(nft_);
    }

    /// @dev Adds token to whitelist
    /// @param newToken token address to be added
    function addToken(address newToken) external onlyRole(WHITELISTSETTER_ROLE) {
        _validTokens.add(newToken);
    }

    /// @dev Removes token from whitelist
    /// @param token token addres to be removed
    function removeToken(address token) external onlyRole(WHITELISTSETTER_ROLE) {
        _validTokens.remove(token);
    }

    /// @dev Allows to know token address belongs to token whitelist
    /// @param token token address to check inside whitelist
    /// @return doesBelongToTokenWhitelist is true when you can buy or sell with this token
    function validTokens(address token) external view returns (bool) {
        return _validTokens.contains(token);
    }

    /// @dev Allows to get all tokens existing in whitelist
    /// @return addresses array of all whitelisted tokens adresses
    function getTokensList() external view returns (address[] memory) {
        return _validTokens.values();
    }

    /// @dev Allows to get all nfts existing in whitelist
    /// @return addresses array of all whitelisted nfts addresses
    function getNFTsList() external view returns (address[] memory) {
        return NFTs.values();
    }

    /// @dev Sets new fee amount
    /// @param newFeeX1000 new fee amount
    function setFee(uint256 newFeeX1000) external onlyRole(FEESETTER_ROLE) {
        feeX1000 = newFeeX1000;
    }

    /// @dev Sets new fee address
    /// @param newFeeAddress new fee address to set
    function setFeeAddress(address newFeeAddress) external onlyRole(FEESETTER_ROLE) {
        feeAddress = newFeeAddress;
    }

    /// @dev Allows admin to grant selected address a fee setter role
    /// @param newFeeSetter is address who can set fee amount and fee address
    function grantFeeSetterRole(address newFeeSetter)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _grantRole(FEESETTER_ROLE, newFeeSetter);
    }

    /// @dev Allows admin to grant selected address a whitelist setter role
    /// @param newWhitelistSetter is address who can add/remove payable
    /// tokens and nft's addresses to/from whitelist
    function grantWhitelistSetterRole(address newWhitelistSetter)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _grantRole(WHITELISTSETTER_ROLE, newWhitelistSetter);
    }

    /// @dev Allows admin to revoke fee setter from role selected address
    /// @param feeSetter is address who could not set fee amount and fee address
    function revokeFeeSetterRole(address feeSetter)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _revokeRole(FEESETTER_ROLE, feeSetter);
    }

    /// @dev Allows admin to revoke a whitelist setter role from selected address
    /// @param whitelistSetter is address who could not add/remove payable
    /// tokens and nft's addresses to/from whitelist
    function revokeWhitelistSetterRole(address whitelistSetter)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _revokeRole(WHITELISTSETTER_ROLE, whitelistSetter);
    }
}