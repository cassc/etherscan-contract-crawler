// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Base} from "../base/Base.sol";
import {IMint} from "../interfaces/IMint.sol";
import {LibMerkleProof} from "../libraries/LibMerkleProof.sol";
import {LibMint} from "../libraries/LibMint.sol";

contract ClaimFacet is Base, IMint {
    function claim(bytes32[] calldata _merkleProof) external onlyEoA {
        if (!LibMint.isClaimingActive()) revert ClaimingNotActive();
        if (!LibMerkleProof.verifyClaim(_merkleProof)) revert InvalidProof();
        if (LibMint.claimed(msg.sender)) revert AlreadyClaimed();
        LibMint.setClaimed(msg.sender);
        LibMint.mint(msg.sender, s);
    }
}