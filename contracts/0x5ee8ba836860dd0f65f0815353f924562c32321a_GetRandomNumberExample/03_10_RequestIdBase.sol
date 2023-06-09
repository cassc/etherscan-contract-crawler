// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract RequestIdBase {
    function _makeRandcastInputSeed(uint256 _userSeed, address _requester, uint256 _nonce)
        internal
        pure
        returns (uint256)
    {
        return uint256(keccak256(abi.encode(_userSeed, _requester, _nonce)));
    }

    function _makeRequestId(uint256 inputSeed) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(inputSeed));
    }
}