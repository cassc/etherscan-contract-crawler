//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IMerkleWhitelist {
    event UpdateMerkleRoot(bytes32 rootHash);

    event ClaimWhitelist(address indexed sender, uint256 round);

    function isWhitelisted(address owner, bytes32[] calldata proof)
        external
        view
        returns (bool);

    function claimWhitelist(address owner, bytes32[] calldata proof) external;

    function updateIsLimited(bool limited) external;

    function isLimited() external view returns (bool);
}