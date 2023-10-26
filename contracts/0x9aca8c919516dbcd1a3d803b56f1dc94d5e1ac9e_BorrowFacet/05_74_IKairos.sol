// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {IDiamondLoupe} from "diamond/contracts/interfaces/IDiamondLoupe.sol";
import {IDiamondCut} from "diamond/contracts/interfaces/IDiamondCut.sol";

import {IAdminFacet} from "./IAdminFacet.sol";
import {IAuctionFacet} from "./IAuctionFacet.sol";
import {IBorrowFacet} from "./IBorrowFacet.sol";
import {IClaimFacet} from "./IClaimFacet.sol";
import {IOwnershipFacet} from "./IOwnershipFacet.sol";
import {IProtocolFacet} from "./IProtocolFacet.sol";
import {IRepayFacet} from "./IRepayFacet.sol";
import {ISupplyPositionFacet} from "./ISupplyPositionFacet.sol";

/* solhint-disable-next-line no-empty-blocks */
interface IKairos is
    IDiamondLoupe,
    IDiamondCut,
    IAdminFacet,
    IAuctionFacet,
    IBorrowFacet,
    IClaimFacet,
    IOwnershipFacet,
    IProtocolFacet,
    IRepayFacet,
    ISupplyPositionFacet
{

}