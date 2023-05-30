// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IKOAccessControlsLookup {
    function hasAdminRole(address _address) external view returns (bool);

    function isVerifiedArtist(
        uint256 _index,
        address _account,
        bytes32[] calldata _merkleProof
    ) external view returns (bool);
}