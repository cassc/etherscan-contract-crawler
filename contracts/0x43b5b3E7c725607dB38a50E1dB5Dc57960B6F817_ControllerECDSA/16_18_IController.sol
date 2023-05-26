// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IController {

    function setMembershipCard(address _membershipCard) external;

    function signerOfSafeMintBatch(
        address[] memory _squadsIn,
        address[] memory toAddresses,
        address minterOwner,
        bytes memory signature,
        uint256 deadline,
        uint256 _nonce
    ) external view returns (address);

    function signerOfSafeMint(
        address _squad,
        address to,
        address minterOwner,
        bytes memory signature,
        uint256 deadline,
        uint256 _nonce
    ) external view returns (address);

    function signerOfAdminTransfer(
        address from,
        address to,
        uint256 tokenId,
        address minterOwner,
        bytes memory signature,
        uint256 deadline,
        uint256 _nonce
    ) external view returns (address);

    function executeMintBatchFromSignature(
        address[] memory squads,
        address[] memory toAddresses,
        address minterOwner,
        bytes memory signature,
        uint256 deadline,
        uint256 _nonce
    ) external;

    function executeMintFromSignature(
        address squad,
        address to,
        address minterOwner,
        bytes memory signature,
        uint256 deadline,
        uint256 _nonce
    ) external;

    function executeAdminTransferFromSignature(
        address from,
        address to,
        uint256 tokenId,
        address transferOwner,
        bytes memory signature,
        uint256 deadline,
        uint256 _nonce
    ) external;
}