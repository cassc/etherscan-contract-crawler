// SPDX-License-Identifier: UNLICENSED
//
pragma solidity ^0.8.15;

// __/\\\________/\\\_______/\\\\\_______/\\\________/\\\____/\\\\\\\\\_____
//  _\///\\\____/\\\/______/\\\///\\\____\/\\\_______\/\\\__/\\\///////\\\___
//   ___\///\\\/\\\/______/\\\/__\///\\\__\/\\\_______\/\\\_\/\\\_____\/\\\___
//    _____\///\\\/_______/\\\______\//\\\_\/\\\_______\/\\\_\/\\\\\\\\\\\/____
//     _______\/\\\_______\/\\\_______\/\\\_\/\\\_______\/\\\_\/\\\//////\\\____
//      _______\/\\\_______\//\\\______/\\\__\/\\\_______\/\\\_\/\\\____\//\\\___
//       _______\/\\\________\///\\\__/\\\____\//\\\______/\\\__\/\\\_____\//\\\__
//        _______\/\\\__________\///\\\\\/______\///\\\\\\\\\/___\/\\\______\//\\\_
//         _______\///_____________\/////__________\/////////_____\///________\///__
// _____/\\\\\\\\\\\____/\\\\\\\\\\\\\\\_______/\\\\\_________/\\\\\\\\\______/\\\________/\\\_
//  ___/\\\/////////\\\_\///////\\\/////______/\\\///\\\_____/\\\///////\\\___\///\\\____/\\\/__
//   __\//\\\______\///________\/\\\_________/\\\/__\///\\\__\/\\\_____\/\\\_____\///\\\/\\\/____
//    ___\////\\\_______________\/\\\________/\\\______\//\\\_\/\\\\\\\\\\\/________\///\\\/______
//     ______\////\\\____________\/\\\_______\/\\\_______\/\\\_\/\\\//////\\\__________\/\\\_______
//      _________\////\\\_________\/\\\_______\//\\\______/\\\__\/\\\____\//\\\_________\/\\\_______
//       __/\\\______\//\\\________\/\\\________\///\\\__/\\\____\/\\\_____\//\\\________\/\\\_______
//        _\///\\\\\\\\\\\/_________\/\\\__________\///\\\\\/_____\/\\\______\//\\\_______\/\\\_______
//         ___\///////////___________\///_____________\/////_______\///________\///________\///________
//
//  "The rightful owner of this NFT owns all copyright that may exist in the work embodied in the NFT’s
//   tokenURI, subject to: (1) the rights of owners of other NFTs minted under the same smart contract
//   as if all such NFTs were minted simultaneously; and (2) a nonexclusive, sublicensable, transferable
//   license retained by the creator of the smart contract to reproduce, distribute, prepare derivative
//   works based upon, and display the work embodied in the NFT’s tokenURI solely to promote the NFT
//   collection created through the smart contract. Using a private key to sign a transaction that
//   transfers this NFT constitutes a writing signed by the transferor assigning all such copyright to
//   the transferee. Grants or assignments of exclusive rights in such copyright shall be null and void
//   except to the extent such rights are transferred upon transfer of the NFT."
//========================================================================

import "openzeppelin-contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "openzeppelin-contracts/utils/Base64.sol";
import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/security/ReentrancyGuard.sol";

import "operator-filter-registry/DefaultOperatorFilterer.sol";

import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import "./MerkleDistributor.sol";
import "./WordTable.sol";

error MintPriceNotPaid();
error MaxSupply();
error MaxAddressMints();
error NonExistentTokenURI();
error WithdrawTransfer();

