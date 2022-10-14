// SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8;

import "../ICedarFeatures.sol";
import "../IMulticallable.sol";
import "../ICedarVersioned.sol";
import "../issuance/ICedarSFTIssuance.sol";
import "../lazymint/ICedarLazyMint.sol";
import "../baseURI/ICedarUpdateBaseURI.sol";
import "../standard/IERC1155.sol";
import "../royalties/IRoyalty.sol";
import "../metadata/ICedarSFTMetadata.sol";
import "../metadata/IContractMetadata.sol";
import "../agreement/ICedarAgreement.sol";
import "../primarysale/IPrimarySale.sol";

interface ICedarERC1155DropV3 is
    ICedarFeaturesV0,
    ICedarVersionedV0,
    IMulticallableV0,
    ICedarSFTIssuanceV1,
    ICedarLazyMintV0,
    ICedarUpdateBaseURIV0,
    IERC1155SupplyV0,
    IRoyaltyV0,
    ICedarMetadataV1,
    ICedarAgreementV0,
    IPrimarySaleV0
{}