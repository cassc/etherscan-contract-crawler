// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./IHomageProtocolConfigView.sol";

interface IL2TokenClaimBridge is IHomageProtocolConfigView {
    function initialize(address homageProtocolConfig_) external;

    function claimEther(
        address canonicalNft_,
        uint256 tokenId_,
        address payable beneficiary_
    ) external returns (uint256);

    function claimEtherForMultipleNfts(
        address[] calldata canonicalNfts_,
        uint256[] calldata tokenIds_,
        address payable beneficiary_
    ) external returns (uint256);

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
}