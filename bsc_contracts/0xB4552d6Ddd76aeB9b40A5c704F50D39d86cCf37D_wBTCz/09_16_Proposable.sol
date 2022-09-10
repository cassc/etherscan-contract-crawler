// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./ERRNO.sol";


abstract contract Proposable is ERRNO {

    constructor() {}

    /*########## OBSERVERS ##########*/

    function getVoterNumberLimit() internal view virtual returns (uint256);

    function isActive(uint256 proposalIndex) internal view virtual returns (bool);

    function isPct(uint256 pct) internal pure virtual returns (bool);

    function getActionPct(uint8 action) internal view virtual returns (uint8);

    /*########## MODIFIERS ##########*/

    function setVoterNumberLimit(uint256 limit) internal virtual;

    function addProposal(
        address proposedBy,
        uint8 action,
        uint256 groupIndex,
        uint256 value
    ) internal virtual returns (uint256 proposalIndex, ErrNo errNo);

    function voteProposal(address voter, address proposedBy, uint8 action,  uint8 decision) internal virtual returns (int8, ErrNo);

    function voteProposal(address voter, uint256 proposalIndex,  uint8 decision) internal virtual returns (int8, ErrNo);

    function removeProposal(address proposedBy, uint8 action) internal virtual returns (bool);
    
    function setActionPct(uint8 action, uint8 pct) internal virtual returns (bool);


}