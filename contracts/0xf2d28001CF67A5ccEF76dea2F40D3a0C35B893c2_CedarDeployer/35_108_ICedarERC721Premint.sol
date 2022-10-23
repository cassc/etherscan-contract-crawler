// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

import "../ICedarFeatures.sol";
import "../IMulticallable.sol";
import "../ICedarVersioned.sol";
import "../issuance/ICedarPremint.sol";
import "../agreement/ICedarAgreement.sol";
import "../baseURI/ICedarUpgradeBaseURI.sol";

// Each CedarERC721 contract should implement a maximal version of the interfaces it supports and should itself carry
// the version major version suffix, in this case CedarERC721V0

interface ICedarERC721PremintV2 is
    ICedarFeaturesV0,
    ICedarVersionedV1,
    ICedarPremintV0,
    ICedarAgreementV0,
    IMulticallableV0,
    ICedarUpgradeBaseURIV0
{

}