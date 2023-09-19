// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8;

import "../IAspenFeatures.sol";
import "../IMulticallable.sol";
import "../IAspenVersioned.sol";
import "../issuance/ICedarSFTIssuance.sol";
import "../issuance/ISFTLimitSupply.sol";
import "../issuance/ISFTSupply.sol";
import "../issuance/ISFTClaimCount.sol";
import "../baseURI/IUpdateBaseURI.sol";
import "../standard/IERC1155.sol";
import "../standard/IERC2981.sol";
import "../standard/IERC4906.sol";
import "../royalties/IRoyalty.sol";
import "../metadata/ISFTMetadata.sol";
import "../metadata/IContractMetadata.sol";
import "../agreement/IAgreement.sol";
import "../primarysale/IPrimarySale.sol";
import "../lazymint/ILazyMint.sol";
import "../pausable/IPausable.sol";
import "../ownable/IOwnable.sol";
import "../royalties/IPlatformFee.sol";

interface IAspenERC1155DropV4 is
    IAspenFeaturesV1,
    IAspenVersionedV2,
    IMulticallableV0,
    // NOTE: keep this standard interfaces around to generate supportsInterface
    IERC1155V5,
    IERC1155MetadataURIV0,
    IERC1155BurnableV0,
    IERC1155NameSymbolV0,
    IERC2981V0,
    IRestrictedERC4906V0,
    // NOTE: keep this standard interfaces around to generate supportsInterface ˆˆ
    // Supply
    IDelegatedSFTSupplyV2,
    IRestrictedSFTLimitSupplyV1,
    // Issuance
    IPublicSFTIssuanceV5,
    IDelegatedSFTIssuanceV1,
    IRestrictedSFTIssuanceV6,
    // Royalties
    IDelegatedRoyaltyV1,
    IRestrictedRoyaltyV1,
    // BaseUri
    IDelegatedUpdateBaseURIV1,
    IRestrictedUpdateBaseURIV1,
    // Metadata
    IDelegatedMetadataV0,
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
    IDelegatedPrimarySaleV0,
    IRestrictedPrimarySaleV2,
    IRestrictedSFTPrimarySaleV0,
    // Operator Filterer
    IRestrictedOperatorFiltererV0,
    IPublicOperatorFilterToggleV1,
    IRestrictedOperatorFilterToggleV0,
    // Delegated only
    IDelegatedPlatformFeeV0,
    // Restricted Only
    IRestrictedLazyMintV1,
    IRestrictedSFTClaimCountV0
{}