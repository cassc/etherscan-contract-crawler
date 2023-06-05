// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ERC721SeaDrop } from "../src/ERC721SeaDrop.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./PrimesUtils.sol";
import "./Revealable.sol";

// @title: Primes
// @creator: g56d

contract Primes is ERC721SeaDrop, Revealable {
    using Strings for uint256;
    using PrimesUtils for *;
    string[9] private colors = [
        "fa0",
        "af0",
        "0f0",
        "0fa",
        "0af",
        "",
        "a0f",
        "f0a",
        ""
    ];
    address[] public allowedSeaDrop;
    struct Definitions {
        string path;
        string values;
    }
    mapping(uint256 => Definitions) private Paths;

    constructor() ERC721SeaDrop("Primes", "PRIMES", allowedSeaDrop) {
        setPathMap();
    }

    function setPathMap() internal {
        Definitions memory v1 = Definitions(
            "M0 0H100V100H0Z",
            "M50 0H100V50H50Z;M-50 0H100V150H-50Z;M50 0H100V50H50Z;"
        );
        Paths[1] = v1;
        Definitions memory v2 = Definitions(
            "M100 0H200V100H100Z",
            "M100 0H150V50H100Z;M100 0H250V150H100Z;M100 0H150V50H100Z;"
        );
        Paths[2] = v2;
        Definitions memory v3 = Definitions(
            "M200 0H300V100H200Z",
            "M200 0H300V100H200Z"
        );
        Paths[3] = v3;
        Definitions memory v4 = Definitions(
            "M300 0H400V100H300Z",
            "M350 0H400V50H350Z;M250 0H400V150H250Z;M350 0H400V50H350Z;"
        );
        Paths[4] = v4;
        Definitions memory v5 = Definitions(
            "M400 0H500V100H400Z",
            "M400 0H450V50H400Z;M400 0H550V150H400Z;M400 0H450V50H400Z;"
        );
        Paths[5] = v5;
        Definitions memory v7 = Definitions(
            "M600 0H700V100H600Z",
            "M650 0H700V50H650Z;M550 0H700V150H550Z;M650 0H700V50H650Z;"
        );
        Paths[7] = v7;
        Definitions memory v8 = Definitions(
            "M700 0H800V100H700Z",
            "M700 0H750V50H700Z;M700 0H850V150H700Z;M700 0H750V50H700Z;"
        );
        Paths[8] = v8;
        Definitions memory v10 = Definitions(
            "M0 100H100V200H0Z",
            "M50 150H100V200H50Z;M-50 50H100V200H-50Z;M50 150H100V200H50Z;"
        );
        Paths[10] = v10;
        Definitions memory v11 = Definitions(
            "M100 100H200V200H100Z",
            "M100 150H150V200H100Z;M100 50H250V200H100Z;M100 150H150V200H100Z;"
        );
        Paths[11] = v11;
        Definitions memory v13 = Definitions(
            "M300 100H400V200H300Z",
            "M350 150H400V200H350Z;M250 50H400V200H250Z;M350 150H400V200H350Z;"
        );
        Paths[13] = v13;
        Definitions memory v14 = Definitions(
            "M400 100H500V200H400Z",
            "M400 150H450V200H400Z;M400 50H550V200H400Z;M400 150H450V200H400Z;"
        );
        Paths[14] = v14;
        Definitions memory v16 = Definitions(
            "M600 100H700V200H600Z",
            "M650 150H700V200H650Z;M550 50H700V200H550Z;M650 150H700V200H650Z;"
        );
        Paths[16] = v16;
        Definitions memory v17 = Definitions(
            "M700 100H800V200H700Z",
            "M700 150H750V200H700Z;M700 50H850V200H700Z;M700 150H750V200H700Z;"
        );
        Paths[17] = v17;
        Definitions memory v19 = Definitions(
            "M0 200H100V300H0Z",
            "M50 200H100V250H50Z;M-50 200H100V350H-50Z;M50 200H100V250H50Z;"
        );
        Paths[19] = v19;
        Definitions memory v20 = Definitions(
            "M100 200H200V300H100Z",
            "M100 200H150V250H100Z;M100 200H250V350H100Z;M100 200H150V250H100Z;"
        );
        Paths[20] = v20;
        Definitions memory v22 = Definitions(
            "M300 200H400V300H300Z",
            "M350 200H400V250H350Z;M250 200H400V350H250Z;M350 200H400V250H350Z;"
        );
        Paths[22] = v22;
        Definitions memory v23 = Definitions(
            "M400 200H500V300H400Z",
            "M400 200H450V250H400Z;M400 200H550V350H400Z;M400 200H450V250H400Z;"
        );
        Paths[23] = v23;
        Definitions memory v25 = Definitions(
            "M600 200H700V300H600Z",
            "M650 200H700V250H650Z;M550 200H700V350H550Z;M650 200H700V250H650Z;"
        );
        Paths[25] = v25;
        Definitions memory v26 = Definitions(
            "M700 200H800V300H700Z",
            "M700 200H750V250H700Z;M700 200H850V350H700Z;M700 200H750V250H700Z;"
        );
        Paths[26] = v26;
        Definitions memory v28 = Definitions(
            "M0 300H100V400H0Z",
            "M50 350H100V400H50Z;M-50 250H100V400H-50Z;M50 350H100V400H50Z;"
        );
        Paths[28] = v28;
        Definitions memory v29 = Definitions(
            "M100 300H200V400H100Z",
            "M100 350H150V400H100Z;M100 250H250V400H100Z;M100 350H150V400H100Z;"
        );
        Paths[29] = v29;
        Definitions memory v31 = Definitions(
            "M300 300H400V400H300Z",
            "M350 350H400V400H350Z;M250 250H400V400H250Z;M350 350H400V400H350Z;"
        );
        Paths[31] = v31;
        Definitions memory v32 = Definitions(
            "M400 300H500V400H400Z",
            "M400 350H450V400H400Z;M400 250H550V400H400Z;M400 350H450V400H400Z;"
        );
        Paths[32] = v32;
        Definitions memory v34 = Definitions(
            "M600 300H700V400H600Z",
            "M650 350H700V400H650Z;M550 250H700V400H550Z;M650 350H700V400H650Z;"
        );
        Paths[34] = v34;
        Definitions memory v35 = Definitions(
            "M700 300H800V400H700Z",
            "M700 350H750V400H700Z;M700 250H850V400H700Z;M700 350H750V400H700Z;"
        );
        Paths[35] = v35;
        Definitions memory v37 = Definitions(
            "M0 400H100V500H0Z",
            "M50 400H100V450H50Z;M-50 400H100V550H-50Z;M50 400H100V450H50Z;"
        );
        Paths[37] = v37;
        Definitions memory v38 = Definitions(
            "M100 400H200V500H100Z",
            "M100 400H150V450H100Z;M100 400H250V550H100Z;M100 400H150V450H100Z;"
        );
        Paths[38] = v38;
        Definitions memory v40 = Definitions(
            "M300 400H400V500H300Z",
            "M350 400H400V450H350Z;M250 400H400V550H250Z;M350 400H400V450H350Z;"
        );
        Paths[40] = v40;
        Definitions memory v41 = Definitions(
            "M400 400H500V500H400Z",
            "M400 400H450V450H400Z;M400 400H550V550H400Z;M400 400H450V450H400Z;"
        );
        Paths[41] = v41;
        Definitions memory v43 = Definitions(
            "M600 400H700V500H600Z",
            "M650 400H700V450H650Z;M550 400H700V550H550Z;M650 400H700V450H650Z;"
        );
        Paths[43] = v43;
        Definitions memory v44 = Definitions(
            "M700 400H800V500H700Z",
            "M700 400H750V450H700Z;M700 400H850V550H700Z;M700 400H750V450H700Z;"
        );
        Paths[44] = v44;
        Definitions memory v46 = Definitions(
            "M0 500H100V600H0Z",
            "M50 550H100V600H50Z;M-50 450H100V600H-50Z;M50 550H100V600H50Z;"
        );
        Paths[46] = v46;
        Definitions memory v47 = Definitions(
            "M100 500H200V600H100Z",
            "M100 550H150V600H100Z;M100 450H250V600H100Z;M100 550H150V600H100Z;"
        );
        Paths[47] = v47;
        Definitions memory v49 = Definitions(
            "M300 500H400V600H300Z",
            "M350 550H400V600H350Z;M250 450H400V600H250Z;M350 550H400V600H350Z;"
        );
        Paths[49] = v49;
        Definitions memory v50 = Definitions(
            "M400 500H500V600H400Z",
            "M400 550H450V600H400Z;M400 450H550V600H400Z;M400 550H450V600H400Z;"
        );
        Paths[50] = v50;
        Definitions memory v52 = Definitions(
            "M600 500H700V600H600Z",
            "M650 550H700V600H650Z;M550 450H700V600H550Z;M650 550H700V600H650Z;"
        );
        Paths[52] = v52;
        Definitions memory v53 = Definitions(
            "M700 500H800V600H700Z",
            "M700 550H750V600H700Z;M700 450H850V600H700Z;M700 550H750V600H700Z;"
        );
        Paths[53] = v53;
        Definitions memory v55 = Definitions(
            "M0 600H100V700H0Z",
            "M50 600H100V650H50Z;M-50 600H100V750H-50Z;M50 600H100V650H50Z;"
        );
        Paths[55] = v55;
        Definitions memory v56 = Definitions(
            "M100 600H200V700H100Z",
            "M100 600H150V650H100Z;M100 600H250V750H100Z;M100 600H150V650H100Z;"
        );
        Paths[56] = v56;
        Definitions memory v58 = Definitions(
            "M300 600H400V700H300Z",
            "M350 600H400V650H350Z;M250 600H400V750H250Z;M350 600H400V650H350Z;"
        );
        Paths[58] = v58;
        Definitions memory v59 = Definitions(
            "M400 600H500V700H400Z",
            "M400 600H450V650H400Z;M400 600H550V750H400Z;M400 600H450V650H400Z;"
        );
        Paths[59] = v59;
        Definitions memory v61 = Definitions(
            "M600 600H700V700H600Z",
            "M650 600H700V650H650Z;M550 600H700V750H550Z;M650 600H700V650H650Z;"
        );
        Paths[61] = v61;
        Definitions memory v62 = Definitions(
            "M700 600H800V700H700Z",
            "M700 600H750V650H700Z;M700 600H850V750H700Z;M700 600H750V650H700Z;"
        );
        Paths[62] = v62;
        Definitions memory v64 = Definitions(
            "M0 700H100V800H0Z",
            "M50 750H100V800H50Z;M-50 650H100V800H-50Z;M50 750H100V800H50Z;"
        );
        Paths[64] = v64;
        Definitions memory v65 = Definitions(
            "M100 700H200V800H100Z",
            "M100 750H150V800H100Z;M100 650H250V800H100Z;M100 750H150V800H100Z;"
        );
        Paths[65] = v65;
        Definitions memory v67 = Definitions(
            "M300 700H400V800H300Z",
            "M350 750H400V800H350Z;M250 650H400V800H250Z;M350 750H400V800H350Z;"
        );
        Paths[67] = v67;
        Definitions memory v68 = Definitions(
            "M400 700H500V800H400Z",
            "M400 750H450V800H400Z;M400 650H550V800H400Z;M400 750H450V800H400Z;"
        );
        Paths[68] = v68;
        Definitions memory v70 = Definitions(
            "M600 700H700V800H600Z",
            "M650 750H700V800H650Z;M550 650H700V800H550Z;M650 750H700V800H650Z;"
        );
        Paths[70] = v70;
        Definitions memory v71 = Definitions(
            "M700 700H800V800H700Z",
            "M700 750H750V800H700Z;M700 650H850V800H700Z;M700 750H750V800H700Z;"
        );
        Paths[71] = v71;
        Definitions memory v73 = Definitions(
            "M0 800H100V900H0Z",
            "M50 800H100V850H50Z;M-50 800H100V950H-50Z;M50 800H100V850H50Z;"
        );
        Paths[73] = v73;
        Definitions memory v74 = Definitions(
            "M100 800H200V900H100Z",
            "M100 800H150V850H100Z;M100 800H250V950H100Z;M100 800H150V850H100Z;"
        );
        Paths[74] = v74;
        Definitions memory v76 = Definitions(
            "M300 800H400V900H300Z",
            "M350 800H400V850H350Z;M250 800H400V950H250Z;M350 800H400V850H350Z;"
        );
        Paths[76] = v76;
        Definitions memory v77 = Definitions(
            "M400 800H500V900H400Z",
            "M400 800H450V850H400Z;M400 800H550V950H400Z;M400 800H450V850H400Z;"
        );
        Paths[77] = v77;
        Definitions memory v79 = Definitions(
            "M600 800H700V900H600Z",
            "M650 800H700V850H650Z;M550 800H700V950H550Z;M650 800H700V850H650Z;"
        );
        Paths[79] = v79;
        Definitions memory v80 = Definitions(
            "M700 800H800V900H700Z",
            "M700 800H750V850H700Z;M700 800H850V950H700Z;M700 800H750V850H700Z;"
        );
        Paths[80] = v80;
    }

    // generation of the tokenURI
    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "Primes: non-extistent token ID");
        string
            memory description = "One of 1575 unique artworks from the on-chain scalable, animated and interactive Primes collection created by g56d";
        string memory serialName;
        string memory dataImage;
        string memory serialIsPrime;
        uint primesCount = 1;
        if (_revealState == RevealState.Revealed) {
            uint256 serialIndex = getHiddenValue(_tokenId, 2);
            serialName = string(
                abi.encodePacked("Primes #", serialIndex.toString())
            );
            dataImage = generateBase64SVG(serialIndex);
            serialIsPrime = PrimesUtils.isPrime(serialIndex) ? "true" : "false";
            primesCount = PrimesUtils.getNumberOfPrimeNumber(serialIndex);
        } else {
            serialName = "Primes";
            dataImage = "PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZlcnNpb249IjEuMiIgdmlld0JveD0iMCAwIDkwMCA5MDAiIHdpZHRoPSI5MDAiIGhlaWdodD0iOTAwIg0KICAgIHNoYXBlLXJlbmRlcmluZz0iZ2VvbWV0cmljUHJlY2lzaW9uIj4NCiAgICA8dGl0bGU+UHJpbWVzIHVucmV2ZWFsZWQ8L3RpdGxlPg0KICAgIDxyZWN0IHdpZHRoPSI5MDAiIGhlaWdodD0iOTAwIiBmaWxsPSIjMDAwIiAvPg0KICAgIDxwYXRoIGQ9Ik00MDAgNDAwSDUwMFY1MDBINDAwWiIgZmlsbD0iIzBhZiIgLz4NCjwvc3ZnPg==";
        }
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                serialName,
                                '", "description":"',
                                description,
                                '", "image": "',
                                "data:image/svg+xml;base64,",
                                dataImage,
                                '", "attributes": [',
                                '{"trait_type":"Number of prime number", "value":"',
                                primesCount.toString(),
                                '"},',
                                '{"trait_type":"Serial number is a prime number", "value":"',
                                serialIsPrime,
                                '"}',
                                "]",
                                "}"
                            )
                        )
                    )
                )
            );
    }

    // base64 encode SVG
    function generateBase64SVG(
        uint256 _tokenId
    ) internal view returns (string memory) {
        return Base64.encode(bytes(generateSVG(_tokenId)));
    }

    // generation of SVG
    function generateSVG(
        uint256 _tokenId
    ) internal view returns (string memory) {
        string memory title = string.concat(
            "<title>Primes #",
            _tokenId.toString(),
            "</title>"
        );
        string memory paths = generatePaths(_tokenId);
        return
            string(
                abi.encodePacked(
                    '<svg xmlns="http://www.w3.org/2000/svg" version="1.1" viewBox="0 0 900 900" width="100%" height="100%" style="background:#000">',
                    title,
                    '<rect width="900" height="900" fill="#000"/>',
                    paths,
                    "</svg>"
                )
            );
    }

    // generation of paths
    function generatePaths(
        uint256 _tokenId
    ) internal view returns (string memory) {
        uint256 count = (_tokenId * 81) - 80;
        uint256 x = 0;
        uint256 y = 0;
        uint256 colorIndex = 0;
        uint256 index = 0;
        uint256 key = 1;
        string memory paths = "";

        for (y = 0; y <= 800; y += 100) {
            for (x = 0; x <= 800; x += 100) {
                colorIndex = x / 100;
                if (PrimesUtils.isPrime(uint256(count))) {
                    string memory d = getPath(key);
                    string memory values = getValues(key);
                    string memory oi = PrimesUtils.setAnimationEvent(
                        index,
                        colorIndex
                    );
                    paths = PrimesUtils.concatenate(
                        paths,
                        string(
                            abi.encodePacked(
                                '<path d="',
                                d,
                                '" fill="#',
                                string(colors[colorIndex]),
                                '" shape-rendering="geometricPrecision"><animate attributeName="d" values="',
                                values,
                                '" repeatCount="indefinite" dur="',
                                count.toString(),
                                'ms" ',
                                oi,
                                '="click"></animate></path>'
                            )
                        )
                    );
                }
                count += 1;
                index += 1;
                key += 1;
            }
        }
        return paths;
    }

    function getPath(uint256 _k) internal view returns (string memory path) {
        return Paths[_k].path;
    }

    function getValues(
        uint256 _k
    ) internal view returns (string memory values) {
        return Paths[_k].values;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed");
    }
}