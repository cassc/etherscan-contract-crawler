// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IIdentityManage {
    /// @dev set the whitelist Merkle Tree root
    /// @param merkleRoot the merkle root of whitelist
    function setWhitelistMerkleRoot(bytes32 merkleRoot) external;

    /// @dev set the OG list Merkle Tree root
    /// @param merkleRoot the merkle root of OG list
    function setOGListMerkleRoot(bytes32 merkleRoot) external;

    /// @dev set if the address is treasury admin
    /// @param addr the address to set
    /// @param isTreasuryAdmin if `addr` is treasury admin
    function setTreasuryAdmin(address addr, bool isTreasuryAdmin) external;

    /// @dev if `user` is in whitelist
    /// @param user the `address` to be verified
    /// @param merkleProof the Merkle Proof of the user
    function isWhitelist(
        address user,
        bytes32[] calldata merkleProof
    ) external view returns (bool);

    /// @dev if `user` is in OG list
    /// @param user the `address` to be verified
    /// @param merkleProof the Merkle Proof of the user
    function isOG(
        address user,
        bytes32[] calldata merkleProof
    ) external view returns (bool);

    /// @dev if `user` is treasury admin
    /// @param user the `address` to be verified
    function isTreasuryAdmin(address user) external view returns (bool);
}