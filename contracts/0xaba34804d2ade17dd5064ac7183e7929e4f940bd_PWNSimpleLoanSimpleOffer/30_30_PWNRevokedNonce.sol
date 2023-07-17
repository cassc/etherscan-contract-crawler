// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

import "@pwn/hub/PWNHubAccessControl.sol";
import "@pwn/PWNErrors.sol";


/**
 * @title PWN Revoked Nonce
 * @notice Contract holding revoked nonces.
 */
contract PWNRevokedNonce is PWNHubAccessControl {

    /*----------------------------------------------------------*|
    |*  # VARIABLES & CONSTANTS DEFINITIONS                     *|
    |*----------------------------------------------------------*/

    bytes32 immutable internal accessTag;

    /**
     * @dev Mapping of revoked nonces by an address.
     *      Every address has its own nonce space.
     *      (owner => nonce => is revoked)
     */
    mapping (address => mapping (uint256 => bool)) private revokedNonces;

    /**
     * @dev Mapping of minimal nonce value per address.
     *      (owner => minimal nonce value)
     */
    mapping (address => uint256) private minNonces;


    /*----------------------------------------------------------*|
    |*  # EVENTS DEFINITIONS                                    *|
    |*----------------------------------------------------------*/

    /**
     * @dev Emitted when a nonce is revoked.
     */
    event NonceRevoked(address indexed owner, uint256 indexed nonce);


    /**
     * @dev Emitted when a new min nonce value is set.
     */
    event MinNonceSet(address indexed owner, uint256 indexed minNonce);


    /*----------------------------------------------------------*|
    |*  # CONSTRUCTOR                                           *|
    |*----------------------------------------------------------*/

    constructor(address hub, bytes32 _accessTag) PWNHubAccessControl(hub) {
        accessTag = _accessTag;
    }


    /*----------------------------------------------------------*|
    |*  # REVOKE NONCE                                          *|
    |*----------------------------------------------------------*/

    /**
     * @notice Revoke a nonce.
     * @dev Caller is used as a nonce owner.
     * @param nonce Nonce to be revoked.
     */
    function revokeNonce(uint256 nonce) external {
        _revokeNonce(msg.sender, nonce);
    }

    /**
     * @notice Revoke a nonce on behalf of an owner.
     * @dev Only an address with associated access tag in PWN Hub can call this function.
     * @param owner Owner address of a revoking nonce.
     * @param nonce Nonce to be revoked.
     */
    function revokeNonce(address owner, uint256 nonce) external onlyWithTag(accessTag) {
        _revokeNonce(owner, nonce);
    }

    function _revokeNonce(address owner, uint256 nonce) private {
        // Revoke nonce
        revokedNonces[owner][nonce] = true;

        // Emit event
        emit NonceRevoked(owner, nonce);
    }


    /*----------------------------------------------------------*|
    |*  # SET MIN NONCE                                         *|
    |*----------------------------------------------------------*/

    /**
     * @notice Set a minimal nonce.
     * @dev Nonce is considered revoked when smaller than minimal nonce.
     * @param minNonce New value of a minimal nonce.
     */
    function setMinNonce(uint256 minNonce) external {
        // Check that nonce is greater than current min nonce
        uint256 currentMinNonce = minNonces[msg.sender];
        if (currentMinNonce >= minNonce)
            revert InvalidMinNonce();

        // Set new min nonce value
        minNonces[msg.sender] = minNonce;

        // Emit event
        emit MinNonceSet(msg.sender, minNonce);
    }


    /*----------------------------------------------------------*|
    |*  # IS NONCE REVOKED                                      *|
    |*----------------------------------------------------------*/

    /**
     * @notice Get information if owners nonce is revoked or not.
     * @dev Nonce is considered revoked if is smaller than owners min nonce value or if is explicitly revoked.
     * @param owner Address of a nonce owner.
     * @param nonce Nonce in question.
     * @return True if owners nonce is revoked.
     */
    function isNonceRevoked(address owner, uint256 nonce) external view returns (bool) {
        if (nonce < minNonces[owner])
            return true;

        return revokedNonces[owner][nonce];
    }

}