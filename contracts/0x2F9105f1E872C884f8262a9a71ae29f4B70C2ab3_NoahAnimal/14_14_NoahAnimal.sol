pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NoahAnimal is ERC721, AccessControl {
    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    Counters.Counter private _tokenIdCounter;

    enum animal_species {
        Cat,
        Dog,
        Zebra,
        Ape,
        Lion
    }

    struct AnimalAttributes {
        animal_species species;
        uint256 power;
        uint256 age;
    }

    mapping(uint256 => AnimalAttributes) tokenIdToAttributes;

    constructor() ERC721("NoahAnimal", "NAM") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function mintAnimals(
        address to,
        uint256 stake_amount,
        uint256 age
    ) public onlyRole(MINTER_ROLE) {
        _mintAnimal(to, stake_amount, age);
        _mintAnimal(to, stake_amount, age);
    }

    function _mintAnimal(
        address to,
        uint256 stake_amount,
        uint256 age
    ) private onlyRole(MINTER_ROLE) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);

        animal_species species = animal_species.Cat;
        if (stake_amount >= 1000) {
            species = animal_species.Lion;
        } else if (stake_amount >= 100) {
            species = animal_species.Ape;
        } else if (stake_amount >= 10) {
            species = animal_species.Zebra;
        } else if (stake_amount >= 1) {
            species = animal_species.Dog;
        }

        tokenIdToAttributes[tokenId] = AnimalAttributes({
            species: species,
            power: stake_amount,
            age: age
        });
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function getAttributes(
        uint256 firstTokenId
    ) public view returns (AnimalAttributes memory) {
        return (tokenIdToAttributes[firstTokenId]);
    }
}