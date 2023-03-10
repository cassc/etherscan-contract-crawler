// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import "../../libs/LibBase58.sol";

contract TokenCIDDigestURIUpgradeable {
    bytes private constant V0_SHA256_MULTI_HASH = hex"1220";

    mapping(uint256 => bytes32) private _tokenCIDsDigests;

    function cidDigest(uint256 tokenId) public view returns (bytes32) {
        return _tokenCIDsDigests[tokenId];
    }

    function _generateIpfsURIFromDigest(bytes32 _cidDigest) internal pure returns (string memory) {
        return string(abi.encodePacked("ipfs://", _digestToCIDV0(_cidDigest)));
    }

    function _digestToCIDV0(bytes32 _cidDigest) internal pure returns (string memory) {
        return string(_digestToCIDV0MultiHash(_cidDigest));
    }

    function _digestToCIDV0MultiHash(bytes32 _cidDigest) internal pure returns (bytes memory) {
        return LibBase58.toBase58(LibBase58.concat(V0_SHA256_MULTI_HASH, abi.encodePacked(_cidDigest)));
    }

    function _setTokenCIDDigest(uint256 tokenId, bytes32 _cidDigest) internal virtual {
        _tokenCIDsDigests[tokenId] = _cidDigest;
    }

    function _resetTokenCIDDigest(uint256 tokenId) internal virtual {
        delete _tokenCIDsDigests[tokenId];
    }

    uint256[50] private __gap;
}