//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./interfaces/IN.sol";

/**
 * @title TheGaussianProtocol
 * @author Designed by @syntroNFT
 */
contract TheGaussianProtocol is ERC721Enumerable, ReentrancyGuard, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_TOKEN_ID = 8888;

    IN public immutable n;
    bool public publicSaleActive = false;
    string private _imageUriPrefix;
    string private _uriPrefix;

    mapping(uint256 => string) private tokenSeeds;

    constructor(address _nContractAddress) ERC721("The Gaussian Protocol", "GAUS") {
        n = IN(_nContractAddress);
    }

    function setBaseImageURI(string memory prefix) public onlyOwner {
        _imageUriPrefix = prefix;
    }

    function setBaseURI(string memory prefix) public onlyOwner {
        _uriPrefix = prefix;
    }

    function togglePublicSale() public onlyOwner {
        publicSaleActive = !publicSaleActive;
    }

    function random(string memory seed, uint8 offset) internal pure returns (uint8) {
        return uint8(uint256(keccak256(abi.encodePacked(seed, toString(offset)))));
    }

    function getRandomGaussianNumbers(string memory seed) public pure returns (uint256[8] memory) {
        uint256[8] memory numbers;
        for (uint8 i = 0; i < 8; ++i) {
            int64 accumulator = 0;
            for (uint8 j = 0; j < 16; ++j) {
                uint8 offset = (i * 16) + j;
                accumulator += int64(uint64(random(seed, offset)));
            }

            accumulator *= 10000;
            accumulator /= 16;
            accumulator = accumulator - 1270000;
            accumulator *= 10000;
            accumulator /= 733235;
            accumulator *= 8;
            accumulator += 105000;
            accumulator /= 10000;
            numbers[i] = uint256(uint64(accumulator));
        }

        return numbers;
    }

    function getNumbers(uint256 tokenId) public view returns (uint256[8] memory) {
        require(_exists(tokenId), "Nonexistent token");
        return getRandomGaussianNumbers(tokenSeeds[tokenId]);
    }

    function getFirst(uint256 tokenId) public view returns (uint256) {
        return getNumbers(tokenId)[0];
    }

    function getSecond(uint256 tokenId) public view returns (uint256) {
        return getNumbers(tokenId)[1];
    }

    function getThird(uint256 tokenId) public view returns (uint256) {
        return getNumbers(tokenId)[2];
    }

    function getFourth(uint256 tokenId) public view returns (uint256) {
        return getNumbers(tokenId)[3];
    }

    function getFifth(uint256 tokenId) public view returns (uint256) {
        return getNumbers(tokenId)[4];
    }

    function getSixth(uint256 tokenId) public view returns (uint256) {
        return getNumbers(tokenId)[5];
    }

    function getSeventh(uint256 tokenId) public view returns (uint256) {
        return getNumbers(tokenId)[6];
    }

    function getEight(uint256 tokenId) public view returns (uint256) {
        return getNumbers(tokenId)[7];
    }

    function _mintNumbers(uint256 tokenId) internal virtual {
        tokenSeeds[tokenId] = string(abi.encodePacked(toString(tokenId), msg.sender, block.number.toString()));
        _safeMint(msg.sender, tokenId);
    }

    function mintWithN(uint256 tokenId) public virtual nonReentrant {
        require(n.ownerOf(tokenId) == msg.sender, "Invalid owner of N");
        _mintNumbers(tokenId);
    }

    function mint(uint256 tokenId) public virtual nonReentrant {
        require(publicSaleActive, "Public sale is not yet active");
        require(tokenId < MAX_TOKEN_ID, "Exceeds total supply");
        _mintNumbers(tokenId);
    }

    function svgLine(uint256 value, uint256 index) internal pure returns (string memory) {
        string memory output;
        if (value >= 8 && value <= 12) {
            // white
            output = "#fff";
        } else if (value >= 6 && value <= 14) {
            // green
            output = "#03bf00";
        } else if (value >= 4 && value <= 16) {
            // blue
            output = "#009ed2";
        } else if (value >= 2 && value <= 18) {
            // yellow
            output = "#f1f100";
        } else {
            // red
            output = "#ca0303";
        }
        output = string(
            abi.encodePacked(
                '<text x="10" y="',
                toString((index + 1) * 20),
                '" fill="',
                output,
                '" class="base">',
                toString(value),
                '</text>'
            )
        );
        return output;
    }

    function tokenSVG(uint256 tokenId) public view returns (string memory) {
        uint256[8] memory numbers = getNumbers(tokenId);
        string[10] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { font-family: monospace; font-weight: bold; font-size: 16px; } .sig { font-size: 10px; font-weight: normal;}</style><rect width="100%" height="100%" fill="black" />';

        parts[1] = svgLine(numbers[0], 0);
        parts[2] = svgLine(numbers[1], 1);
        parts[3] = svgLine(numbers[2], 2);
        parts[4] = svgLine(numbers[3], 3);
        parts[5] = svgLine(numbers[4], 4);
        parts[6] = svgLine(numbers[5], 5);
        parts[7] = svgLine(numbers[6], 6);
        parts[8] = svgLine(numbers[7], 7);
        parts[9] = '<text x="245" y="340" fill="#fff" class="base sig">~&#119977;(10,4) series</text></svg>';

        string memory output = string(
            abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8])
        );
        output = string(
            abi.encodePacked(
                output,
                parts[9]
            )
        );

        return output;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (bytes(_uriPrefix).length > 0) {
            return string(abi.encodePacked(_uriPrefix, tokenId.toString()));
        }

        string memory output;
        if (bytes(_imageUriPrefix).length > 0) {
            output = string(abi.encodePacked(_imageUriPrefix, tokenId.toString(), ".png"));
        } else {
            output = tokenSVG(tokenId);
            output = string(abi.encodePacked(
                    'data:image/svg+xml;base64,',
                    Base64.encode(bytes(output))
                ));
        }

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Gaussian #',
                        toString(tokenId),
                        '", "description": "A set of 8 random numbers whose rarity follows a Gaussian distribution. Generated and stored on-chain using the power of the central limit theorem.", "image": "',
                        output,
                        '"}'
                    )
                )
            )
        );
        output = string(abi.encodePacked("data:application/json;base64,", json));

        return output;
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
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