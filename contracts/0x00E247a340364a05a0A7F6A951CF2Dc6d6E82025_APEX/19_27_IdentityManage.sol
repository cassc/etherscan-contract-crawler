// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "../interfaces/IIdentityManage.sol";
import "./APEXAccessControl.sol";

contract IdentityManage is IIdentityManage, APEXAccessControl {
    using MerkleProof for bytes32[];

    bytes32 private _whitelistMerkleRoot;
    bytes32 private _ogListMerkleRoot;
    mapping(address => bool) private _isTreasuryAdmin;

    function setWhitelistMerkleRoot(
        bytes32 merkleRoot
    ) external override onlyRole(BUSINESS_MANAGER) {
        _whitelistMerkleRoot = merkleRoot;
    }

    function setOGListMerkleRoot(
        bytes32 merkleRoot
    ) external override onlyRole(BUSINESS_MANAGER) {
        _ogListMerkleRoot = merkleRoot;
    }

    function setTreasuryAdmin(
        address addr,
        bool setAsTreasuryAdmin
    ) external override onlyRole(BUSINESS_MANAGER) {
        _isTreasuryAdmin[addr] = setAsTreasuryAdmin;
    }

    function isWhitelist(
        address user,
        bytes32[] calldata merkleProof
    ) public view override returns (bool) {
        return
            merkleProof.verify(
                _whitelistMerkleRoot,
                keccak256(bytes.concat(keccak256(abi.encode(user))))
            );
    }

    function isOG(
        address user,
        bytes32[] calldata merkleProof
    ) public view override returns (bool) {
        return
            merkleProof.verify(
                _ogListMerkleRoot,
                keccak256(bytes.concat(keccak256(abi.encode(user))))
            );
    }

    function isTreasuryAdmin(address user) public view override returns (bool) {
        return _isTreasuryAdmin[user];
    }
}