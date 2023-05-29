// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleAllowList {

    mapping(address=>bool) internal _hasMinted;
    bytes32 internal _merkleRoot;

    constructor(bytes32 merkleRoot) {
        _merkleRoot = merkleRoot;
    }

    function hasUserMinted(address user) external view returns (bool) {
        return _hasMinted[user];
    }

    function _setMerkleRoot(bytes32 newMerkleRoot) internal {
        _merkleRoot = newMerkleRoot;
    }

    bool public allowListEnabled = true;

    event EnabledAllowList();
    event DisableAllowList();

    modifier onlyPublicSale {
        require(!allowListEnabled, "Allow list is currently active");
        _;
    }

    modifier onlyAllowListSale {
        require(allowListEnabled, "Allow list is current not active");
        _;
    }

    function _setHasMinted(address _newlyMinted) internal {
        _hasMinted[_newlyMinted] = true;
    }

    function _enableAllowList() internal {
        allowListEnabled = true;
        emit EnabledAllowList();
    }

    function _disableAllowList() internal {
        allowListEnabled = false;
        emit DisableAllowList();
    }

    modifier canMint(bytes32[] calldata proof, address _sender) {
        require(allowListEnabled, "Allow list is currently not active");
        require(!_hasMinted[_sender], "User has already minted in whitelist sale");
        bytes32 leaf = keccak256(abi.encodePacked(_sender));
        require(MerkleProof.verify(proof, _merkleRoot, leaf), "User is not whitelisted");
        _;
    }

}