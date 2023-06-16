// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./AnonymiceLibrary.sol";
import "./RedactedLibrary.sol";
import "./Interfaces.sol";

contract DNAChip is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using AnonymiceLibrary for uint8;

    uint256 public constant MAX_SUPPLY = 2000;
    uint8 public constant BASE_INDEX = 0;
    uint8 public constant EARRINGS_INDEX = 1;
    uint8 public constant EYES_INDEX = 2;
    uint8 public constant HATS_INDEX = 3;
    uint8 public constant MOUTHS_INDEX = 4;
    uint8 public constant NECKS_INDEX = 5;
    uint8 public constant NOSES_INDEX = 6;
    uint8 public constant WHISKERS_INDEX = 7;

    struct Traits {
        uint8 base;
        uint8 earrings;
        uint8 eyes;
        uint8 hats;
        uint8 mouths;
        uint8 necks;
        uint8 noses;
        uint8 whiskers;
    }

    uint16[] public BASE;
    mapping(uint8 => uint16[][8]) private _traitsByBase;

    address public breedingAddress;
    address public podFragmentAddress;
    address public cheethAddress;
    address public descriptorAddress;
    uint256 public seedNonce = 0;
    uint256 public dnaRolls;
    bool public isMintEnabled;
    mapping(uint256 => bool) public usedEvolutionPods;
    mapping(uint256 => bool) public isEvolutionPod;
    mapping(uint256 => uint256) public breedingIdToEvolutionPod;
    mapping(uint256 => uint256) public evolutionPodToBreedingId;
    mapping(uint256 => uint256) public tokenIdToTraits;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("DNAChip", "DNA") {
        // Freak, Robot, Druid, Skele, Alien
        BASE = [387, 387, 100, 100, 26];

        _traitsByBase[0][BASE_INDEX] = [387, 387, 100, 100, 26];
        _traitsByBase[1][BASE_INDEX] = [387, 387, 100, 100, 26];
        _traitsByBase[2][BASE_INDEX] = [387, 387, 100, 100, 26];
        _traitsByBase[3][BASE_INDEX] = [387, 387, 100, 100, 26];
        _traitsByBase[4][BASE_INDEX] = [387, 387, 100, 100, 26];

        _traitsByBase[0][EARRINGS_INDEX] = [900, 80, 20];
        _traitsByBase[1][EARRINGS_INDEX] = [900, 80, 20];
        _traitsByBase[2][EARRINGS_INDEX] = [750, 200, 50];
        _traitsByBase[3][EARRINGS_INDEX] = [750, 200, 50];
        _traitsByBase[4][EARRINGS_INDEX] = [600, 300, 100];

        _traitsByBase[0][EYES_INDEX] = [320, 320, 100, 70, 70, 50, 50, 20];
        _traitsByBase[1][EYES_INDEX] = [320, 320, 100, 70, 70, 50, 50, 20];
        _traitsByBase[2][EYES_INDEX] = [255, 255, 120, 90, 90, 70, 70, 50];
        _traitsByBase[3][EYES_INDEX] = [255, 255, 120, 90, 90, 70, 70, 50];
        _traitsByBase[4][EYES_INDEX] = [170, 170, 140, 120, 120, 100, 100, 80];

        _traitsByBase[0][HATS_INDEX] = [320, 125, 125, 110, 110, 65, 65, 40, 25, 15];
        _traitsByBase[1][HATS_INDEX] = [320, 125, 125, 110, 110, 65, 65, 40, 25, 15];
        _traitsByBase[2][HATS_INDEX] = [260, 140, 140, 100, 100, 60, 60, 50, 50, 40];
        _traitsByBase[3][HATS_INDEX] = [260, 140, 140, 100, 100, 60, 60, 50, 50, 40];
        _traitsByBase[4][HATS_INDEX] = [175, 110, 110, 100, 100, 90, 90, 90, 75, 60];

        _traitsByBase[0][MOUTHS_INDEX] = [150, 150, 150, 150, 150, 150, 100];
        _traitsByBase[1][MOUTHS_INDEX] = [150, 150, 150, 150, 150, 150, 100];
        _traitsByBase[2][MOUTHS_INDEX] = [150, 150, 150, 150, 150, 150, 100];
        _traitsByBase[3][MOUTHS_INDEX] = [150, 150, 150, 150, 150, 150, 100];
        _traitsByBase[4][MOUTHS_INDEX] = [150, 150, 150, 150, 150, 150, 100];

        _traitsByBase[0][NECKS_INDEX] = [720, 200, 80];
        _traitsByBase[1][NECKS_INDEX] = [720, 200, 80];
        _traitsByBase[2][NECKS_INDEX] = [630, 250, 120];
        _traitsByBase[3][NECKS_INDEX] = [630, 250, 120];
        _traitsByBase[4][NECKS_INDEX] = [550, 300, 150];

        _traitsByBase[0][NOSES_INDEX] = [200, 200, 200, 200, 200];
        _traitsByBase[1][NOSES_INDEX] = [200, 200, 200, 200, 200];
        _traitsByBase[2][NOSES_INDEX] = [200, 200, 200, 200, 200];
        _traitsByBase[3][NOSES_INDEX] = [200, 200, 200, 200, 200];
        _traitsByBase[4][NOSES_INDEX] = [200, 200, 200, 200, 200];

        _traitsByBase[0][WHISKERS_INDEX] = [220, 220, 220, 220, 120];
        _traitsByBase[1][WHISKERS_INDEX] = [220, 220, 220, 220, 120];
        _traitsByBase[2][WHISKERS_INDEX] = [220, 220, 220, 220, 120];
        _traitsByBase[3][WHISKERS_INDEX] = [220, 220, 220, 220, 120];
        _traitsByBase[4][WHISKERS_INDEX] = [220, 220, 220, 220, 120];
    }

    function mint() external {
        require(!AnonymiceLibrary.isContract(msg.sender), "no cheaters");
        require(isMintEnabled, "mint not enabled");
        require(dnaRolls < MAX_SUPPLY, "max supply");
        ERC20Burnable(cheethAddress).transferFrom(msg.sender, address(this), getPrice());
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _randomizeChip(tokenId);
        _safeMint(msg.sender, tokenId);
    }

    function reroll(uint256 tokenId) external {
        require(!AnonymiceLibrary.isContract(msg.sender), "no cheaters");
        require(dnaRolls < MAX_SUPPLY, "max supply");
        require(msg.sender == ownerOf(tokenId), "not allowed");

        _randomizeChip(tokenId);
    }

    function assembleEvolutionPod(uint256 tokenId) external {
        require(!AnonymiceLibrary.isContract(msg.sender), "no cheaters");
        require(msg.sender == ownerOf(tokenId), "not allowed");
        require(!isEvolutionPod[tokenId], "already assembled");
        isEvolutionPod[tokenId] = true;
        ERC1155Burnable(podFragmentAddress).burn(msg.sender, 1, 3);
    }

    function evolveBreedingMouse(uint256 tokenId, uint256 breedingMouseId) external {
        require(!AnonymiceLibrary.isContract(msg.sender), "no cheaters");
        require(isEvolutionPod[tokenId], "not assembled");
        require(!usedEvolutionPods[tokenId], "already used");
        require(msg.sender == ownerOf(tokenId), "not allowed");
        require(IERC721Enumerable(breedingAddress).ownerOf(breedingMouseId) == msg.sender, "not allowed");
        breedingIdToEvolutionPod[breedingMouseId] = tokenId;
        evolutionPodToBreedingId[tokenId] = breedingMouseId;
        usedEvolutionPods[tokenId] = true;
        _burn(tokenId);
    }

    // GETTERS

    function getPrice() public pure returns (uint256) {
        return 1000 ether;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return IDescriptor(descriptorAddress).tokenURI(_tokenId);
    }

    function getTraitsRepresentation(uint256 _tokenId) public view returns (uint256) {
        return tokenIdToTraits[_tokenId];
    }

    function getTraits(uint256 _tokenId) public view returns (RedactedLibrary.Traits memory) {
        return RedactedLibrary.representationToTraits(tokenIdToTraits[_tokenId]);
    }

    function getTraitsArray(uint256 _tokenId) public view returns (uint8[8] memory) {
        return RedactedLibrary.representationToTraitsArray(tokenIdToTraits[_tokenId]);
    }

    // OWNER FUNCTIONS

    function setAddresses(
        address _podFragmentAddress,
        address _breedingAddress,
        address _cheethAddress,
        address _descriptorAddress
    ) external onlyOwner {
        podFragmentAddress = _podFragmentAddress;
        breedingAddress = _breedingAddress;
        cheethAddress = _cheethAddress;
        descriptorAddress = _descriptorAddress;
    }

    function withdraw(address to) external onlyOwner {
        ERC20Burnable(cheethAddress).transfer(to, ERC20Burnable(cheethAddress).balanceOf(address(this)));
    }

    function setIsMintEnabled(bool value) external onlyOwner {
        isMintEnabled = value;
    }

    // PRIVATE FUNCTIONS

    function _randomizeChip(uint256 tokenId) internal {
        require(!isEvolutionPod[tokenId], "already assembled");
        dnaRolls++;
        tokenIdToTraits[tokenId] = RedactedLibrary.traitsToRepresentation(_generateTraits(tokenId));
    }

    function _rarityGen(uint256 _randinput, uint16[] memory _percentages) internal pure returns (uint8) {
        uint16 currentLowerBound = 0;
        for (uint8 i = 0; i < _percentages.length; i++) {
            uint16 thisPercentage = _percentages[i];
            if (_randinput >= currentLowerBound && _randinput < currentLowerBound + thisPercentage) return i;
            currentLowerBound = currentLowerBound + thisPercentage;
        }

        revert("rarity gen failed");
    }

    function _getRandomNumber(uint256 _tokenId, uint256 limit) internal returns (uint256) {
        seedNonce++;

        return
            uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, _tokenId, msg.sender, seedNonce))) %
            limit;
    }

    function _generateTraits(uint256 tokenId) internal returns (RedactedLibrary.Traits memory traits) {
        uint8 base = _rarityGen(_getRandomNumber(tokenId, 1000), BASE);
        uint16[][8] memory traitProbabilites = _traitsByBase[base];

        traits.base = base;
        traits.earrings = _rarityGen(_getRandomNumber(tokenId, 1000), traitProbabilites[EARRINGS_INDEX]);
        traits.eyes = _rarityGen(_getRandomNumber(tokenId, 1000), traitProbabilites[EYES_INDEX]);
        traits.hats = _rarityGen(_getRandomNumber(tokenId, 1000), traitProbabilites[HATS_INDEX]);
        traits.mouths = _rarityGen(_getRandomNumber(tokenId, 1000), traitProbabilites[MOUTHS_INDEX]);
        traits.necks = _rarityGen(_getRandomNumber(tokenId, 1000), traitProbabilites[NECKS_INDEX]);
        traits.noses = _rarityGen(_getRandomNumber(tokenId, 1000), traitProbabilites[NOSES_INDEX]);
        traits.whiskers = _rarityGen(_getRandomNumber(tokenId, 1000), traitProbabilites[WHISKERS_INDEX]);
    }
}