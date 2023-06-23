// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/contracts/token/ERC721/ERC721.sol";

struct Freaker {
    uint8 species;
    uint8 stamina;
    uint8 fortune;
    uint8 agility;
    uint8 offense;
    uint8 defense;
}

struct EnergyBalance {
    uint128 basic;
    uint128 index;
}

struct CombatMultipliers {
    uint128 attack;
    uint128 defend;
}

struct SpeciesCounter {
    int32 pluto;
    int32 mercury;
    int32 saturn;
    int32 uranus;
    int32 venus;
    int32 mars;
    int32 neptune;
    int32 jupiter;
}

contract EtherFreakers is ERC721 {
    /// Number of tokens in existence.
    uint128 public numTokens;

    /// Record of energy costs paid for birthing.
    uint256[] public birthCertificates;

    /// Index for the creator energy pool.
    uint128 public creatorIndex;

    /// Index for the freaker energy pool.
    uint128 public freakerIndex;

    /// Total freaker shares.
    uint128 public totalFortune;

    /// Mapping from freaker id to freaker.
    mapping(uint128 => Freaker) public freakers;

    /// Mapping from token id to energy balance.
    mapping(uint128 => EnergyBalance) public energyBalances;

    /// Mapping from account to aggregate multipliers.
    mapping(address => CombatMultipliers) public combatMultipliers;

    /// Mapping from account to count of each species.
    mapping(address => SpeciesCounter) public speciesCounters;

    event Born(address mother, uint128 energy, uint128 indexed freakerId, Freaker freaker);
    event Missed(address attacker, address defender, uint128 indexed sourceId, uint128 indexed targetId);
    event Thwarted(address attacker, address defender, uint128 indexed sourceId, uint128 indexed targetId);
    event Captured(address attacker, address defender, uint128 indexed sourceId, uint128 indexed targetId);

    /**
     * @notice Construct the EtherFreakers contract.
     * @param author Jared's address.
     */
    constructor(address author) ERC721("EtherFreakers", "EFKR") {
        for (uint i = 0; i < 8; i++) {
            _mint(author, numTokens++);
        }
    }

    /**
     * @notice Base URI for computing {tokenURI}.
     * @dev EtherFreakers original art algorithm commit hash:
     *  fe61dab48fa91cc298438862652116469fe663ea
     */
    function _baseURI() internal pure override returns (string memory) {
        return "https://ether.freakers.art/m/";
    }

    /**
     * @notice Birth a new freaker, given enough energy.
     */
    function birth() payable public {
        birthTo(payable(msg.sender));
    }

    /**
     * @notice Birth a new freaker, given enough energy.
     * @param to Recipient's address
     */
    function birthTo(address payable to) payable public {
        // Roughly
        //  pick species
        //   0 (1x) ->
        //    fortune / offense
        //   1 (2x) ->
        //    fortune / defense
        //   2 (2x) ->
        //    fortune / agility
        //   3 (3x) ->
        //    offense / defense
        //   4 (3x) ->
        //    defense / offense
        //   5 (4x) ->
        //    agility / offense
        //   6 (4x) ->
        //    agility / defense
        //   7 (1x) ->
        //    defense / agility
        //  pick stamina: [0, 9]
        //  pick fortune, agility, offense, defense based on species: [1, 10]
        //   primary = 300% max
        //   secondary = 200% max

        uint256 middle = middlePrice();
        require(msg.value > middle * 1005 / 1000, "Not enough energy");

        uint128 freakerId = numTokens++;
        uint8 speciesDie = uint8(_randomishIntLessThan("species", 20));
        uint8 species = (
         (speciesDie < 1 ? 0 :
          (speciesDie < 3 ? 1 :
           (speciesDie < 5 ? 2 :
            (speciesDie < 8 ? 3 :
             (speciesDie < 11 ? 4 :
              (speciesDie < 15 ? 5 :
               (speciesDie < 19 ? 6 : 7))))))));

        uint8 stamina = uint8(_randomishIntLessThan("stamina", 10));
        uint8 fortune = uint8(_randomishIntLessThan("fortune", species < 3 ? 30 : 10) + 1);
        uint8 agility = uint8(_randomishIntLessThan("agility",
         (species == 5 || species == 6 ? 30 :
          (species == 2 || species == 7 ? 20 : 10))) + 1);
        uint8 offense = uint8(_randomishIntLessThan("offense",
         (species == 3 ? 30 :
          (species == 0 || species == 4 || species == 5 ? 20 : 10))) + 1);
        uint8 defense = uint8(_randomishIntLessThan("defense",
         (species == 4 || species == 7 ? 30 :
          (species == 1 || species == 4 || species == 6 ? 20 : 10))) + 1);

        Freaker memory freaker = Freaker({
            species: species,
            stamina: stamina,
            fortune: fortune,
            agility: agility,
            offense: offense,
            defense: defense
          });
        freakers[freakerId] = freaker;

        uint128 value = uint128(msg.value);
        uint128 half = value / 2;
        _dissipateEnergyIntoPool(half);
        energyBalances[freakerId] = EnergyBalance({
            basic: half,
            index: freakerIndex
          });
        totalFortune += fortune;

        birthCertificates.push(msg.value);

        emit Born(to, value, freakerId, freaker);
        _safeMint(to, freakerId, "");
    }

    /**
     * @notice Attempt to capture another owner's freaker.
     * @param sourceId The freaker launching the attack.
     * @param targetId The freaker being attacked.
     * @return Whether or not the attack was successful.
     */
    function attack(uint128 sourceId, uint128 targetId) public returns (bool) {
        address attacker = ownerOf(sourceId);
        address defender = ownerOf(targetId);
        require(attacker != defender, "Cannot attack self");
        require(attacker == msg.sender, "Sender does not own source");

        if (isEnlightened(sourceId) || isEnlightened(targetId)) {
            revert("Enlightened beings can neither attack nor be attacked");
        }

        Freaker memory source = freakers[sourceId];
        Freaker memory target = freakers[targetId];

        if (_randomishIntLessThan("hit?", source.agility + target.agility) > source.agility) {
            // source loses energy:
            //  0.1% - 1% (0.1% * (10 - stamina))
            uint128 sourceCharge = energyOf(sourceId);
            uint128 sourceSpent = sourceCharge * (1 * (10 - source.stamina)) / 1000;
            energyBalances[sourceId] = EnergyBalance({
                basic: sourceCharge - sourceSpent,
                index: freakerIndex
              });
            _dissipateEnergyIntoPool(sourceSpent);
            emit Missed(attacker, defender, sourceId, targetId);
            return false;
        }

        if (_randomishIntLessThan("win?", attackPower(sourceId)) < defendPower(targetId)) {
            // both source and target lose energy:
            //  1% - 10% (1% * (10 - stamina))
            uint128 sourceCharge = energyOf(sourceId);
            uint128 targetCharge = energyOf(targetId);
            uint128 sourceSpent = sourceCharge * (1 * (10 - source.stamina)) / 100;
            uint128 targetSpent = targetCharge * (1 * (10 - target.stamina)) / 100;
            energyBalances[sourceId] = EnergyBalance({
                basic: sourceCharge - sourceSpent,
                index: freakerIndex
              });
            energyBalances[targetId] = EnergyBalance({
                basic: targetCharge - targetSpent,
                index: freakerIndex
              });
            _dissipateEnergyIntoPool(sourceSpent);
            _dissipateEnergyIntoPool(targetSpent);
            emit Thwarted(attacker, defender, sourceId, targetId);
            return false;
        } else {
            // source loses energy
            //  2% - 20% (2% * (10 - stamina))
            // return target charge to target owner, if we can
            // transfer target to source owner
            // remaining source energy is split in half and given to target
            uint128 sourceCharge = energyOf(sourceId);
            uint128 targetCharge = energyOf(targetId);
            uint128 sourceSpent = sourceCharge * (2 * (10 - source.stamina)) / 100;
            uint128 sourceRemaining = sourceCharge - sourceSpent;
            if (!payable(defender).send(targetCharge)) {
                creatorIndex += targetCharge / 8;
            }
            _transfer(defender, attacker, targetId);
            _dissipateEnergyIntoPool(sourceSpent);

            uint128 half = sourceRemaining / 2;
            energyBalances[sourceId] = EnergyBalance({
                basic: half,
                index: freakerIndex
              });
            energyBalances[targetId] = EnergyBalance({
                basic: half,
                index: freakerIndex
              });

            emit Captured(attacker, defender, sourceId, targetId);
            return true;
        }
    }

    /**
     * @notice Draw upon a creator's share of energy.
     * @param creatorId The token id of the creator to tap.
     */
    function tap(uint128 creatorId) public {
        require(isCreator(creatorId), "Not a creator");
        address owner = ownerOf(creatorId);
        uint128 unclaimed = creatorIndex - energyBalances[creatorId].index;
        energyBalances[creatorId].index = creatorIndex;
        payable(owner).transfer(unclaimed);
    }

    /**
     * @notice Store energy on a freaker.
     * @param freakerId The token id of the freaker to charge.
     */
    function charge(uint128 freakerId) payable public {
        address owner = ownerOf(freakerId);
        require(msg.sender == owner, "Sender does not own freaker");
        require(isFreaker(freakerId), "Not a freaker");
        EnergyBalance memory balance = energyBalances[freakerId];
        energyBalances[freakerId] = EnergyBalance({
            basic: balance.basic + uint128(msg.value),
            index: balance.index
          });
    }

    /**
     * @notice Withdraw energy from a freaker.
     * @param freakerId The token id of the freaker to discharge.
     * @param amount The amount of energy (Ether) to discharge, capped to max.
     */
    function discharge(uint128 freakerId, uint128 amount) public {
        address owner = ownerOf(freakerId);
        require(msg.sender == owner, "Sender does not own freaker");
        require(isFreaker(freakerId), "Not a freaker");
        uint128 energy = energyOf(freakerId);
        uint128 capped = amount > energy ? energy : amount;
        energyBalances[freakerId] = EnergyBalance({
            basic: energy - capped,
            index: freakerIndex
          });
        payable(owner).transfer(capped);
    }

    function isCreator(uint256 tokenId) public pure returns (bool) { return tokenId < 8; }
    function isFreaker(uint256 tokenId) public pure returns (bool) { return tokenId >= 8; }

    function isEnlightened(uint128 tokenId) public view returns (bool) {
        if (isCreator(tokenId)) {
            return true;
        }
        address owner = ownerOf(tokenId);
        SpeciesCounter memory c = speciesCounters[owner];
        return (
         c.pluto > 0 && c.mercury > 0 && c.saturn > 0 && c.uranus > 0 &&
         c.venus > 0 && c.mars > 0 && c.neptune > 0 && c.jupiter > 0
        );
    }

    function energyOf(uint128 tokenId) public view returns (uint128) {
        if (isCreator(tokenId)) {
            EnergyBalance memory balance = energyBalances[tokenId];
            return balance.basic + (creatorIndex - balance.index);
        } else {
            Freaker memory freaker = freakers[tokenId];
            EnergyBalance memory balance = energyBalances[tokenId];
            return balance.basic + (freakerIndex - balance.index) * freaker.fortune;
        }
    }

    function attackPower(uint128 freakerId) public view returns (uint128) {
        address attacker = ownerOf(freakerId);
        return combatMultipliers[attacker].attack * energyOf(freakerId);
    }

    function defendPower(uint128 freakerId) public view returns (uint128) {
        address defender = ownerOf(freakerId);
        return combatMultipliers[defender].defend * energyOf(freakerId);
    }

    function middlePrice() public view returns (uint256) {
        uint256 length = birthCertificates.length;
        return length > 0 ? birthCertificates[length / 2] : 0;
    }

    function _randomishIntLessThan(bytes32 salt, uint256 n) internal view returns (uint256) {
        if (n == 0)
            return 0;
        return uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, salt))) % n;
    }

    function _dissipateEnergyIntoPool(uint128 amount) internal {
        if (amount > 0) {
            if (totalFortune > 0) {
                uint128 creatorAmount = amount * 20 / 100;
                uint128 freakerAmount = amount * 80 / 100;
                creatorIndex += creatorAmount / 8;
                freakerIndex += freakerAmount / totalFortune;
            } else {
                creatorIndex += amount / 8;
            }
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        if (isFreaker(tokenId)) {
            uint128 freakerId = uint128(tokenId);
            Freaker memory freaker = freakers[freakerId];

            if (from != address(0)) {
                CombatMultipliers memory multipliers = combatMultipliers[from];
                combatMultipliers[from] = CombatMultipliers({
                    attack: multipliers.attack - freaker.offense * uint128(freaker.offense),
                    defend: multipliers.defend - freaker.defense * uint128(freaker.defense)
                  });
                _countSpecies(from, freaker.species, -1);
            }

            if (to != address(0)) {
                CombatMultipliers memory multipliers = combatMultipliers[to];
                combatMultipliers[to] = CombatMultipliers({
                    attack: multipliers.attack + freaker.offense * uint128(freaker.offense),
                    defend: multipliers.defend + freaker.defense * uint128(freaker.defense)
                  });
                _countSpecies(to, freaker.species, 1);
            }

            if (from != address(0) && to != address(0)) {
                uint128 freakerCharge = energyOf(freakerId);
                uint128 freakerSpent = freakerCharge / 1000;
                energyBalances[freakerId] = EnergyBalance({
                    basic: freakerCharge - freakerSpent,
                    index: freakerIndex
                  });
                _dissipateEnergyIntoPool(freakerSpent);
            }
        }
    }

    function _countSpecies(address account, uint8 species, int8 delta) internal {
        if (species < 4) {
            if (species < 2) {
                if (species == 0) {
                    speciesCounters[account].pluto += delta;
                } else {
                    speciesCounters[account].mercury += delta;
                }
            } else {
                if (species == 2) {
                    speciesCounters[account].saturn += delta;
                } else {
                    speciesCounters[account].uranus += delta;
                }
            }
        } else {
            if (species < 6) {
                if (species == 4) {
                    speciesCounters[account].venus += delta;
                } else {
                    speciesCounters[account].mars += delta;
                }
            } else {
                if (species == 6) {
                    speciesCounters[account].neptune += delta;
                } else {
                    speciesCounters[account].jupiter += delta;
                }
            }
        }
    }
}