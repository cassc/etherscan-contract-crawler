// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol';

contract SignerNonce is ContextUpgradeable {
    mapping(bytes32 => bool) private _nonceUsed;

    /**
     * @dev Allow sender to check if the nonce is used.
     */
    function isNonceUsed(uint256 nonce) public view virtual returns (bool) {
        return _isNonceUsed(_msgSender(), nonce);
    }

    /**
     * @dev Check whether a nonce is used for a signer.
     */
    function _isNonceUsed(address signer, uint256 nonce) private view returns (bool) {
        return _nonceUsed[keccak256(abi.encodePacked(signer, nonce))];
    }

    function revokeSignature(uint256 nonce) external virtual returns (bool) {
        return _nonceUsed[keccak256(abi.encodePacked(_msgSender(), nonce))] = true;
    }

    /**
     * @dev Register a nonce for a signer.
     */
    function _useNonce(address signer, uint256 nonce) internal {
        require(!_isNonceUsed(signer, nonce), 'SignerNonce: Invalid Nonce');
        _nonceUsed[keccak256(abi.encodePacked(signer, nonce))] = true;
    }
}