// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract SignedTokenVerifier {
    using ECDSA for bytes32;

    address private _signer;

    event SignerUpdated(address newSigner);

    constructor() {
    }

    function _setSigner(address _newSigner) internal {
        _signer = _newSigner;
        emit SignerUpdated(_signer);
    }

    function _hash(string calldata salt, uint256 _tokenId, address _address)
        internal
        view
        returns (bytes32)
    {
        return keccak256(abi.encode(salt, address(this), _address, _tokenId));
    }

    function _verify(bytes32 hash, bytes memory token)
        internal
        view
        returns (bool)
    {
        return (_recover(hash, token) == _signer);
    }

    function _recover(bytes32 hash, bytes memory token)
        internal
        pure
        returns (address)
    {
        return hash.toEthSignedMessageHash().recover(token);
    }

    function verifyTokenForAddress(
        string calldata _salt,
        bytes calldata _token,
        uint256 _tokenId,
        address _address
    ) public view returns (bool) {
        return _verify(_hash(_salt, _tokenId, _address), _token);
    }
}