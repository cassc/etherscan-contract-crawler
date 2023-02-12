// SPDX-License-Identifier: MIT
//
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract OLoot is
    ERC721A,
    ERC721ABurnable,
    DefaultOperatorFilterer,
    Pausable,
    ReentrancyGuard,
    Ownable,
    ERC2981
{
    mapping(uint256 => string) private _burnedTokens;

    uint256 public MINT_PRICE = 0.0333 ether;

    uint16 public MAX_SUPPLY = 7779;

    uint8 public ORDINAL_BTC_ADDRESS_LEN = 62;
    uint8 public MAX_MINT_PER_TX = 10;
    uint8 public MAX_PER_WALLET = 20;

    bool public ARE_BURNS_ALLOWED = false;

    constructor() ERC721A("oLoot", "OLOOT") {
        _setDefaultRoyalty(msg.sender, 690);
        _pause();
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function mint(uint8 num) external payable whenNotPaused nonReentrant {
        require(msg.value >= MINT_PRICE * num, "Send more ETH");
        require(num <= MAX_MINT_PER_TX, "Limit 10 per transaction");
        uint256 totalMinted = _totalMinted();
        require(num + totalMinted <= MAX_SUPPLY, "Cannot mint past max supply");
        uint256 mintedByWallet = _numberMinted(msg.sender);
        require(mintedByWallet + num <= MAX_PER_WALLET, "Limit 20 per wallet");
        require(msg.sender == tx.origin, "Are you human?");
        _mint(msg.sender, num);
    }

    function reserve(uint8 num) external onlyOwner {
        uint256 totalMinted = _totalMinted();
        require(num + totalMinted <= MAX_SUPPLY, "Cannot mint past max supply");
        _mint(msg.sender, num);
    }

    function ordBurn(uint256 tokenId, string memory destAddress) public {
        require(ARE_BURNS_ALLOWED, "Burns are not enabled");
        require(
            bytes(destAddress).length == ORDINAL_BTC_ADDRESS_LEN,
            "Only taproot addresses can receive ordinals"
        );
        _burnedTokens[tokenId] = destAddress;
        burn(tokenId);
    }

    function getMintCountOfAddress(address addr) external view returns (uint256) {
        return _numberMinted(addr);
    }

    function getOrdBurnDestAddress(uint256 tokenId)
        external
        view
        returns (string memory)
    {
        return _burnedTokens[tokenId];
    }

    function toggleBurns() public onlyOwner {
        ARE_BURNS_ALLOWED = !ARE_BURNS_ALLOWED;
    }

    function setMaxSupply(uint16 newSupply) public onlyOwner {
        require(newSupply <= 7779, "Increasing supply not allowed");
        MAX_SUPPLY = newSupply;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC721A, ERC721A, ERC2981)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function withdraw() external onlyOwner {
        uint256 _balance = address(this).balance;
        payable(msg.sender).transfer(_balance);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        public
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getWeapon(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "OLOOTWEAPON", weapons);
    }

    function getChest(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "OLOOTCHEST", chestArmor);
    }

    function getHead(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "OLOOTHEAD", headArmor);
    }

    function getWaist(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "OLOOTWAIST", waistArmor);
    }

    function getFoot(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "OLOOTFOOT", footArmor);
    }

    function getHand(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "OLOOTHAND", handArmor);
    }

    function getNeck(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "OLOOTNECK", necklaces);
    }

    function getRing(uint256 tokenId) public view returns (string memory) {
        return pluck(tokenId, "OLOOTRING", rings);
    }

    function pluck(
        uint256 tokenId,
        string memory keyPrefix,
        string[] memory sourceArray
    ) internal view returns (string memory) {
        uint256 rand = random(
            string(abi.encodePacked(keyPrefix, _toString(tokenId)))
        );
        string memory output = sourceArray[rand % sourceArray.length];
        uint256 greatness = rand % 21;
        if (greatness > 14) {
            output = string(
                abi.encodePacked(output, " ", suffixes[rand % suffixes.length])
            );
        }
        if (greatness >= 19) {
            string[2] memory name;
            name[0] = namePrefixes[rand % namePrefixes.length];
            name[1] = nameSuffixes[rand % nameSuffixes.length];
            if (greatness == 19) {
                output = string(
                    abi.encodePacked('"', name[0], " ", name[1], '" ', output)
                );
            } else {
                output = string(
                    abi.encodePacked(
                        '"',
                        name[0],
                        " ",
                        name[1],
                        '" ',
                        output,
                        " +1"
                    )
                );
            }
        }
        return output;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(IERC721A, ERC721A)
        returns (string memory)
    {
        string[18] memory parts;
        parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

        parts[1] = getWeapon(tokenId);

        parts[2] = '</text><text x="10" y="40" class="base">';

        parts[3] = getChest(tokenId);

        parts[4] = '</text><text x="10" y="60" class="base">';

        parts[5] = getHead(tokenId);

        parts[6] = '</text><text x="10" y="80" class="base">';

        parts[7] = getWaist(tokenId);

        parts[8] = '</text><text x="10" y="100" class="base">';

        parts[9] = getFoot(tokenId);

        parts[10] = '</text><text x="10" y="120" class="base">';

        parts[11] = getHand(tokenId);

        parts[12] = '</text><text x="10" y="140" class="base">';

        parts[13] = getNeck(tokenId);

        parts[14] = '</text><text x="10" y="160" class="base">';

        parts[15] = getRing(tokenId);

        parts[16] = "</text>";

        parts[
            17
        ] = '<ellipse style="fill:#535353;fill-opacity:.82901555" cx="320.74557" cy="319.29968" rx="18.555529" ry="19.519451" /><path fill="#ffffff" fill-rule="nonzero" d="m 326.49329,316.50911 c -0.67642,2.29832 -4.8022,1.12021 -6.14142,0.83892 l 1.18339,-4.02165 c 1.31876,0.27592 5.63446,0.80416 4.93758,3.18273 z m -0.7373,6.49866 c -0.73048,2.50433 -5.69485,1.14916 -7.30484,0.80954 l 1.30513,-4.44109 c 1.60998,0.34458 6.7638,1.01678 5.99971,3.63155 z m 5.41094,-6.46391 c 0.42611,-2.44765 -1.76534,-3.7631 -4.73451,-4.63634 l 0.97398,-3.31511 -2.40086,-0.5055 -0.94671,3.22906 c -0.62237,-0.13196 -1.26471,-0.25854 -1.90071,-0.37933 l 0.9467,-3.26339 -2.37407,-0.5055 -0.97399,3.3151 -1.51501,-0.28708 -3.28037,-0.69537 -0.62919,2.15478 c 0,0 1.75852,0.34457 1.72492,0.36775 0.67156,0.0691 1.16147,0.57581 1.10936,1.14915 l -1.10936,3.77469 c 0.0833,0.0161 0.16509,0.0389 0.2435,0.0691 l -0.25031,-0.0575 -1.54912,5.29158 c -0.14513,0.38719 -0.63211,0.60023 -1.08842,0.47696 h -4.9e-4 c 0,0.0286 -1.73173,-0.36195 -1.73173,-0.36195 l -1.17705,2.29831 3.09091,0.64946 1.69083,0.37353 -0.98079,3.34944 2.37407,0.5055 0.97398,-3.3151 c 0.6399,0.14933 1.26958,0.28708 1.88708,0.41366 l -0.96034,3.32669 2.37408,0.4997 0.98079,-3.34364 c 4.05808,0.64987 7.09495,0.3905 8.38011,-2.72316 1.03485,-2.50514 -0.0541,-3.94718 -2.18463,-4.88951 1.55544,-0.30445 2.70571,-1.14915 3.03686,-2.96473 z" style="stroke-width:.0448832;fill:#fff;fill-opacity:.75352114" /></svg>';

        string memory output = string(
            abi.encodePacked(
                parts[0],
                parts[1],
                parts[2],
                parts[3],
                parts[4],
                parts[5],
                parts[6],
                parts[7],
                parts[8]
            )
        );
        output = string(
            abi.encodePacked(
                output,
                parts[9],
                parts[10],
                parts[11],
                parts[12],
                parts[13],
                parts[14],
                parts[15],
                parts[16],
                parts[17]
            )
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Bag #',
                        _toString(tokenId),
                        '", "description": "oLoot is randomized adventurer gear generated and stored on chain across ETH and BTC. Stats, images, and other functionality are intentionally omitted for others to interpret.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    string[] private weapons = [
        "Warhammer",
        "Quarterstaff",
        "Maul",
        "Mace",
        "Club",
        "Katana",
        "Tongue Flick Of Death",
        "Scimitar",
        "Long Sword",
        "Short Sword",
        "Ghost Wand",
        "Grave Wand",
        "Bone Wand",
        "Wand",
        "Grimoire",
        "Chronicle",
        "Froggo Laser Eyes",
        "Book"
    ];

    string[] private chestArmor = [
        "Divine Robe",
        "Silk Robe",
        "Linen Robe",
        "Robe",
        "Shirt",
        "Demon Husk",
        "Dragonskin Armor",
        "Studded Leather Armor",
        "Hard Leather Armor",
        "Leather Armor",
        "Holy Chestplate",
        "Ornate Chestplate",
        "Plate Mail",
        "Chain Mail",
        "Ring Mail"
    ];

    string[] private headArmor = [
        "Ancient Helm",
        "Ornate Helm",
        "Great Helm",
        "Full Helm",
        "Helm",
        "Demon Crown",
        "Dragon's Crown",
        "War Cap",
        "Leather Cap",
        "Cap",
        "Crown",
        "Divine Hood",
        "Silk Hood",
        "Linen Hood",
        "Hood"
    ];

    string[] private waistArmor = [
        "Ornate Belt",
        "War Belt",
        "Plated Belt",
        "Mesh Belt",
        "Heavy Belt",
        "Demonhide Belt",
        "Dragonskin Belt",
        "Studded Leather Belt",
        "Hard Leather Belt",
        "Leather Belt",
        "Brightsilk Sash",
        "Silk Sash",
        "Wool Sash",
        "Linen Sash",
        "Sash"
    ];

    string[] private footArmor = [
        "Holy Greaves",
        "Ornate Greaves",
        "Greaves",
        "Chain Boots",
        "Heavy Boots",
        "Demonhide Boots",
        "Dragonskin Boots",
        "Studded Leather Boots",
        "Hard Leather Boots",
        "Leather Boots",
        "Divine Slippers",
        "Silk Slippers",
        "Wool Shoes",
        "Linen Shoes",
        "Lily Pads"
    ];

    string[] private handArmor = [
        "Holy Gauntlets",
        "Ornate Gauntlets",
        "Gauntlets",
        "Chain Gloves",
        "Heavy Gloves",
        "Demon's Hands",
        "Dragonskin Gloves",
        "Studded Leather Gloves",
        "Hard Leather Gloves",
        "Leather Gloves",
        "Divine Gloves",
        "Silk Gloves",
        "Wool Gloves",
        "Linen Gloves",
        "Four Finger Death Punch"
    ];

    string[] private necklaces = ["Necklace", "Amulet", "Pendant"];

    string[] private rings = [
        "Gold Ring",
        "Silver Ring",
        "Bronze Ring",
        "Platinum Ring",
        "Titanium Ring"
    ];

    string[] private suffixes = [
        "of Power",
        "of Giants",
        "of Titans",
        "of Skill",
        "of Perfection",
        "of Brilliance",
        "of Enlightenment",
        "of Protection",
        "of Anger",
        "of Rage",
        "of Furie",
        "of Vitriol",
        "of the Frog",
        "of Detection",
        "of Reflection",
        "of the Twins"
    ];

    string[] private namePrefixes = [
        "Agony",
        "Apocalypse",
        "Armageddon",
        "Beast",
        "Behemoth",
        "Blight",
        "Blood",
        "Frog",
        "Brimstone",
        "Brood",
        "Carrion",
        "Cataclysm",
        "Chimeric",
        "Corpse",
        "Corruption",
        "Damnation",
        "Death",
        "Demon",
        "Dire",
        "Dragon",
        "Dread",
        "Doom",
        "Dusk",
        "Eagle",
        "Empyrean",
        "Fate",
        "Foe",
        "Matt",
        "Ghoul",
        "Gloom",
        "Glyph",
        "Golem",
        "Grim",
        "Hate",
        "Havoc",
        "Honour",
        "Horror",
        "Hypnotic",
        "Kraken",
        "Loath",
        "Maelstrom",
        "Mind",
        "Miracle",
        "Morbid",
        "Oblivion",
        "Onslaught",
        "Pain",
        "Pandemonium",
        "Phoenix",
        "Plague",
        "Rage",
        "Rapture",
        "Rune",
        "Skull",
        "Sol",
        "Soul",
        "Sorrow",
        "Spirit",
        "Storm",
        "Tempest",
        "Torment",
        "Vengeance",
        "Victory",
        "Viper",
        "Vortex",
        "Woe",
        "Wrath",
        "Light's",
        "Shimmering"
    ];

    string[] private nameSuffixes = [
        "Bane",
        "Root",
        "Bite",
        "Song",
        "Roar",
        "Grasp",
        "Instrument",
        "Glow",
        "Bender",
        "Shadow",
        "Whisper",
        "Shout",
        "Growl",
        "Tear",
        "Peak",
        "Form",
        "Sun",
        "Moon"
    ];
}