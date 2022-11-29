// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8;

import "../ICedarFeatures.sol";
import "../IMulticallable.sol";
import "../ICedarVersioned.sol";
import "../issuance/ICedarSFTIssuance.sol";
import "../issuance/ISFTLimitSupply.sol";
import "../issuance/ISFTSupply.sol";
import "../baseURI/ICedarUpdateBaseURI.sol";
import "../standard/IERC1155.sol";
import "../standard/IERC2981.sol";
import "../royalties/IRoyalty.sol";
import "../metadata/ICedarSFTMetadata.sol";
import "../metadata/IContractMetadata.sol";
import "../agreement/ICedarAgreement.sol";
import "../primarysale/IPrimarySale.sol";
import "../lazymint/ICedarLazyMint.sol";
import "../pausable/ICedarPausable.sol";

interface ICedarERC1155DropV5 is
    ICedarFeaturesV0,
    ICedarVersionedV2,
    IMulticallableV0,
    IPublicSFTIssuanceV0,
    ISFTSupplyV0,
    // NOTE: keep this standard interfaces around to generate supportsInterface
    IERC1155V1,
    IERC2981V0,
    IPublicRoyaltyV0,
    IPublicUpdateBaseURIV0,
    IPublicMetadataV0,
    ICedarSFTMetadataV1,
    IPublicAgreementV0,
    IPublicPrimarySaleV1,
    IRestrictedAgreementV0,
    IRestrictedSFTIssuanceV0,
    IRestrictedLazyMintV0,
    IRestrictedPausableV0,
    IRestrictedMetadataV0,
    IRestrictedUpdateBaseURIV0,
    IRestrictedRoyaltyV0,
    IRestrictedPrimarySaleV1,
    IRestrictedSFTLimitSupplyV0
{}