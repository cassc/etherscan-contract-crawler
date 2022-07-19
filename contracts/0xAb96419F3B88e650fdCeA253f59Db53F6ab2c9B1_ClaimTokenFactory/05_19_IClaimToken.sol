// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface IClaimToken {
    function closePoolDistribution()
         external;

    function initialize(
    address _token,
    bytes32 _merkleRoot
    ) external;

    function updateMerkleRoot (bytes32 _merkleRoot) external ;

    function updateAddress(address formerAddress, address newAddress) external;

    function claim (
        address _tokenContract,
        bytes32[] memory proof,
        uint256 _amount
    ) external;

     function transferOwnership(address _owner) external;
}