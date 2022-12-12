// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "../base/IBaseClaimNFT.sol";
import "../../state/StateNFTStorage.sol";

interface IWhitelistClaimNFT is IBaseClaimNFT {
    function setWhitelistMerkleRoot(bytes32 whitelistMerkleRoot) external;

    function whitelistClaim(
        StateNFTStorage.Edition edition,
        StateNFTStorage.Size size,
        bytes32[] calldata whitelistProof
    ) external payable returns (uint256 tokenId);

    function isWhitelistClaimAllowed(bytes32[] calldata whitelistProof) external view returns (bool);
}