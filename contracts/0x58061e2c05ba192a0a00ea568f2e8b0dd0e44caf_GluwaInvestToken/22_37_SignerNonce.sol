// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

contract SignerNonce is ContextUpgradeable {
    mapping(bytes32 => bool) private _nonceUsed;

    /**
     * @dev Allow sender to check if the nonce is used.
     */
    function isNonceUsed(uint256 nonce) public view virtual returns (bool) {
        return _isNonceUsed(_msgSender(), nonce);
    }

    /**
     * @dev Allow sender to check if the nonce is used.
     */
    function revokeSignature(uint256 nonce) external virtual returns (bool) {
        _nonceUsed[keccak256(abi.encodePacked(_msgSender(), nonce))] = true;
        return true;
    }

    /**
     * @dev Check whether a nonce is used for a signer.
     */
    function _isNonceUsed(address signer, uint256 nonce)
        private
        view
        returns (bool)
    {
        return _nonceUsed[keccak256(abi.encodePacked(signer, nonce))];
    }

    /**
     * @dev Register a nonce for a signer.
     */
    function _useNonce(address signer, uint256 nonce) internal {
        require(!_isNonceUsed(signer, nonce), "SignerNonce: Invalid Nonce");
        _nonceUsed[keccak256(abi.encodePacked(signer, nonce))] = true;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}