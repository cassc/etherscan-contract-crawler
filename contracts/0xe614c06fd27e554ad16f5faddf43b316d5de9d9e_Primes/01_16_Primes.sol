// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./PrimesUtils.sol";

// @title Primes
// @author g56d

contract Primes is ERC721AQueryable, ERC2981, Ownable {
    using Strings for uint256;
    using PrimesUtils for *;

    // Metadata
    // --------
    struct Scheme {
        string color;
    }
    struct D {
        string min;
        string max;
    }
    mapping(uint256 => D) private Values;
    mapping(uint256 => Scheme) private Color;

    // Paths
    // --------
    function setValuesMap() internal {
        D memory oo = D(
            "M-38.2 138.2H100V0H-38.2V0Z",
            "M38.2 61.8H100V0H38.2V0Z"
        );
        Values[0] = oo;
        D memory oi = D(
            "M38.2 100H100V38.2H38.2V0Z",
            "M-38.2 100H100V-38.2H-38.2V0Z"
        );
        Values[1] = oi;
        D memory io = D("M0 138.2H138.2V0H0V0Z", "M0 61.8H61.80V0H0V0Z");
        Values[2] = io;
        D memory ii = D("M0 100H61.8V38.2H0V0Z", "M0 100H138.2V-38.2H0V0Z");
        Values[3] = ii;
    }

    function getMinValue(
        uint256 k
    ) internal view returns (string memory values) {
        return Values[k].min;
    }

    function getMaxValue(
        uint256 k
    ) internal view returns (string memory values) {
        return Values[k].max;
    }

    // Colors
    // --------
    function setColorsMap() internal {
        Scheme memory v1 = Scheme("fa0");
        Color[0] = v1;
        Scheme memory v2 = Scheme("af0");
        Color[100] = v2;
        Scheme memory v3 = Scheme("0f0");
        Color[200] = v3;
        Scheme memory v4 = Scheme("0fa");
        Color[300] = v4;
        Scheme memory v5 = Scheme("0af");
        Color[400] = v5;
        Scheme memory v6 = Scheme("a0f");
        Color[600] = v6;
        Scheme memory v7 = Scheme("f0a");
        Color[700] = v7;
    }

    function getColor(uint256 k) internal view returns (string memory color) {
        return Color[k].color;
    }

    // Token URI
    // --------
    function tokenURI(
        uint256 tokenId
    ) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        require(_exists(tokenId), "Primes: non-extistent token ID");
        string memory description = "One of 1575 Primes";
        string memory serialStr;
        string memory dataImage;
        string memory dataHTML;
        string memory serialIsPrime;
        uint primesCount = 0;
        uint256 serialIndex = tokenId;
        serialStr = string(
            abi.encodePacked("Primes #", serialIndex.toString())
        );
        dataImage = encodeSVG(serialIndex);
        dataHTML = encodeHTML(serialIndex);
        serialIsPrime = PrimesUtils.isPrime(serialIndex) ? "true" : "false";
        primesCount = PrimesUtils.getNumberOfPrimeNumber(serialIndex);

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                serialStr,
                                '","description":"',
                                description,
                                '","image": "',
                                dataImage,
                                '","attributes":[{"trait_type":"Number of primes","value":"',
                                primesCount.toString(),
                                '"},{"trait_type":"The edition number is a primes","value":"',
                                serialIsPrime,
                                '"}],"animation_url":"',
                                dataHTML,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    // SVG
    // --------
    function encodeSVG(uint256 tokenId) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(bytes(generateSVG(tokenId)))
                )
            );
    }

    function generateSVG(
        uint256 tokenId
    ) internal view returns (string memory) {
        string memory paths = generatePaths(tokenId);
        return
            string(
                abi.encodePacked(
                    '<svg xmlns="http://www.w3.org/2000/svg" version="1.1" viewBox="0 0 900 900" width="100%" height="100%" style="background:#000"><title>Primes #',
                    tokenId.toString(),
                    '</title><rect width="900" height="900" fill="#000"/>',
                    paths,
                    "</svg>"
                )
            );
    }

    function SVG(uint256 tokenId) external view returns (string memory) {
        return string(generateSVG(tokenId));
    }

    // Paths
    // --------
    function generatePaths(
        uint256 tokenId
    ) internal view returns (string memory) {
        uint256 count = (tokenId * 81) - 80;
        uint256 x = 0;
        uint256 y = 0;
        uint i = 2;
        string memory paths = "";

        for (y = 0; y <= 800; y += 100) {
            for (x = 0; x <= 800; x += 100) {
                if (PrimesUtils.isPrime(uint256(count))) {
                    string memory animation = "";
                    if (PrimesUtils.booleanRandom(x / 100, count)) {
                        animation = string(
                            abi.encodePacked(
                                'begin="0s;t',
                                count.toString(),
                                '.click"'
                            )
                        );
                    } else {
                        animation = string(
                            abi.encodePacked(
                                'begin="t',
                                count.toString(),
                                '.click"'
                            )
                        );
                    }
                    paths = PrimesUtils.concatenate(
                        paths,
                        string(
                            abi.encodePacked(
                                '<g transform="translate(',
                                getCoordinates(x, y),
                                ')"><title>',
                                count.toString(),
                                '</title><path id="_',
                                count.toString(),
                                '" d="M0 100H100V0H0V100Z" fill="#',
                                getColor(x),
                                '" shape-rendering="geometricPrecision"><animate attributeName="d" values="',
                                getValues(x, y, i, count),
                                '" repeatCount="indefinite" calcMode="spline" keySplines=".4 0 .6 1;.4 0 .6 1" dur="',
                                count.toString(),
                                'ms" ',
                                animation,
                                ' end="click"/></path>',
                                generateTPath(x / 100, count),
                                "</g>"
                            )
                        )
                    );
                    i += 1;
                }
                count += 1;
            }
        }
        return paths;
    }

    function generateTPath(
        uint256 x,
        uint256 count
    ) internal view returns (string memory) {
        string memory tD = "";
        string memory tValues = "";
        string memory tAnimation = "";

        if (PrimesUtils.booleanRandom(x, count)) {
            tD = "M0 0H0V0H0V0Z";
            tValues = "M0 100H100V0H0V100Z";
            tAnimation = string(
                abi.encodePacked(
                    'begin="_',
                    count.toString(),
                    '.click" end="click"'
                )
            );
        } else {
            tD = "M0 100H100V0H0V100Z";
            tValues = "M0 0H0V0H0V0Z";
            tAnimation = string(
                abi.encodePacked(
                    'begin="click" ',
                    'end="_',
                    count.toString(),
                    '.click"'
                )
            );
        }

        return
            string(
                abi.encodePacked(
                    '<path id="t',
                    count.toString(),
                    '" d="',
                    tD,
                    '" fill-opacity="0"><animate attributeName="d" values="',
                    tValues,
                    '" ',
                    tAnimation,
                    "/></path>"
                )
            );
    }

    function getCoordinates(
        uint x,
        uint y
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(x.toString(), ",", y.toString()));
    }

    /**
     * @param x coordinate
     * @param y coordinate
     * @param c incremented value
     * @return d animation paths
     */
    function getValues(
        uint x,
        uint y,
        uint c,
        uint d
    ) internal view returns (string memory) {
        if (x == 0 || x == 300 || x == 600) {
            if (y == 0 || y == 200 || y == 400 || y == 600) {
                return concatValues(0, c, d);
            } else {
                return concatValues(1, c, d);
            }
        } else {
            if (y == 0 || y == 200 || y == 400 || y == 600) {
                return concatValues(2, c, d);
            } else {
                return concatValues(3, c, d);
            }
        }
    }

    /**
     * @param i index of array
     * @param c incremented value
     * @param d incremented value
     * @return Concatenated animation values, min/max variation
     */
    function concatValues(
        uint i,
        uint c,
        uint d
    ) internal view returns (string memory) {
        if (uint256(keccak256(abi.encodePacked(msg.sender, c, d))) % 2 == 0) {
            return
                string(
                    abi.encodePacked(
                        getMinValue(i),
                        ";",
                        getMaxValue(i),
                        ";",
                        getMinValue(i)
                    )
                );
        } else {
            return
                string(
                    abi.encodePacked(
                        getMaxValue(i),
                        ";",
                        getMinValue(i),
                        ";",
                        getMaxValue(i)
                    )
                );
        }
    }

    // Animation URL
    function encodeHTML(uint256 tokenId) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:text/html;base64,",
                    Base64.encode(bytes(generateHTML(tokenId)))
                )
            );
    }

    function generateHTML(
        uint256 tokenId
    ) internal view returns (string memory) {
        string memory svg = generateSVG(tokenId);
        return
            string(
                abi.encodePacked(
                    '<!DOCTYPE html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Primes #',
                    tokenId.toString(),
                    "</title><style>html{background:#000} body{margin:0 auto;overflow:hidden} svg{max-width:100vw;max-height:100vh}</style></head><body>",
                    svg,
                    "</body></html>"
                )
            );
    }

    // EIP-165
    // --------
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981, IERC721A) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    // EIP-2981
    // --------
    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /**
     * @dev Overrides the function from ERC721A to start at 1.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    constructor() ERC721A("Primes", "PRMS") {
        setValuesMap();
        setColorsMap();
        _mint(msg.sender, 1);
        for (uint256 i = 1; i <= 787; i += 1) {
            _mint(msg.sender, 2);
        }
        _setDefaultRoyalty(0xC5c6E2D210fCf090C4647b982553756735a0c135, 500);
    }

    function mint(address to, uint256 quantity) external onlyOwner {
        require(
            totalSupply() + quantity <= 1575,
            "Primes: total supply limit exceeded"
        );
        _mint(to, quantity);
    }
}