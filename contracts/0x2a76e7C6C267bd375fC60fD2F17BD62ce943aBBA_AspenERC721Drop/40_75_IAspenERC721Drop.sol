// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8;

import "../IAspenFeatures.sol";
import "../IMulticallable.sol";
import "../IAspenVersioned.sol";
import "../issuance/ICedarNFTIssuance.sol";
import "../issuance/INFTLimitSupply.sol";
import "../agreement/IAgreement.sol";
import "../issuance/INFTSupply.sol";
import "../issuance/INFTClaimCount.sol";
import "../lazymint/ILazyMint.sol";
import "../standard/IERC721.sol";
import "../standard/IERC4906.sol";
import "../standard/IERC2981.sol";
import "../royalties/IRoyalty.sol";
import "../baseURI/IUpdateBaseURI.sol";
import "../metadata/INFTMetadata.sol";
import "../metadata/IContractMetadata.sol";
import "../primarysale/IPrimarySale.sol";
import "../pausable/IPausable.sol";
import "../ownable/IOwnable.sol";
import "../royalties/IPlatformFee.sol";

// Each AspenERC721 contract should implement a maximal version of the interfaces it supports and should itself carry
// the version major version suffix, in this case CedarERC721V0

interface IAspenERC721DropV2 is
    IAspenFeaturesV0,
    IAspenVersionedV2,
    IMulticallableV0,
    // NOTE: keep this standard interfaces around to generate supportsInterface
    IERC721V3,
    IERC2981V0,
    IRestrictedERC4906V0,
    // NOTE: keep this standard interfaces around to generate supportsInterface ˆˆ
    // Supply
    INFTSupplyV1,
    IRestrictedNFTLimitSupplyV1,
    // Issuance
    IPublicNFTIssuanceV4,
    IDelegatedNFTIssuanceV0,
    IRestrictedNFTIssuanceV4,
    // Roylaties
    IPublicRoyaltyV0,
    IRestrictedRoyaltyV1,
    // BaseUri
    IPublicUpdateBaseURIV0,
    IRestrictedUpdateBaseURIV1,
    // Metadata
    IPublicMetadataV0,
    IAspenNFTMetadataV1,
    IRestrictedMetadataV2,
    // Ownable
    IPublicOwnableV0,
    IRestrictedOwnableV0,
    // Pausable
    IPublicPausableV0,
    IRestrictedPausableV1,
    // Agreement
    IPublicAgreementV1,
    IDelegatedAgreementV0,
    IRestrictedAgreementV1,
    // Primary Sale
    IPublicPrimarySaleV1,
    IRestrictedPrimarySaleV2,
    // Oprator Filterers
    IRestrictedOperatorFiltererV0,
    IPublicOperatorFilterToggleV0,
    IRestrictedOperatorFilterToggleV0,
    // Delegated only
    IDelegatedPlatformFeeV0,
    // Restricted only
    IRestrictedLazyMintV1,
    IRestrictedNFTClaimCountV0
{

}