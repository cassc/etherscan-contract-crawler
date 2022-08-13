// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";

interface Shuffler {
    function shuffle(address _addr) external view returns (uint160);
}

contract Metadata is Ownable {

    uint256[] internal mintedHands;
    bool internal claimIsEnabled;
    address internal shufflerAddress;
    mapping(address => bool) internal limiter;
    mapping(uint256 => uint256[]) internal tokenToCards;


    function flipClaim(bool _bool) external onlyOwner {
        claimIsEnabled = _bool;
    }

    modifier shuffle(uint160 _shuffleIndex) {
        require(claimIsEnabled, "Claim is not live.");
        require(tx.origin == msg.sender, "EOAs only.");
        require(_shuffleIndex == getShuffleIndex(msg.sender), "Invalid Shuffle Index");
        require(mintedHands.length < 1326, "Supply is capped by the merkle root anyways.");
        require(!limiter[msg.sender], "One claim per wallet.");
        _;
    }

    function setShufflerAddress(address _address) external onlyOwner {
        shufflerAddress = _address;
    }

    function getShuffleIndex(address _addr) internal view returns (uint160) {
        return Shuffler(shufflerAddress).shuffle(_addr);
    }

    function getMintedHands() public view returns (uint256[] memory) {
        return mintedHands;
    }

    function getMetadataImage(uint256 _tokenId) public view returns (string memory) {
        uint256 card1 = tokenToCards[_tokenId][0];
        uint256 card2 = tokenToCards[_tokenId][1];
        string memory color1 = (card1 < 13 || 38 < card1 ) ? 'Black' : 'Red';
        string memory color2 = (card2 < 13 || 38 < card2 ) ? 'Black' : 'Red';
        return string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 500 500"><style>.card1{fill:',
            color1,
            ';font-size:250px;}</style><style>.card2{fill:',
            color2,
            ';font-size:250px;}</style><rect width="100%" height="100%" fill="white" /><text x="30%" y="281px" class="card1" dominant-baseline="middle" text-anchor="middle">',
            cardIcons[card1],
            '</text><text x="70%" y="281px" class="card2" dominant-baseline="middle" text-anchor="middle">',
            cardIcons[card2],
            '</text></svg>'
        ));
    }

    function getMetadataJSON(uint256 _tokenId, string memory _svg) internal view returns (string memory) {
        return Base64.encode(bytes(string(abi.encodePacked(
            '{"name": "Hand #',
            toString(_tokenId),
            '","attributes": [ { "trait_type": "Card 1", "value": "',
            cardNames[tokenToCards[_tokenId][0]],
            '" },{ "trait_type": "Card 2", "value": "',
            cardNames[tokenToCards[_tokenId][1]],
            '" }], "description": "The Cards collection consists of the 1326 unique poker starting hand combinations that can be obtained within a deck of 52 cards.",',
            '"image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(_svg)),
            '"}'
        ))));
    }

    string[52] internal cardNames = [
        "Ace Of Spades",
        "Two Of Spades",
        "Three Of Spades",
        "Four Of Spades",
        "Five Of Spades",
        "Six Of Spades",
        "Seven Of Spades",
        "Eight Of Spades",
        "Nine Of Spades",
        "Ten Of Spades",
        "Jack Of Spades",
        "Queen Of Spades",
        "King Of Spades",
        "Ace Of Hearts",
        "Two Of Hearts",
        "Three Of Hearts",
        "Four Of Hearts",
        "Five Of Hearts",
        "Six Of Hearts",
        "Seven Of Hearts",
        "Eight Of Hearts",
        "Nine Of Hearts",
        "Ten Of Hearts",
        "Jack Of Hearts",
        "Queen Of Hearts",
        "King Of Hearts",
        "Ace Of Diamonds",
        "Two Of Diamonds",
        "Three Of Diamonds",
        "Four Of Diamonds",
        "Five Of Diamonds",
        "Six Of Diamonds",
        "Seven Of Diamonds",
        "Eight Of Diamonds",
        "Nine Of Diamonds",
        "Ten Of Diamonds",
        "Jack Of Diamonds",
        "Queen Of Diamonds",
        "King Of Diamonds",
        "Ace Of Clubs",
        "Two Of Clubs",
        "Three Of Clubs",
        "Four Of Clubs",
        "Five Of Clubs",
        "Six Of Clubs",
        "Seven Of Clubs",
        "Eight Of Clubs",
        "Nine Of Clubs",
        "Ten Of Clubs",
        "Jack Of Clubs",
        "Queen Of Clubs",
        "King Of Clubs"
    ];
    
    string[52] internal cardIcons = [
        "\xf0\x9f\x82\xa1",
        "\xf0\x9f\x82\xa2",
        "\xf0\x9f\x82\xa3",
        "\xf0\x9f\x82\xa4",
        "\xf0\x9f\x82\xa5",
        "\xf0\x9f\x82\xa6",
        "\xf0\x9f\x82\xa7",
        "\xf0\x9f\x82\xa8",
        "\xf0\x9f\x82\xa9",
        "\xf0\x9f\x82\xaa",
        "\xf0\x9f\x82\xab",
        "\xf0\x9f\x82\xad",
        "\xf0\x9f\x82\xae",
        "\xf0\x9f\x82\xb1",
        "\xf0\x9f\x82\xb2",
        "\xf0\x9f\x82\xb3",
        "\xf0\x9f\x82\xb4",
        "\xf0\x9f\x82\xb5",
        "\xf0\x9f\x82\xb6",
        "\xf0\x9f\x82\xb7",
        "\xf0\x9f\x82\xb8",
        "\xf0\x9f\x82\xb9",
        "\xf0\x9f\x82\xba",
        "\xf0\x9f\x82\xbb",
        "\xf0\x9f\x82\xbd",
        "\xf0\x9f\x82\xbe",
        "\xf0\x9f\x83\x81",
        "\xf0\x9f\x83\x82",
        "\xf0\x9f\x83\x83",
        "\xf0\x9f\x83\x84",
        "\xf0\x9f\x83\x85",
        "\xf0\x9f\x83\x86",
        "\xf0\x9f\x83\x87",
        "\xf0\x9f\x83\x88",
        "\xf0\x9f\x83\x89",
        "\xf0\x9f\x83\x8a",
        "\xf0\x9f\x83\x8b",
        "\xf0\x9f\x83\x8d",
        "\xf0\x9f\x83\x8e",
        "\xf0\x9f\x83\x91",
        "\xf0\x9f\x83\x92",
        "\xf0\x9f\x83\x93",
        "\xf0\x9f\x83\x94",
        "\xf0\x9f\x83\x95",
        "\xf0\x9f\x83\x96",
        "\xf0\x9f\x83\x97",
        "\xf0\x9f\x83\x98",
        "\xf0\x9f\x83\x99",
        "\xf0\x9f\x83\x9a",
        "\xf0\x9f\x83\x9b",
        "\xf0\x9f\x83\x9d",
        "\xf0\x9f\x83\x9e"
    ];

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

}


/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}