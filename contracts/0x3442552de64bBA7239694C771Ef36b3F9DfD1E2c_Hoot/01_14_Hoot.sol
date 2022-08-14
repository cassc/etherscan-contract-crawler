// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/*
         ,' ``',
        '  (o)(o)
       `       > ;
       ',     . ...-'"""""`'.
     .'`',`''''`________:   ":
   (`'. '.;  |           ;/\;\;
  (`',.',.;  |               |
 (,'` .`.,'  |      Birds    |
 (,.',.','   |      100%     |
(,.',.-`_____|    Onchain    |
    __\_ _\_ |   hoot hoot!  |
             |_______________|
*/
// we hope you Digg it!
error SoundBounded();

contract Hoot is ERC721, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;

    mapping(uint256 => string[]) public hootMetaData;
    mapping(uint256 => bool) public beenClaimed;
    mapping(uint256 => bool) public isSoul;
    bool public openGates;

    ERC721 public constant MB =
        ERC721(0x23581767a106ae21c074b2276D25e5C3e136a68b);
    bytes32 public constant METADATAROOT =
        0x5d2bb5f5ec347e04ba7e4f2f121f74eb22bfe097dc040b843913f4c7d2add985;
    uint256 public launchTime;

    constructor() ERC721("Hoot", "Hoot") {
        launchTime = block.timestamp;
    }

    function setHootMetaData(uint256 tokenId, string[] memory traits) private {
        require(hootMetaData[tokenId].length == 0, "Hoot already set");
        require(block.timestamp < launchTime + 1 weeks, "Saved forever");
        hootMetaData[tokenId] = traits;
    }

    function claim(
        uint256 id,
        string[] memory traits,
        bytes32[] calldata proof
    ) external nonReentrant {
        require(openGates, "Hoot gates are closed");
        require(beenClaimed[id] == false, "Already minted");
        require(balanceOf(msg.sender) < 2, "Max two hoots");
        require(id >= 0 && id <= 9999, "Exceeds max supply");
        bytes memory traitsPacked;
        for (uint256 i = 0; i < traits.length; i++) {
            traitsPacked = abi.encodePacked(traitsPacked, traits[i]);
        }
        bytes32 leaf = keccak256(abi.encodePacked(id, traitsPacked));
        require(MerkleProof.verify(proof, METADATAROOT, leaf), "Invalid proof");
        beenClaimed[id] = true;
        setHootMetaData(id, traits);
        _safeMint(msg.sender, id);
    }

    function boundSoul(uint256 id) external {
        require(block.timestamp > launchTime + 1 weeks, "Cant lock yet");
        require(MB.ownerOf(id) == msg.sender, "Must own MB");
        require(ownerOf(id) == msg.sender, "Must own Hoot");
        isSoul[id] = true;
    }

    function openTheGates() external onlyOwner {
        require(openGates == false, "Gates already open");
        openGates = true;
    }

    function hasBeenClaimed(uint256 tokenId) external view returns (bool) {
        return beenClaimed[tokenId];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        if (isSoul[tokenId]) {
            revert SoundBounded();
        }
        ERC721.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        if (isSoul[tokenId]) {
            revert SoundBounded();
        }
        ERC721.safeTransferFrom(from, to, tokenId, _data);
    }

    function ownerOf(uint256 tokenId_) public view override returns (address) {
        if (isSoul[tokenId_]) {
            return MB.ownerOf(tokenId_);
        }
        return super.ownerOf(tokenId_);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string[] memory traits = hootMetaData[tokenId];
        uint256 length = 20 + 4 * (traits.length - 3);
        string[] memory parts = new string[](length);

        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" ';

        parts[1] = 'preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350">';
        parts[
            2
        ] = "<style>.base { fill: white; font-family: serif; font-size: ";
        parts[3] = '14px; }</style> <rect width="100%" height="100%" ';
        parts[4] = 'fill="black" /><text x="10" y="20" class="base">#';

        parts[5] = toString(tokenId);
        parts[6] = "</text>";

        parts[7] = '<text x="10" y="40" ';
        parts[8] = 'class="base">';
        parts[9] = traits[0];
        parts[10] = "</text>";

        parts[11] = '<text x="10" y="60" ';
        parts[12] = 'class="base">';
        parts[13] = traits[1];
        parts[14] = "</text>";

        parts[15] = '<text x="10" y="80" ';
        parts[16] = 'class="base">';
        parts[17] = traits[2];
        parts[18] = "</text>";

        if (length >= 24) {
            parts[19] = '<text x="10" y="100" ';
            parts[20] = 'class="base">';
            parts[21] = traits[3];
            parts[22] = "</text>";
        }
        if (length >= 28) {
            parts[23] = '<text x="10" y="120" ';
            parts[24] = 'class="base">';
            parts[25] = traits[4];
            parts[26] = "</text>";
        }
        if (length >= 32) {
            parts[27] = '<text x="10" y="140" ';
            parts[28] = 'class="base">';
            parts[29] = traits[5];
            parts[30] = "</text>";
        }
        if (length >= 36) {
            parts[31] = '<text x="10" y="160" ';
            parts[32] = 'class="base">';
            parts[33] = traits[6];
            parts[34] = "</text>";
        }

        if (length >= 40) {
            parts[35] = '<text x="10" y="180" ';
            parts[36] = 'class="base">';
            parts[37] = traits[7];
            parts[38] = "</text>";
        }

        parts[parts.length - 1] = "</svg>";

        string memory output;

        for (uint256 i = 0; i < parts.length; i++) {
            output = string(abi.encodePacked(output, parts[i]));
        }

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Hoot #',
                        toString(tokenId),
                        '", "description": "Hoot is an on-chain collection inspired by Loot. Each tokens attributes correspond to the Moonbird of the same ID. CC0.", "image": "data:image/svg+xml;base64,',
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

    function toString(uint256 value) internal pure returns (string memory) {
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
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

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
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
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