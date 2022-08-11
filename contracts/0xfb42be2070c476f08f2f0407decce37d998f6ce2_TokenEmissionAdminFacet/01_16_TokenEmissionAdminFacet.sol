// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Base} from "../base/Base.sol";
import {LibMint} from "../libraries/LibMint.sol";

contract TokenEmissionAdminFacet is Base {

    function setClaimingMerkleRoot(bytes32 root_) external {
        LibMint.mintStorage().claimingMerkleRoot = root_;
    }

    function initMint(
        uint256 price,
        uint256 supply,
        uint256 maxMintsPerTx,
        uint256 maxMintsPerAddress,
        bytes32 privateSaleMerkleRoot,
        bytes32 claimingMerkleRoot
    ) external {
        LibMint.init(price, supply, maxMintsPerTx, maxMintsPerAddress, privateSaleMerkleRoot, claimingMerkleRoot);
    }

    function setClaiming(bool active_) external {
        active_ ? LibMint.activateClaiming() : LibMint.deactivateClaiming();
    }

    function setPublicSale(bool active_) external {
        active_ ? LibMint.startPublicSale() : LibMint.stopPublicSale();
    }

    function setPrivateSale(bool active_) external {
        active_ ? LibMint.startPrivateSale() : LibMint.stopPrivateSale();
    }

    function setPrivateSaleMerkleRoot(bytes32 root_) external {
        LibMint.mintStorage().privateSaleMerkleRoot = root_;
    }

    function getClaimingMerkleRoot() external view returns (bytes32) {
        return LibMint.mintStorage().claimingMerkleRoot;
    }

    function getPrivateSaleMerkleRoot() external view returns (bytes32) {
        return LibMint.mintStorage().privateSaleMerkleRoot;
    }
}