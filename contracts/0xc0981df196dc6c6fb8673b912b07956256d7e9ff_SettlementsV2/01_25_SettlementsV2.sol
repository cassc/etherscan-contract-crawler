// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./SettlementsLegacy.sol";
import "./ERC20Mintable.sol";
import "./Helper.sol";
import "hardhat/console.sol";

// @author zeth and out.eth
// @notice This contract is heavily inspired by Dom Hofmann's Loot Project with game design from Sid Meirs Civilisation, DND, Settlers of Catan & Age of Empires.

// Lands allows for the creation of lands of which users have 5 turns to create their perfect civ.
// Randomise will pseduo randomly assign a land a new set of attributes & increase their turn count.
// An allocation of 100 lands are reserved for owner & future expansion packs

contract SettlementsV2 is ERC721, ERC721Enumerable, Ownable {
    struct Attributes {
        uint8 size;
        uint8 spirit;
        uint8 age;
        uint8 resource;
        uint8 morale;
        uint8 government;
        uint8 turns;
    }

    SettlementsLegacy public legacySettlements;
    Helpers public helpersContract;

    ERC20Mintable[] public resourceTokenAddresses;
    mapping(uint256 => uint256) public tokenIdToLastHarvest;
    mapping(uint256 => Attributes) public attrIndex;

    string[] public _sizes = [
        "Camp",
        "Hamlet",
        "Village",
        "Town",
        "District",
        "Precinct",
        "Capitol",
        "State"
    ];
    string[] public _spirits = ["Earth", "Fire", "Water", "Air", "Astral"];
    string[] public _ages = [
        "Ancient",
        "Classical",
        "Medieval",
        "Renaissance",
        "Industrial",
        "Modern",
        "Information",
        "Future"
    ];
    string[] public _resources = [
        "Iron",
        "Gold",
        "Silver",
        "Wood",
        "Wool",
        "Water",
        "Grass",
        "Grain"
    ];
    string[] public _morales = [
        "Expectant",
        "Enlightened",
        "Dismissive",
        "Unhappy",
        "Happy",
        "Undecided",
        "Warring",
        "Scared",
        "Unruly",
        "Anarchist"
    ];
    string[] public _governments = [
        "Democracy",
        "Communism",
        "Socialism",
        "Oligarchy",
        "Aristocracy",
        "Monarchy",
        "Theocracy",
        "Colonialism",
        "Dictatorship"
    ];
    string[] public _realms = ["Genesis", "Valhalla", "Keskella", "Shadow", "Plains", "Ends"];

    constructor(
        SettlementsLegacy _legacyAddress,
        ERC20Mintable ironToken_,
        ERC20Mintable goldToken_,
        ERC20Mintable silverToken_,
        ERC20Mintable woodToken_,
        ERC20Mintable woolToken_,
        ERC20Mintable waterToken_,
        ERC20Mintable grassToken_,
        ERC20Mintable grainToken_
    ) ERC721("Settlements", "STL") {
        legacySettlements = _legacyAddress;
        resourceTokenAddresses = [
            ironToken_,
            goldToken_,
            silverToken_,
            woodToken_,
            woolToken_,
            waterToken_,
            grassToken_,
            grainToken_
        ];
    }

    function setHelpersContract(Helpers helpersContract_) public onlyOwner {
        helpersContract = helpersContract_;
    }

    function indexFor(string memory input, uint256 length) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input))) % length;
    }

    function _getRandomSeed(uint256 tokenId, string memory seedFor)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    seedFor,
                    Strings.toString(tokenId),
                    block.timestamp,
                    block.difficulty
                )
            );
    }

    function generateAttribute(string memory salt, string[] memory items)
        internal
        pure
        returns (uint8)
    {
        return uint8(indexFor(string(salt), items.length));
    }

    function _oldTokenURI(uint256 tokenId) private view returns (string memory) {
        return _tokenURI(tokenId, true);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return _tokenURI(tokenId, false);
    }

    function getUnharvestedTokens(uint256 tokenId) public view returns (ERC20Mintable, uint256) {
        Attributes memory attributes = attrIndex[tokenId];
        return helpersContract.getUnharvestedTokens(tokenId, attributes);
    }

    function _tokenURI(uint256 tokenId, bool useLegacy) private view returns (string memory) {
        require(_exists(tokenId), "Settlement does not exist");

        Helpers.TokenURIInput memory tokenURIInput;

        tokenURIInput.size = _sizes[attrIndex[tokenId].size];
        tokenURIInput.spirit = _spirits[attrIndex[tokenId].spirit];
        tokenURIInput.age = _ages[attrIndex[tokenId].age];
        tokenURIInput.resource = _resources[attrIndex[tokenId].resource];
        tokenURIInput.morale = _morales[attrIndex[tokenId].morale];
        tokenURIInput.government = _governments[attrIndex[tokenId].government];
        tokenURIInput.realm = _realms[attrIndex[tokenId].turns];

        ERC20Mintable tokenContract = resourceTokenAddresses[0];
        uint256 unharvestedTokenAmount = 0;

        if (useLegacy == false) {
            Attributes memory attributes = attrIndex[tokenId];
            (tokenContract, unharvestedTokenAmount) = getUnharvestedTokens(tokenId);
        }

        string memory output = helpersContract.tokenURI(
            tokenURIInput,
            unharvestedTokenAmount,
            tokenContract.symbol(),
            useLegacy,
            tokenId
        );

        return output;
    }

    function randomiseAttributes(uint256 tokenId, uint8 turn) internal {
        attrIndex[tokenId].size = generateAttribute(_getRandomSeed(tokenId, "size"), _sizes);
        attrIndex[tokenId].spirit = generateAttribute(_getRandomSeed(tokenId, "spirit"), _spirits);
        attrIndex[tokenId].age = generateAttribute(_getRandomSeed(tokenId, "age"), _ages);
        attrIndex[tokenId].resource = generateAttribute(
            _getRandomSeed(tokenId, "resource"),
            _resources
        );
        attrIndex[tokenId].morale = generateAttribute(_getRandomSeed(tokenId, "morale"), _morales);
        attrIndex[tokenId].government = generateAttribute(
            _getRandomSeed(tokenId, "government"),
            _governments
        );
        attrIndex[tokenId].turns = turn;
    }

    function randomise(uint256 tokenId) public {
        require(
            _exists(tokenId) && msg.sender == ownerOf(tokenId) && attrIndex[tokenId].turns < 5,
            "Settlement turns over"
        );

        harvest(tokenId);
        randomiseAttributes(tokenId, attrIndex[tokenId].turns + 1);
    }

    function harvest(uint256 tokenId) public {
        (ERC20Mintable tokenAddress, uint256 tokensToMint) = getUnharvestedTokens(tokenId);

        tokenAddress.mint(ownerOf(tokenId), tokensToMint);
        tokenIdToLastHarvest[tokenId] = block.number;
    }

    function multiClaim(uint256[] calldata tokenIds, Attributes[] memory tokenAttributes) public {
        for (uint256 i = 0; i < tokenAttributes.length; i++) {
            claim(tokenIds[i], tokenAttributes[i]);
        }
    }

    function claim(uint256 tokenId, Attributes memory attributes) public {
        legacySettlements.transferFrom(msg.sender, address(this), tokenId);
        _safeMint(msg.sender, tokenId);
        attrIndex[tokenId] = attributes;
        bytes32 v2Uri = keccak256(abi.encodePacked(_oldTokenURI(tokenId)));
        bytes32 legacyURI = keccak256(abi.encodePacked(legacySettlements.tokenURI(tokenId)));

        tokenIdToLastHarvest[tokenId] = block.number;
        require(v2Uri == legacyURI, "Attributes don't match legacy contract");
    }

    function claimAndReroll(uint256 tokenId) public {
        legacySettlements.transferFrom(msg.sender, address(this), tokenId);
        randomiseAttributes(tokenId, 3);
        _safeMint(msg.sender, tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function getSettlementSize(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "Settlement does not exist");
        return _sizes[attrIndex[tokenId].size];
    }

    function getSettlementSpirit(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "Settlement does not exist");
        return _spirits[attrIndex[tokenId].spirit];
    }

    function getSettlementAge(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "Settlement does not exist");
        return _ages[attrIndex[tokenId].age];
    }

    function getSettlementResource(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "Settlement does not exist");
        return _resources[attrIndex[tokenId].resource];
    }

    function getSettlementMorale(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "Settlement does not exist");
        return _morales[attrIndex[tokenId].morale];
    }

    function getSettlementGovernment(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "Settlement does not exist");
        return _governments[attrIndex[tokenId].government];
    }

    function getSettlementRealm(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "Settlement does not exist");
        return _realms[attrIndex[tokenId].turns];
    }
}