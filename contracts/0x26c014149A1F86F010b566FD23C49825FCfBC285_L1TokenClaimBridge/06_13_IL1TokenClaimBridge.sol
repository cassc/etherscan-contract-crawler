// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IL1TokenClaimBridge {
    function claimEtherForMultipleNfts(
        address[] calldata canonicalNfts_,
        uint256[] calldata tokenIds_,
        address payable beneficiary_,
        uint256[] calldata amounts_
    ) external;

    function markReplicasAsAuthentic(address canonicalNft_, uint256 tokenId_)
        external;

    function l2TokenClaimBridge() external view returns (address);

    function l1EventLogger() external view returns (address);

    function royaltyEngine() external view returns (address);
}