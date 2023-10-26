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

interface IAspenERC721DropV4 is
    IAspenFeaturesV1,
    IAspenVersionedV2,
    IMulticallableV0,
    // NOTE: keep this standard interfaces around to generate supportsInterface
    IERC721V5,
    IERC721MetadataV0,
    IERC721BurnableV0,
    IERC2981V0,
    IRestrictedERC4906V0,
    // NOTE: keep this standard interfaces around to generate supportsInterface ˆˆ
    // Supply
    IPublicNFTSupplyV0,
    IDelegatedNFTSupplyV1,
    IRestrictedNFTLimitSupplyV1,
    // Issuance
    IPublicNFTIssuanceV5,
    IDelegatedNFTIssuanceV1,
    IRestrictedNFTIssuanceV6,
    // Roylaties
    IPublicRoyaltyV1,
    IDelegatedRoyaltyV0,
    IRestrictedRoyaltyV1,
    // BaseUri
    IDelegatedUpdateBaseURIV1,
    IRestrictedUpdateBaseURIV1,
    // Metadata
    IPublicMetadataV0,
    IRestrictedMetadataV2,
    // Ownable
    IPublicOwnableV1,
    // Pausable
    IDelegatedPausableV0,
    IRestrictedPausableV1,
    // Agreement
    IPublicAgreementV2,
    IDelegatedAgreementV1,
    IRestrictedAgreementV3,
    // Primary Sale
    IPublicPrimarySaleV1,
    IRestrictedPrimarySaleV2,
    // Oprator Filterers
    IRestrictedOperatorFiltererV0,
    IPublicOperatorFilterToggleV1,
    IRestrictedOperatorFilterToggleV0,
    // Delegated only
    IDelegatedPlatformFeeV0,
    // Restricted only
    IRestrictedLazyMintV1,
    IRestrictedNFTClaimCountV0
{

}