// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IPartyActions} from "./party/IPartyActions.sol";
import {IPartyEvents} from "./party/IPartyEvents.sol";
import {IPartyMemberActions} from "./party/IPartyMemberActions.sol";
import {IPartyManagerActions} from "./party/IPartyManagerActions.sol";
import {IPartyCreatorActions} from "./party/IPartyCreatorActions.sol";
import {IPartyState} from "./party/IPartyState.sol";

/**
 * @title Interface for PartyFacet
 * @dev The party interface is broken up into smaller chunks
 */
interface IPartyFacet is
    IPartyActions,
    IPartyEvents,
    IPartyCreatorActions,
    IPartyManagerActions,
    IPartyMemberActions,
    IPartyState
{

}