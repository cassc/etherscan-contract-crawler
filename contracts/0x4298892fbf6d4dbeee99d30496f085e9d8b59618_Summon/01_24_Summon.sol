// SPDX-License-Identifier: MIT

/// @title RaidParty Party Contract

/**
 *   ___      _    _ ___          _
 *  | _ \__ _(_)__| | _ \__ _ _ _| |_ _  _
 *  |   / _` | / _` |  _/ _` | '_|  _| || |
 *  |_|_\__,_|_\__,_|_| \__,_|_|  \__|\_, |
 *                                    |__/
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../interfaces/IHero.sol";
import "../interfaces/IHeroURIHandler.sol";
import "../interfaces/IFighter.sol";
import "../interfaces/IERC20Burnable.sol";
import "../interfaces/IParty.sol";

contract Summon is AccessControlEnumerable, Pausable {
    uint256 private constant _cost = 100 * 10**18;

    IHero private immutable _hero;
    IFighter private immutable _fighter;
    IERC20Burnable private immutable _confetti;
    IParty private immutable _party;
    address private _team;

    constructor(
        address admin,
        IHero hero,
        IFighter fighter,
        IERC20Burnable confetti,
        IParty party
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _hero = hero;
        _fighter = fighter;
        _confetti = confetti;
        _team = admin;
        _party = party;
        _pause();
    }

    function getCost() external pure returns (uint256) {
        return _cost;
    }

    function getHero() external view returns (address) {
        return address(_hero);
    }

    function getFighter() external view returns (address) {
        return address(_fighter);
    }

    function getConfetti() external view returns (address) {
        return address(_confetti);
    }

    function getTeam() external view returns (address) {
        return _team;
    }

    function setTeam(address team) external {
        require(msg.sender == _team, "Summon::setTeam: caller not owner");
        _team = team;
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function _transferAndMint(address to, uint256 count) internal {
        uint256 cost = _cost * count;
        uint256 teamAmount = (cost * 15) / 100;
        _confetti.transferFrom(msg.sender, _team, teamAmount);
        _confetti.burnFrom(msg.sender, cost - teamAmount);
        _fighter.mint(to, count);
    }

    function mintFighter() external whenNotPaused {
        require(
            _fighter.totalSupply() < 77000,
            "Summon::mintFighter: fighter supply reached"
        );

        _transferAndMint(msg.sender, 1);
    }

    function mintFighters(uint256 count) external whenNotPaused {
        require(
            _fighter.totalSupply() + count < 77000,
            "Summon::mintFighter: fighter supply reached"
        );

        _transferAndMint(msg.sender, count);
    }

    function mintFightersTo(address to, uint256 count) external whenNotPaused {
        require(
            _fighter.totalSupply() + count < 77000,
            "Summon::mintFighter: fighter supply reached"
        );

        _transferAndMint(to, count);
    }

    function mintHero(uint256 proof, uint256[] calldata burnIds)
        external
        whenNotPaused
    {
        require(
            _hero.totalSupply() < 22000,
            "Summon::mintHero: hero supply reached"
        );

        uint256 fighterCost;
        bool isGenesis;
        if (proof <= 1111) {
            require(
                _party.getUserHero(msg.sender) == proof ||
                    _hero.ownerOf(proof) == msg.sender,
                "Summon::mintHero: invalid proof"
            );
            isGenesis = true;
        }

        if (isGenesis) {
            fighterCost = 15;
        } else {
            fighterCost = 20;
        }

        require(
            burnIds.length == fighterCost,
            "Summon::mintHero: mismatched burn token array length"
        );

        for (uint256 i = 0; i < burnIds.length; i++) {
            require(
                _fighter.ownerOf(burnIds[i]) == msg.sender,
                "Summon::mintHero: fighter not owned by sender"
            );
            _fighter.burn(burnIds[i]);
        }

        uint256 teamAmount = (_cost * 15) / 100;
        _confetti.transferFrom(msg.sender, _team, teamAmount);
        _confetti.burnFrom(msg.sender, _cost - teamAmount);
        _hero.mint(msg.sender, 1);
    }
}