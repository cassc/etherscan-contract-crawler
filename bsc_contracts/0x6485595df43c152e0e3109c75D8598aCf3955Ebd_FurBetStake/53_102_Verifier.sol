// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./abstracts/BaseContract.sol";
// IMPORTS
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title Verifier
 * @author Steve Harmeyer <[email protected]>
 * @notice This contract is a generic verifier contract. This allows us
 * to verify that an address is approved for whatever by taking the address,
 * a salt integer, an expiration timestamp, and a signature and verifying
 * that the signer address actually created the signature with the provided
 * values. This can be used for presales, mints, etc.
 */
contract Verifier is BaseContract
{
    /**
     * Contract initializer.
     * @dev This intializes all the parent contracts.
     */
    function initialize() initializer public
    {
        __BaseContract_init();
    }

    /**
     * Signer.
     * @dev The signer address for address verification.
     */
    address private _signer;

    /**
     * -------------------------------------------------------------------------
     * User functions.
     * -------------------------------------------------------------------------
     */

    /**
     * Verify.
     * @param signature_ Message hash to verify.
     * @param sender_ Address of the sender to verify.
     * @param salt_ Salt used to create the message hash.
     * @param expiration_ Expiration timestamp of the signature.
     * @return bool True if verified.
     * @notice This method takes a signature and then verifies that it returns
     * the original signer address with the provided values. This enables
     * verification without having to store addresses on the blockchain.
     */
    function verify(
        bytes memory signature_,
        address sender_,
        string memory salt_,
        uint256 expiration_
    ) external view returns (bool) {
        // Return false if the signature is expired.
        if(block.timestamp > expiration_) {
            return false;
        }

        // Re-create the original signature hash value.
        bytes32 _hash_ = sha256(abi.encode(sender_, salt_, expiration_));

        // Verify that the signature was created by the signer and
        // return false if not.
        if(ECDSA.recover(_hash_, signature_) != _signer) {
            return false;
        }

        // Everything passed!
        return true;
    }

    /**
     * -------------------------------------------------------------------------
     * Admin functions.
     * -------------------------------------------------------------------------
     */

    /**
     * Update signer.
     * @param signer_ Address of new signer.
     * @notice This allows the owner to update the signer address.
     */
    function updateSigner(address signer_) external onlyOwner
    {
        _signer = signer_;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}