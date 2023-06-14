// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/*
 *
 * on-chain.energy
 * by superspace.network
 *
 */

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract OnchainEnergy is ERC721Royalty, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private tokenCounter;

    struct Energy {
        string color1;
        string color2;
        string color3;
        string color4;
        string color5;
        string color6;
        string color7;
        string color8;
        string color9;
        string time1;
        string time2;
        string time3;
        string time4;
    }

    mapping(uint => Energy) tokenEnergy;
    mapping(uint256 => uint256) public tokenMutations;

    bool public isSaleActive;
    uint256 public numGiftedTokens;

    uint256 public constant MAX_SUPPLY = 1234;
    uint256 public constant MAX_GIFTED_TOKENS = 123;
    uint256 public constant MAX_TOKENS_PER_WALLET = 1;
    uint256 public constant PUBLIC_SALE_PRICE = 0.0321 ether;

    string constant NAME = "Energy #";
    string constant DESCRIPTION =
        "A collection of 1234 onchain energy radiants. Each energy radiant is a generative ERC-721 NFT containing an SVG randomly generated, encoded, and stored fully on the Ethereum blockchain.";
    string constant SVG_OPENER =
        '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="500" height="500" viewBox="0 0 500 500">';
    string constant SVG_CLOSER = "</svg>";
    string constant SVG_ENERGY_OPENER =
        '<rect width="500" height="500" fill="url(#outer_layer)">';
    string constant SVG_ENERGY_CLOSER = "</rect>";
    string constant SVG_DEFS_OPENER = "<defs>";
    string constant SVG_DEFS_CLOSER = "</defs>";

    string constant JSON_PROTOCOL_URI = "data:application/json;base64,";
    string constant SVG_PROTOCOL_URI = "data:image/svg+xml;base64,";

    // ==================================================== //
    // ========= ACCESS CONTROL / SANITY MODIFIERS ======== //
    // ==================================================== //

    modifier canMintTokens() {
        require(
            tokenCounter.current() + 1 <=
                MAX_SUPPLY - MAX_GIFTED_TOKENS + numGiftedTokens,
            "Not enough tokens remaining to mint."
        );
        _;
    }

    modifier canGiftTokens(uint256 numberOfTokens) {
        require(
            numGiftedTokens + numberOfTokens <= MAX_GIFTED_TOKENS,
            "Not enough tokens remaining to gift."
        );
        require(
            tokenCounter.current() + numberOfTokens <= MAX_SUPPLY,
            "Not enough Tokens remaining to mint."
        );
        _;
    }

    modifier isCorrectPayment(uint256 price) {
        require(price == msg.value, "Incorrect ETH value sent.");
        _;
    }

    modifier isTokenOwner(uint256 tokenId) {
        require(
            ownerOf(tokenId) == msg.sender,
            "You must own this token to train it"
        );
        _;
    }

    modifier maxTokensPerWallet() {
        require(
            balanceOf(msg.sender) + 1 <= MAX_TOKENS_PER_WALLET,
            "Max tokens per wallet is one."
        );
        _;
    }

    modifier saleIsActive() {
        require(isSaleActive, "Public sale is not open.");
        _;
    }

    modifier tokenExists(uint256 tokenId) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        _;
    }

    // ==================================================== //
    // =================== CONSTRUCTOR ==================== //
    // ==================================================== //

    constructor() ERC721("OnchainEnergy", "ETHENERGY") {
        _setDefaultRoyalty(msg.sender, 500);
    }

    // ==================================================== //
    // ================= MINTING FUNCTIONS ================ //
    // ==================================================== //

    function mint()
        external
        payable
        nonReentrant
        isCorrectPayment(PUBLIC_SALE_PRICE)
        saleIsActive
        canMintTokens
        maxTokensPerWallet
    {
        newEnergy();
        _safeMint(msg.sender, newToken());
    }

    // ==================================================== //
    // ============ PUBLIC READ-ONLY FUNCTIONS ============ //
    // ==================================================== //

    function getLastTokenId() external view returns (uint256) {
        return tokenCounter.current();
    }

    // ==================================================== //
    // ============== ONLY-OWNER FUNCTIONS ================ //
    // ==================================================== //

    function giftTokens(
        address[] calldata addresses
    ) external nonReentrant onlyOwner canGiftTokens(addresses.length) {
        uint256 numToGift = addresses.length;
        numGiftedTokens += numToGift;

        for (uint256 i = 0; i < numToGift; i++) {
            newEnergy();
            _safeMint(addresses[i], newToken());
        }
    }

    function setIsSaleActive(bool _isSaleActive) external onlyOwner {
        isSaleActive = _isSaleActive;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawTokens(IERC20 token) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    // ==================================================== //
    // ===================== NEW TOKEN ==================== //
    // ==================================================== //

    function newEnergy() private {
        tokenMutations[tokenCounter.current() + 1] = 0;
        tokenEnergy[tokenCounter.current() + 1] = Energy(
            randomColor(360).toString(),
            randomColor(359).toString(),
            randomColor(358).toString(),
            randomColor(357).toString(),
            randomColor(356).toString(),
            randomColor(355).toString(),
            randomColor(354).toString(),
            randomColor(353).toString(),
            randomColor(352).toString(),
            randomSpeed(120).toString(),
            randomSpeed(119).toString(),
            randomSpeed(118).toString(),
            randomSpeed(117).toString()
        );
    }

    function newToken() private returns (uint256) {
        tokenCounter.increment();
        return tokenCounter.current();
    }

    // ==================================================== //
    // ===================== MUTATIONS ==================== //
    // ==================================================== //

    function mutate(
        uint256 tokenId
    ) public isTokenOwner(tokenId) tokenExists(tokenId) {
        uint256 currentMutation = tokenMutations[tokenId];
        tokenMutations[tokenId] = currentMutation + 1;
        tokenEnergy[tokenId] = Energy(
            randomColor(360).toString(),
            randomColor(359).toString(),
            randomColor(358).toString(),
            randomColor(357).toString(),
            randomColor(356).toString(),
            randomColor(355).toString(),
            randomColor(354).toString(),
            randomColor(353).toString(),
            randomColor(352).toString(),
            randomSpeed(120).toString(),
            randomSpeed(119).toString(),
            randomSpeed(118).toString(),
            randomSpeed(117).toString()
        );
    }

    function getMutation(uint256 tokenId) public view returns (string memory) {
        uint256 mutation = tokenMutations[tokenId];
        return mutation.toString();
    }

    // ==================================================== //
    // ====================== RANDOM ====================== //
    // ==================================================== //
    function randomColor(uint256 _modulus) public view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.number,
                        block.timestamp,
                        msg.sender,
                        msg.sender.balance,
                        tokenCounter.current()
                    )
                )
            ) % _modulus;
    }

    function randomSpeed(uint256 _modulus) public view returns (uint256) {
        return
            (uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        msg.sender,
                        tokenCounter.current()
                    )
                )
            ) % _modulus) + 6;
    }

    // ==================================================== //
    // ====================== SUPPLY ====================== //
    // ==================================================== //
    function totalSupply() public view returns (uint256) {
        return tokenCounter.current();
    }

    // ==================================================== //
    // ===================== SVG TOKEN ==================== //
    // ==================================================== //

    function stopOne(uint256 tokenId) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<stop offset="0" stop-color=" hsl(',
                    tokenEnergy[tokenId].color1,
                    ', 100%, 50%)">',
                    "</stop>"
                )
            );
    }

    function stopTwo(uint256 tokenId) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<stop offset="50%" stop-color="hsl(',
                    tokenEnergy[tokenId].color2,
                    ', 100%, 50%)">',
                    '<animate attributeName="stop-color" values="hsl(',
                    tokenEnergy[tokenId].color3,
                    ", 100%, 50%);hsl(",
                    tokenEnergy[tokenId].color4,
                    ", 100%, 50%);hsl(",
                    tokenEnergy[tokenId].color5,
                    ", 100%, 50%);hsl(",
                    tokenEnergy[tokenId].color3,
                    ', 100%, 50%);" dur="',
                    tokenEnergy[tokenId].time1,
                    's" repeatCount="indefinite" />',
                    '<animate attributeName="offset" values=".95;.80;.60;.40;.20;0;.20;.40;.60;.80;.95" dur="',
                    tokenEnergy[tokenId].time2,
                    's" repeatCount="indefinite"/>',
                    "</stop>"
                )
            );
    }

    function stopThree(uint256 tokenId) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<stop offset="100%" stop-color="hsl(',
                    tokenEnergy[tokenId].color6,
                    ', 100%, 50%)" >',
                    '<animate attributeName="stop-color" values="hsl(',
                    tokenEnergy[tokenId].color7,
                    ", 100%, 50%);hsl(",
                    tokenEnergy[tokenId].color8,
                    ", 100%, 50%);hsl(",
                    tokenEnergy[tokenId].color9,
                    ", 100%, 50%);hsl(",
                    tokenEnergy[tokenId].color7,
                    ', 100%, 50%)" dur="',
                    tokenEnergy[tokenId].time3,
                    's" repeatCount="indefinite" />',
                    '<animate attributeName="offset" values=".95;.80;.60;.40;.20;0;.20;.40;.60;.80;.95" dur="',
                    tokenEnergy[tokenId].time4,
                    's" repeatCount="indefinite" />',
                    "</stop>"
                )
            );
    }

    function generateEnergyGradient(
        uint256 tokenId
    ) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    SVG_DEFS_OPENER,
                    '<radialGradient id="outer_layer">',
                    stopOne(tokenId),
                    stopTwo(tokenId),
                    stopThree(tokenId),
                    "</radialGradient>",
                    SVG_DEFS_CLOSER
                )
            );
    }

    function generateEnergy(
        uint256 tokenId
    ) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    SVG_ENERGY_OPENER,
                    '<animate attributeName="rx" values="10;280;10" dur="',
                    tokenEnergy[tokenId].time1,
                    's" repeatCount="indefinite" />',
                    SVG_ENERGY_CLOSER
                )
            );
    }

    function generateSVG(
        uint256 tokenId
    ) internal view returns (string memory) {
        return
            Base64.encode(
                abi.encodePacked(
                    SVG_OPENER,
                    generateEnergyGradient(tokenId),
                    generateEnergy(tokenId),
                    SVG_CLOSER
                )
            );
    }

    // ==================================================== //
    // ===================== METADATA ===================== //
    // ==================================================== //

    function generateOuterEnergyPalette(
        uint256 tokenId
    ) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '{"trait_type": "Color 1", "value": "',
                    tokenEnergy[tokenId].color1,
                    '"},',
                    '{"trait_type": "Color 2", "value": "',
                    tokenEnergy[tokenId].color2,
                    '"},',
                    '{"trait_type": "Color 3", "value": "',
                    tokenEnergy[tokenId].color3,
                    '"},',
                    '{"trait_type": "Color 4", "value": "',
                    tokenEnergy[tokenId].color4,
                    '"},',
                    '{"trait_type": "Color 5", "value": "',
                    tokenEnergy[tokenId].color5,
                    '"},'
                )
            );
    }

    function generateInnerEnergyPalette(
        uint256 tokenId
    ) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '{"trait_type": "Color 6", "value": "',
                    tokenEnergy[tokenId].color6,
                    '"},',
                    '{"trait_type": "Color 7", "value": "',
                    tokenEnergy[tokenId].color7,
                    '"},',
                    '{"trait_type": "Color 8", "value": "',
                    tokenEnergy[tokenId].color8,
                    '"},',
                    '{"trait_type": "Color 9", "value": "',
                    tokenEnergy[tokenId].color9,
                    '"}'
                )
            );
    }

    function generateAttributes(
        uint256 tokenId
    ) internal view returns (string memory) {
        string memory OUTER_ENERGY_ATTRIBUTES = generateOuterEnergyPalette(
            tokenId
        );
        string memory INNER_ENERGY_ATTRIBUTES = generateInnerEnergyPalette(
            tokenId
        );
        return
            string(
                abi.encodePacked(
                    '{"trait_type": "Genesis Block", "value": "',
                    abi.encodePacked(block.number.toString()),
                    '"},',
                    '{"trait_type": "Mutations", "value": "',
                    abi.encodePacked(getMutation(tokenId)),
                    '"},',
                    '{"trait_type": "Timestamp", "value": "',
                    abi.encodePacked(block.timestamp.toString()),
                    '"},',
                    OUTER_ENERGY_ATTRIBUTES,
                    INNER_ENERGY_ATTRIBUTES
                )
            );
    }

    // ==================================================== //
    // ==================== TOKEN URI ===================== //
    // ==================================================== //

    function tokenURI(
        uint256 tokenId
    )
        public
        view
        virtual
        override
        tokenExists(tokenId)
        returns (string memory)
    {
        bytes memory IMAGE = abi.encodePacked(
            SVG_PROTOCOL_URI,
            generateSVG(tokenId)
        );
        bytes memory NUMBER = abi.encodePacked(tokenId.toString());
        string memory ATTRIBUTES = generateAttributes(tokenId);
        bytes memory JSON = abi.encodePacked(
            '{"name":"',
            NAME,
            "",
            NUMBER,
            '",',
            '"description":"',
            DESCRIPTION,
            '",',
            '"image":"',
            IMAGE,
            '",',
            '"attributes":[',
            ATTRIBUTES,
            "]}"
        );
        return string(abi.encodePacked(JSON_PROTOCOL_URI, Base64.encode(JSON)));
    }
}