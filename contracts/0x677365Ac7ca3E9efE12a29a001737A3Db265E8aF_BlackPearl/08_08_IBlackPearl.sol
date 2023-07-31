// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ISwellToken
 * @author https://github.com/max-taylor
 * @dev The interface for the Swell Token, which extends the IWhitelist and IERC20 interfaces and adds additional functions and events for controlling token transfers.
 */
interface IBlackPearl is IERC20 {
    // ***** Events ******

    /**
     * @dev Emitted when token transfers are enabled.
     */
    event TransfersEnabled();

    /**
     * @dev Emitted when token transfers are disabled.
     */
    event TransfersDisabled();

    /**
     * @dev Emitted when admin added
     * @param _address New admin address
     */
    event AdminAdded(address _address);

    /**
     * @dev Emitted when admin removed
     * @param _address Removed admin address
     */
    event AdminRemoved(address _address);

    /**
     * @dev Emitted when whitelist address added
     * @param _address New whitelist address
     */
    event WhitelistAdded(address _address);

    /**
     * @dev Emitted when whitelist address removed
     * @param _address Removed whitelist address
     */
    event WhitelistRemoved(address _address);

    /**
     * @dev Emitted when claim contract changed
     * @param _address Updated contract address
     */
    event SetClaimContract(address _address);

    // ***** Errors ******

    /**
     * @dev Throws if token transfers are disabled.
     */
    error TransferDisabled();

    /**
     * @dev Throws if not in whitelist.
     */
    error NotInWhitelist();

    /**
     * @dev Throws if not an admin.
     */
    error NotAdmin();

    /**
     * @dev Throws if not called by claim contract.
     */
    error NotClaimContract();

    // ************************************
    // ***** External Methods ******

    /**
     * @dev Checks whether token transfers are currently enabled.
     * @return A boolean indicating whether transfers are enabled.
     */
    function transfersEnabled() external returns (bool);

    /**
     * @dev Only the claim contract can burn the users tokens.
     * @return Current claim contract
     */
    function claimContract() external returns (address);

    /**
      * @dev Returns true if the address is in the whitelist, false otherwise.

      * @param _address The address to check.
        @return bool representing whether the address is in the whitelist.
    */
    function whitelistedAddresses(address _address) external returns (bool);

    /**
      * @dev Returns true if the address is in the admin list, false otherwise.

      * @param _address The address to check.
        @return bool representing whether the address is an admin.
    */
    function adminAddresses(address _address) external returns (bool);

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) external;

    /**
     * @dev Burns all tokens for address during claim.Can only by called by whitelisted caller.
     * @param _address The address to burn all tokens
     */
    function burnClaim(address _address) external;

    /**
     * @dev Enables token transfers
     */
    function enableTransfers() external;

    /**
     * @dev Disables token transfers
     */
    function disableTransfers() external;

    /**
     * @dev Adds addresses to the whitelist, reverts if not admin
     * @param _addresses The address list to add.
     */
    function addToWhitelist(address[] calldata _addresses) external;

    /**
     * @dev Removes addresses from the whitelist, reverts if not admin
     * @param _addresses The address list to remove.
     */
    function removeFromWhitelist(address[] calldata _addresses) external;

    /**
     * @dev Adds addresses to the admin list, reverts if not admin
     * @param _addresses The address list to add.
     */
    function addToAdminList(address[] calldata _addresses) external;

    /**
     * @dev Removes addresses from the admin list, reverts if not admin
     * @param _addresses The address list to remove.
     */
    function removeFromAdminList(address[] calldata _addresses) external;

    /**
     * @dev Changes the claim contract which can be used to burn tokens on claim, revets if not admin
     * @param _address New claim contract
     */
    function setClaimContract(address _address) external;
}