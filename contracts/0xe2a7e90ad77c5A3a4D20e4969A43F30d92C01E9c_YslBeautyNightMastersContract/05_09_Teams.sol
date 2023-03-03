// SPDX-License-Identifier: MIT
// Rampp Contracts v2.1 (Teams.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

error InvalidTeamAddress();
error DuplicateTeamAddress();

/**
 * Teams is a contract implementation to extend upon Ownable that allows multiple controllers
 * of a single contract to modify specific mint settings but not have overall ownership of the contract.
 * This will easily allow cross-collaboration via Mintplex.xyz.
 **/
abstract contract Teams is Ownable {
    mapping(address => bool) internal _team;

    /**
     * @dev Adds an address to the team. Allows them to execute protected functions
     * @param _address the ETH address to add, cannot be 0x and cannot be in team already
     **/
    function addToTeam(address _address) public onlyOwner {
        if (inTeam(_address)) revert DuplicateTeamAddress();

        _team[_address] = true;
    }

    /**
     * @dev Removes an address to the team.
     * @param _address the ETH address to remove, cannot be 0x and must be in team
     **/
    function removeFromTeam(address _address) public onlyOwner {
        if (!inTeam(_address)) revert InvalidTeamAddress();

        _team[_address] = false;
    }

    /**
     * @dev Check if an address is valid and active in the team
     * @param _address ETH address to check for truthiness
     **/
    function inTeam(address _address) public view returns (bool) {
        if (_address == address(0)) revert InvalidTeamAddress();
        return _team[_address];
    }

    /**
     * @dev Throws if called by any account other than the owner or team member.
     */
    function _onlyTeamOrOwner() private view {
        bool _isOwner = owner() == msg.sender;
        bool _isTeam = inTeam(msg.sender);
        require(_isOwner || _isTeam, "Team: caller is not the owner or in Team.");
    }

    modifier onlyTeamOrOwner() {
        _onlyTeamOrOwner();
        _;
    }
}