// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ECDSA.sol";

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

    function _hash(bytes calldata _salt, uint256 _tokenId, string memory _nftName, address _address)
        internal
        view
        returns (bytes32)
    {
        return keccak256(abi.encode(_salt, address(this), _address, _tokenId, _nftName));
    }

    function _recover(bytes32 hash, bytes memory token)
        internal
        pure
        returns (address)
    {
        return hash.toEthSignedMessageHash().recover(token);
    }

    function getAddress(
        bytes calldata _salt,
        uint256 _tokenId,
        string memory _nftName,
        bytes calldata _token,
        address _address
    ) internal view returns (address) {
        return _recover(_hash(_salt, _tokenId, _nftName, _address), _token);
    }

    function verifyTokenForAddress(
        bytes calldata _salt,
        uint256 _tokenId,
        string memory _nftName,
        bytes calldata _token,
        address _address
    ) public view returns (bool) {
        return getAddress(_salt, _tokenId, _nftName, _token, _address) == _signer;
    }
}