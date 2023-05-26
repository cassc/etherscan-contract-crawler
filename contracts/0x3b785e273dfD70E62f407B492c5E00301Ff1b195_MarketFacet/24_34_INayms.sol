// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// solhint-disable no-empty-blocks

import { IDiamondCut } from "../shared/interfaces/IDiamondCut.sol";
import { IDiamondLoupe } from "../shared/interfaces/IDiamondLoupe.sol";
import { IERC165 } from "../shared/interfaces/IERC165.sol";
import { IERC173 } from "../shared/interfaces/IERC173.sol";

import { IACLFacet } from "./interfaces/IACLFacet.sol";
import { IUserFacet } from "./interfaces/IUserFacet.sol";
import { IAdminFacet } from "./interfaces/IAdminFacet.sol";
import { ISystemFacet } from "./interfaces/ISystemFacet.sol";
import { INaymsTokenFacet } from "./interfaces/INaymsTokenFacet.sol";
import { ITokenizedVaultFacet } from "./interfaces/ITokenizedVaultFacet.sol";
import { ITokenizedVaultIOFacet } from "./interfaces/ITokenizedVaultIOFacet.sol";
import { IMarketFacet } from "./interfaces/IMarketFacet.sol";
import { IEntityFacet } from "./interfaces/IEntityFacet.sol";
import { ISimplePolicyFacet } from "./interfaces/ISimplePolicyFacet.sol";
import { IGovernanceFacet } from "./interfaces/IGovernanceFacet.sol";

/**
 * @title Nayms Diamond
 * @notice Everything is a part of one big diamond.
 * @dev Every facet should be cut into this diamond.
 */
interface INayms is
    IDiamondCut,
    IDiamondLoupe,
    IERC165,
    IERC173,
    IACLFacet,
    IAdminFacet,
    IUserFacet,
    ISystemFacet,
    INaymsTokenFacet,
    ITokenizedVaultFacet,
    ITokenizedVaultIOFacet,
    IMarketFacet,
    IEntityFacet,
    ISimplePolicyFacet,
    IGovernanceFacet
{

}