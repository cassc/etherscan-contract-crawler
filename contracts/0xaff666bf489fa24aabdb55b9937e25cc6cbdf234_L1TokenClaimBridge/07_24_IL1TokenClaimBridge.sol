// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IL1TokenClaimBridge {
    function initialize(address l1EventLogger_) external;

    function initializeContractReferences(
        address crossChainOwner_,
        address l2TokenClaimBridge_
    ) external;

    function setL2TokenClaimBridge(address l2TokenClaimBridge_) external;

    function claimEther(
        address canonicalNft_,
        uint256 tokenId_,
        address payable beneficiary_
    ) external;

    function claimEtherForMultipleNfts(
        address[] calldata canonicalNfts_,
        uint256[] calldata tokenIds_,
        address payable beneficiary_
    ) external;

    // TODO: rename to "authenticateReplicas"?
    function markReplicasAsAuthentic(address canonicalNft_, uint256 tokenId_)
        external;

    function markReplicasAsAuthenticMultiple(
        address[] calldata canonicalNfts_,
        uint256[] calldata tokenIds_
    ) external;

    function burnReplicasAndDisableRemints(
        address canonicalNft_,
        uint256 tokenId_
    ) external;

    function burnReplicasAndDisableRemintsMultiple(
        address[] calldata canonicalNfts_,
        uint256[] calldata tokenIds_
    ) external;

    function enableRemints(address canonicalNft_, uint256 tokenId_) external;

    function enableRemintsMultiple(
        address[] calldata canonicalNfts_,
        uint256[] calldata tokenIds_
    ) external;

    function disableRemints(address canonicalNft_, uint256 tokenId_) external;

    function disableRemintsMultiple(
        address[] calldata canonicalNfts_,
        uint256[] calldata tokenIds_
    ) external;

    function l2TokenClaimBridge() external view returns (address);

    function l1EventLogger() external view returns (address);
}