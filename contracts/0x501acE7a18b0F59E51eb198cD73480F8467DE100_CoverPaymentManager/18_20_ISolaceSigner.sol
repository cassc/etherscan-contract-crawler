// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;


/**
 * @title ISolaceSigner
 * @author solace.fi
 * @notice Verifies off-chain data.
*/
interface ISolaceSigner {

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when a signer is added.
    event SignerAdded(address signer);

    /// @notice Emitted when a signer is removed.
    event SignerRemoved(address signer);

    /***************************************
    VERIFY FUNCTIONS
    ***************************************/

    /**
     * @notice Verifies `SOLACE` price data.
     * @param token The token to verify price.
     * @param price The `SOLACE` price in wei(usd).
     * @param deadline The deadline for the price.
     * @param signature The `SOLACE` price signature.
     */
    function verifyPrice(address token, uint256 price, uint256 deadline, bytes calldata signature) external view returns (bool);

    /**
     * @notice Verifies cover premium data.
     * @param premium The premium amount to verify.
     * @param policyholder The policyholder address.
     * @param deadline The deadline for the signature.
     * @param signature The premium data signature.
     */
    function verifyPremium(uint256 premium, address policyholder, uint256 deadline, bytes calldata signature) external view returns (bool);

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice Returns the number of signers.
     * @return count The number of signers.
     */
    function numSigners() external returns (uint256 count);

    /**
     * @notice Returns the signer at the given index.
     * @param index The index to query.
     * @return signer The address of the signer.
     */
    function getSigner(uint256 index) external returns (address signer);

    /**
     * @notice Checks whether given signer is an authorized signer or not.
     * @param signer The signer address to check.
     * @return bool True if signer is a authorized signer.
     */
    function isSigner(address signer) external view returns (bool);

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Adds a new signer.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param signer The signer to add.
     */
    function addSigner(address signer) external;

    /**
     * @notice Removes a signer.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param signer The signer to remove.
     */
    function removeSigner(address signer) external;
}