contract YourStory is
    ERC721Royalty,
    DefaultOperatorFilterer,
    MerkleDistributor,
    ReentrancyGuard,
    Ownable
{
    uint256 public currentTokenId;
    uint256 public constant TOTAL_SUPPLY = 8_128;
    uint256 public constant BASE_MINT_PRICE = 0.00001 ether;
    uint256 public constant MAX_MINTS = 2;

    WordTable private wordTable;

    mapping(uint256 => bytes20) private tokenIdToMintSeed;
    mapping(uint256 => bool) private tokenIdIsCombo;
    mapping(address => uint256) public mintCount;

    bool public saleActive;

    constructor(
        address _owner,
        address _wordTable,
        bytes32 merkleRoot
    ) ERC721("Your Story", "STORY") {
        wordTable = WordTable(_wordTable);
        _setAllowList(merkleRoot);
        _transferOwnership(_owner);
        _setDefaultRoyalty(_owner, 628);
    }

    /**
     * @dev marketplace metadata
     */
    function contractURI() external pure returns (string memory) {
        return "https://yourstory.wtf/curi.json";
    }

    /**
     * @dev sets the sale as active for allowlist
     */
    function setAllowListActive(bool allowListActive) external onlyOwner {
        _setAllowListActive(allowListActive);
    }

    /**
     * @dev sets the merkle root for the allow list
     */
    function setAllowList(bytes32 merkleRoot) external onlyOwner {
        _setAllowList(merkleRoot);
    }

    /**
     * @dev allows public sale minting
     */
    function setSaleActive(bool state) external onlyOwner {
        saleActive = state;
    }

    /**
     * @dev sets the public sale as active
     */
    modifier isPublicSaleActive() {
        require(saleActive, "Public sale is not active");
        _;
    }

    function withdrawPayments(address payable payee)
        external
        onlyOwner
        nonReentrant
    {
        if (payee == address(0)) {
            revert WithdrawTransfer();
        }
        uint256 balance = address(this).balance;
        (bool transferTx, ) = payee.call{value: balance}("");
        if (!transferTx) {
            revert WithdrawTransfer();
        }
    }

    /**
     * @dev gets the dynamic mint price
     */
    function mintPrice(uint256 amt) public view returns (uint256 price) {
        uint256 endTokenId = currentTokenId + amt;
        for (uint256 i = currentTokenId; i < endTokenId; i++) {
            price += BASE_MINT_PRICE * (i + 1);
        }
        return price;
    }

    /**
     * @dev checks if user has exceeded max mints
     */
    modifier addressHasMints(address minter, uint256 amt) {
        require(
            mintCount[minter] + amt <= MAX_MINTS,
            "Maximum mints for address exceeded"
        );
        _;
    }

    modifier doesNotExceedSupply(uint256 amt) {
        require(
            (currentTokenId + amt) <= TOTAL_SUPPLY,
            "Mint would exceed max supply"
        );
        _;
    }

    /**
     * @dev mint for allow listers
     */
    function mintAllowlist(uint256 amt, bytes32[] memory merkleProof)
        external
        payable
        ableToClaim(msg.sender, merkleProof)
        addressHasMints(msg.sender, amt)
        doesNotExceedSupply(amt)
        nonReentrant
        returns (uint256[] memory)
    {
        uint256 price = mintPrice(amt);
        if (msg.value < price) {
            revert MintPriceNotPaid();
        }

        uint256[] memory tokenIds = new uint256[](amt);
        for (uint256 i = 0; i < amt; i++) {
            tokenIds[i] = ++currentTokenId; // increment and save
            tokenIdToMintSeed[currentTokenId] = bytes20(msg.sender);
            mintCount[msg.sender] = mintCount[msg.sender] + 1;
            if (mintCount[msg.sender] > 1) {
                tokenIdIsCombo[currentTokenId] = true;
            }
            _safeMint(msg.sender, currentTokenId);
        }

        // return excess
        SafeTransferLib.safeTransferETH(msg.sender, msg.value - price);
        return tokenIds;
    }

    /**
     * @dev mints many
     */
    function mint(uint256 amt)
        external
        payable
        isPublicSaleActive
        addressHasMints(msg.sender, amt)
        doesNotExceedSupply(amt)
        nonReentrant
        returns (uint256[] memory)
    {
        uint256 price = mintPrice(amt);
        if (msg.value < price) {
            revert MintPriceNotPaid();
        }

        uint256[] memory tokenIds = new uint256[](amt);
        for (uint256 i = 0; i < amt; i++) {
            tokenIds[i] = ++currentTokenId; // increment and save
            tokenIdToMintSeed[currentTokenId] = bytes20(msg.sender);
            mintCount[msg.sender] = mintCount[msg.sender] + 1;
            if (mintCount[msg.sender] > 1) {
                tokenIdIsCombo[currentTokenId] = true;
            }
            _safeMint(msg.sender, currentTokenId);
        }

        // return excess
        SafeTransferLib.safeTransferETH(msg.sender, msg.value - price);
        return tokenIds;
    }

    /**
     * @dev gets num tokens minted by sender
     */
    function getMinted() external view returns (uint256) {
        return mintCount[msg.sender];
    }

    /**
     * @dev gets the tokens sentance in raw form
     */
    function getSentance(uint256 tokenId)
        external
        view
        returns (string[40] memory)
    {
        if (ownerOf(tokenId) == address(0)) {
            revert NonExistentTokenURI();
        }

        if (tokenIdIsCombo[tokenId]) {
            return
                seedToSentance(
                    combineAddress(
                        tokenIdToMintSeed[tokenId],
                        bytes20(address(this))
                    )
                );
        } else {
            return seedToSentance(tokenIdToMintSeed[tokenId]);
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (ownerOf(tokenId) == address(0)) {
            revert NonExistentTokenURI();
        }

        bytes20 mintSeed = tokenIdToMintSeed[tokenId];
        if (address(mintSeed) == address(0)) {
            revert NonExistentTokenURI();
        }

        // Determine if token id a combo or not
        // change token seed accordingly
        bytes20 tokenSeed;
        if (tokenIdIsCombo[tokenId]) {
            tokenSeed = combineAddress(
                tokenIdToMintSeed[tokenId],
                bytes20(address(this))
            );
        } else {
            tokenSeed = mintSeed;
        }

        string[2] memory colors = seedToColorStrings(tokenSeed);
        string[40] memory sentance = seedToSentance(tokenSeed);

        // - - - - - - -
        // SVG
        // - - - - - - -

        string memory svgHeader = string.concat(
            '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base {fill: #',
            colors[1],
            "; font-family: American Typewriter, Georgia, serif; font-size: 15px; }</style>",
            '<rect width="100%" height="100%" fill="#',
            colors[0],
            '"/>'
        );

        string memory svgRows;
        for (uint256 row = 0; row < 13; row++) {
            svgRows = string.concat(
                svgRows,
                '<text x="10" y="',
                toString((row + 1) * 20),
                '" class="base">',
                sentance[row * 3],
                " ",
                sentance[(row * 3) + 1],
                " ",
                sentance[(row * 3) + 2],
                "</text>"
            );
        }

        string memory svg = string.concat(
            svgHeader,
            svgRows,
            '<text x="10" y="280" class="base">',
            sentance[39],
            "</text></svg>"
        );

        // - - - - - - -
        // Attributes
        // - - - - - - -

        string memory attributes = '"attributes": [';
        for (uint256 i = 0; i < 40; i++) {
            string memory trait = string.concat(
                '{"trait_type": "Word ',
                toString(i + 1),
                '", "value": '
            );

            if (i == 22 || i == 31) {
                // 22, 31 have leading "
                trait = string.concat(trait, sentance[i], '" }, ');
            } else if (i == 23 || i == 34) {
                // 23, 34 have lagging "
                trait = string.concat(trait, '"', sentance[i], " }, ");
            } else {
                // typical
                trait = string.concat(trait, '"', sentance[i], '" }, ');
            }
            attributes = string.concat(attributes, trait);
        }

        attributes = string.concat(
            attributes,
            '{"trait_type": "Background Color", "value": "#',
            colors[0],
            '"}, ',
            '{"trait_type": "Font Color", "value": "#',
            colors[1],
            '"}]'
        );

        string memory json = Base64.encode(
            bytes(
                string.concat(
                    '{"name": "Your Story #',
                    toString(tokenId),
                    '", "description": "An on-chain story generated from your address. \\n\\nThe rightful owner of this NFT owns all copyright that may exist in the work embodied in the NFTs tokenURI, subject to: (1) the rights of owners of other NFTs minted under the same smart contract as if all such NFTs were minted simultaneously; and (2) a nonexclusive, sublicensable, transferable license retained by the creator of the smart contract to reproduce, distribute, prepare derivative works based upon, and display the work embodied in the NFTs tokenURI solely to promote the NFT collection created through the smart contract. Using a private key to sign a transaction that transfers this NFT constitutes a writing signed by the transferor assigning all such copyright to the transferee. Grants or assignments of exclusive rights in such copyright shall be null and void except to the extent such rights are transferred upon transfer of the NFT.',
                    '", "external_url": "https://yourstory.wtf',
                    '", "image": "data:image/svg+xml;base64,',
                    Base64.encode(bytes(svg)),
                    '",',
                    attributes,
                    "}"
                )
            )
        );

        return string.concat("data:application/json;base64,", json);
    }

    // Utils for handling the address shifting
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function byteToNibbles(bytes1 addrByte)
        internal
        pure
        returns (uint8[2] memory nibbles)
    {
        return [
            uint8((addrByte >> uint8(4)) & hex"0f"),
            uint8(addrByte & hex"0f")
        ];
    }

    function nibblesToBytes(uint8[2] memory nibbles)
        internal
        pure
        returns (bytes1)
    {
        return bytes1((nibbles[0] << 4) | nibbles[1]);
    }

    function combineAddress(bytes20 addrBytes, bytes20 contrBytes)
        internal
        pure
        returns (bytes20 addrBytesShifted)
    {
        bytes memory buffer = new bytes(20);
        for (uint8 i = 0; i < 20; i++) {
            uint8[2] memory nibbles = byteToNibbles(addrBytes[i]);
            uint8[2] memory nibbles2 = byteToNibbles(contrBytes[i]);
            buffer[i] = nibblesToBytes(
                [
                    (nibbles[0] + nibbles2[0]) % uint8(16),
                    (nibbles[1] + nibbles2[1]) % uint8(16)
                ]
            );
        }
        return bytes20(buffer);
    }

    function seedToColorStrings(bytes20 seed)
        internal
        pure
        returns (string[2] memory colors)
    {
        string memory bgColor;
        string memory fontColor;

        for (uint8 i = 0; i < 3; i++) {
            uint8[2] memory nibbles = byteToNibbles(seed[i]);
            bgColor = string(
                abi.encodePacked(
                    bgColor,
                    _HEX_SYMBOLS[nibbles[0] & 0xf],
                    _HEX_SYMBOLS[nibbles[1] & 0xf]
                )
            );
            fontColor = string(
                abi.encodePacked(
                    fontColor,
                    _HEX_SYMBOLS[~nibbles[0] & 0xf],
                    _HEX_SYMBOLS[~nibbles[1] & 0xf]
                )
            );
        }
        return [bgColor, fontColor];
    }

    function seedToSentance(bytes20 seed)
        internal
        view
        returns (string[40] memory sentance)
    {
        for (uint8 i = 0; i < 20; i++) {
            uint8[2] memory nibbles = byteToNibbles(seed[i]);
            sentance[i * 2] = wordTable.WORDS(nibbles[0], i * 2);
            sentance[i * 2 + 1] = wordTable.WORDS(nibbles[1], i * 2 + 1);
        }
        return sentance;
    }

    // - - - - - - - - - - - - - -
    // Royalty Required Overrides
    // - - - - - - - - - - - - - -
    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}