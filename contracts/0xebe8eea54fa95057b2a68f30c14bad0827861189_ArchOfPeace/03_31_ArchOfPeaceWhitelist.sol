// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// import "./MonuverseEpisode.sol";

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ArchOfPeaceWhitelist is Ownable {
    bytes32 private _whitelistRoot;

    function setWhitelistRoot(bytes32 newWhitelistRoot) public virtual onlyOwner {
        _whitelistRoot = newWhitelistRoot;
    }

    function isAccountWhitelisted(
        address account,
        uint256 limit,
        bytes32 birth,
        bytes32[] memory proof
    ) public view returns (bool) {
        require(
            owner() == _msgSender() || account == _msgSender(),
            "ArchOfPeaceWhitelist: account check forbidden"
        );

        return
            MerkleProof.verify(
                proof,
                _whitelistRoot,
                _generateWhitelistLeaf(account, limit, birth)
            );
    }

    function isAccountWhitelisted(
        uint256 limit,
        bytes32 birth,
        bytes32[] memory proof
    ) public view returns (bool) {
        return isAccountWhitelisted(_msgSender(), limit, birth, proof);
    }

    function whitelistRoot() public view returns (bytes32) {
        return _whitelistRoot;
    }

    function _generateWhitelistLeaf(
        address account,
        uint256 limit,
        bytes32 birth
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, limit, birth));
    }

    function _isQuantityWhitelisted(
        uint256 balance,
        uint256 quantity,
        uint256 limit
    ) internal pure returns (bool) {
        return balance + quantity <= limit;
    }
}