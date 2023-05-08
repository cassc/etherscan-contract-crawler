// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// import "@forge-std/src/console.sol";

import {LibDiamond} from "@lib-diamond/src/diamond/LibDiamond.sol";
import {DiamondStorage} from "@lib-diamond/src/diamond/DiamondStorage.sol";
import {IDiamondCut} from "@lib-diamond/src/diamond/IDiamondCut.sol";
import {DiamondLoupeFacet} from "@lib-diamond/src/diamond/DiamondLoupeFacet.sol";
import {ADiamondCutFacet} from "@lib-diamond/src/diamond/ADiamondCutFacet.sol";
import {FacetCut, FacetCutAction} from "@lib-diamond/src/diamond/Facet.sol";
import {DiamondCutAndLoupeFacet} from "@src/ponzu/facets/DiamondCutAndLoupeFacet.sol";

import {IAccessControl} from "@lib-diamond/src/access/access-control/IAccessControl.sol";
import {AccessControlEnumerableFacet} from "@lib-diamond/src/access/access-control/AccessControlEnumerableFacet.sol";
import {DEFAULT_ADMIN_ROLE} from "@lib-diamond/src/access/access-control/Roles.sol";
import {GAME_ADMIN_ROLE} from "./types/ponzu/PonzuRoles.sol";
import {LibAccessControlEnumerable} from "@lib-diamond/src/access/access-control/LibAccessControlEnumerable.sol";
import {WithRoles} from "@lib-diamond/src/access/access-control/WithRoles.sol";

import {ERC165Facet} from "@lib-diamond/src/utils/introspection/erc165/ERC165Facet.sol";

import {APausableFacet} from "@lib-diamond/src/security/pausable/APausableFacet.sol";

import {LibPonzu} from "./libraries/LibPonzu.sol";
import {PonzuStorage} from "./types/ponzu/PonzuStorage.sol";

import {LibQRNG} from "./libraries/LibQRNG.sol";
import {QRNGStorage} from "./types/qrng/QRNGStorage.sol";

import {IAirnodeRrpV0} from "@api3/airnode-protocol/contracts/rrp/interfaces/IAirnodeRrpV0.sol";

import {ABaseDiamond} from "@lib-diamond/src/diamond/ABaseDiamond.sol";

import {Proxy} from "@lib-diamond/src/proxy-etherscan/Proxy.sol";

import {IPausable} from "@lib-diamond/src/security/pausable/IPausable.sol";

// When no function exists for function called
error FunctionNotFound(bytes4 functionSignature);

contract Diamond is ABaseDiamond, Proxy, WithRoles {
  constructor(
    address airnodeRrp,
    address blackHole,
    address rewardToken,
    address contractAdmin,
    address diamondCutAndLoupeFacet_,
    address AccessControlEnumerableFacet_,
    address erc165Facet_,
    address pausableFacet_,
    address methodsExposureFacetAddress_
  ) payable {
    LibAccessControlEnumerable.grantRole(DEFAULT_ADMIN_ROLE, contractAdmin);
    LibAccessControlEnumerable.grantRole(GAME_ADMIN_ROLE, contractAdmin);

    PonzuStorage storage ps = LibPonzu.DS();

    ps.blackHole = blackHole;
    ps.rewardToken = rewardToken;
    ps.depositDeadlineDuration = 6 hours;
    ps.roundDuration = 3 days;

    // QRNG
    QRNGStorage storage qs = LibQRNG.DS();
    qs.airnodeRrp = airnodeRrp;
    IAirnodeRrpV0(airnodeRrp).setSponsorshipStatus(address(this), true);

    // Set the implementation address
    _setImplementation(methodsExposureFacetAddress_);

    // Add the diamondCut external function from the diamondCutFacet
    FacetCut[] memory cut = new FacetCut[](1);
    bytes4[] memory functionSelectors = new bytes4[](1);

    // Add the diamondLoupe external functions from the diamondLoupeFacet
    cut = new FacetCut[](1);
    functionSelectors = new bytes4[](5);
    functionSelectors[0] = DiamondLoupeFacet.facets.selector;
    functionSelectors[1] = DiamondLoupeFacet.facetFunctionSelectors.selector;
    functionSelectors[2] = DiamondLoupeFacet.facetAddresses.selector;
    functionSelectors[3] = DiamondLoupeFacet.facetAddress.selector;
    functionSelectors[4] = IDiamondCut.diamondCut.selector;
    cut[0] = FacetCut({
      facetAddress: diamondCutAndLoupeFacet_,
      action: FacetCutAction.Add,
      functionSelectors: functionSelectors
    });
    LibDiamond.diamondCut(cut, address(0), "");

    // Add the access control external functions from the AccessControlEnumerableFacet
    cut = new FacetCut[](1);
    functionSelectors = new bytes4[](8);
    functionSelectors[0] = IAccessControl.hasRole.selector;
    functionSelectors[1] = IAccessControl.getRoleAdmin.selector;
    functionSelectors[2] = IAccessControl.grantRole.selector;
    functionSelectors[3] = IAccessControl.revokeRole.selector;
    functionSelectors[4] = IAccessControl.renounceRole.selector;
    functionSelectors[5] = AccessControlEnumerableFacet.getRoleMember.selector;
    functionSelectors[6] = AccessControlEnumerableFacet.getRoleMemberCount.selector;
    functionSelectors[7] = AccessControlEnumerableFacet.getRoleMembers.selector;
    cut[0] = FacetCut({
      facetAddress: AccessControlEnumerableFacet_,
      action: FacetCutAction.Add,
      functionSelectors: functionSelectors
    });
    LibDiamond.diamondCut(cut, address(0), "");

    // Add the ERC165 external functions from the erc165Facet
    cut = new FacetCut[](1);
    functionSelectors = new bytes4[](1);
    functionSelectors[0] = ERC165Facet.supportsInterface.selector;
    cut[0] = FacetCut({
      facetAddress: erc165Facet_,
      action: FacetCutAction.Add,
      functionSelectors: functionSelectors
    });
    LibDiamond.diamondCut(cut, address(0), "");

    // Add the Pausable external functions from the pausableFacet
    cut = new FacetCut[](1);
    functionSelectors = new bytes4[](5);
    functionSelectors[0] = IPausable.pause.selector;
    functionSelectors[1] = IPausable.unpause.selector;
    functionSelectors[2] = IPausable.isPaused.selector;
    functionSelectors[3] = IPausable.lastPausedAt.selector;
    functionSelectors[4] = IPausable.timeSincePaused.selector;
    cut[0] = FacetCut({
      facetAddress: pausableFacet_,
      action: FacetCutAction.Add,
      functionSelectors: functionSelectors
    });
    LibDiamond.diamondCut(cut, address(0), "");
  }
}