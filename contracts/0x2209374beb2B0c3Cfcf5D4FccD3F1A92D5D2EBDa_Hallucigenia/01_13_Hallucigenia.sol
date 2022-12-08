// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Hallucigenia is ERC721Enumerable, Ownable {
    bytes10 internal constant _DIGITS = "0123456789";
    string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    bool public PAUSED = true;
    uint public MAX_SUPPLY = 1250;
    uint public MAX_MINTS_PER_TX = 5;

    uint256 private PRICE = 0.02 ether;

    mapping(uint256 => uint256) private _generator;
    mapping(uint256 => uint) private _palette;

    constructor() ERC721("Hallucigenia", "HALLU") {}

    function mint(uint amount) public payable {
        uint256 currentSupply = totalSupply();

        require(!PAUSED,                                        "Sale paused");
        require(currentSupply + amount < MAX_SUPPLY,            "Sale has already ended");
        require(msg.value >= PRICE,                             "Ether sent is not correct");
        require(amount > 0 && amount - 1 < MAX_MINTS_PER_TX,    "Too many mints/tx");

        for (uint256 i = 0; i < amount; i++) {
            _generator[currentSupply] = prng(block.timestamp + currentSupply) + prng(block.number + currentSupply);
            _palette[currentSupply] = (prng(block.timestamp + currentSupply) % 6) + 1;
            _safeMint(msg.sender, currentSupply);
            currentSupply++;
        }
    }

    function pause() public onlyOwner {
        PAUSED = !PAUSED;
    }

    function setMaxSupply(uint256 supply) public onlyOwner {
        MAX_SUPPLY = supply;
    }

    function setMaxMints(uint256 mints) public onlyOwner {
        MAX_MINTS_PER_TX = mints;
    }

    function withdraw() public payable onlyOwner {
        require(payable(0xed8D89B01cB469B75a9a18bd4680f0b4c4224a4d).send(address(this).balance));
    }

    function tokenURI(uint256 index) public view override virtual returns (string memory) {
        require(_exists(index), "URI query for nonexistent token");

        bytes memory name = abi.encodePacked("Hallucigenia #", str(index), ' [', str(_generator[index]), ']');
        bytes memory attr = abi.encodePacked('{"trait_type": "Color", "value": "', colorName(index), '"}');

        if (_generator[index] % 7 == 0) {
            attr = abi.encodePacked(attr, ', {"trait_type": "Background", "value": "Transparent"}');
        } else {
            attr = abi.encodePacked(attr, ', {"trait_type": "Background", "value": "Black"}');
        }

        if (_generator[index] % 6 == 0) {
            attr = abi.encodePacked(attr, ', {"trait_type": "Animation", "value": "Discrete"}');
        } else {
            attr = abi.encodePacked(attr, ', {"trait_type": "Animation", "value": "Fluid"}');
        }

        bytes memory json = abi.encodePacked('{"name":"', name, '", "description": "waiworinao", "attributes": [', attr, '], "image": "', hallu(index), '"}');
        
        return string(abi.encodePacked('data:application/json;base64,', encode(json)));
    }


    function colorName(uint256 index) private view returns (bytes memory) {
        uint palette = _palette[index];

        if (palette == 1) {
            return abi.encodePacked("Pastel");
        } else if (palette == 2) {
            return abi.encodePacked("Neon");
        } else if (palette == 3) {
            return abi.encodePacked("Magma");
        } else if (palette == 4) {
            return abi.encodePacked("Amazonia");
        } else if (palette == 5) {
            return abi.encodePacked("Chrominance");
        } else if (palette == 6) {
            return abi.encodePacked("Luminance");
        } else {
            return abi.encodePacked("?????");
        }
    }

    function hallu(uint256 index) private view returns (string memory) {
        require(_exists(index), "URI query for nonexistent token");

        bytes memory firstPath = getPath(_generator[index] << 3);
        uint palette = _palette[index];

        bytes memory out = abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" version="1.2" viewBox="0 0 500 500">');
        
        if (_generator[index] % 7 != 0) {
            out = abi.encodePacked(out, '<rect x="0" y="0" width="500" height="500" fill="#111"><animate attributeName="fill" values="#000;#333;#000" dur="0.01s" repeatCount="indefinite"/></rect>');
        }

        out = abi.encodePacked(out, '<path d="', firstPath, '" stroke="#fff" fill="none" stroke-width="40" stroke-linecap="round"><animate attributeName="stroke" values="');

        if (palette == 1) {
            out = abi.encodePacked(out, '#ff71ce;#01cdfe;#05ffa1');
        } else if (palette == 2) {
            out = abi.encodePacked(out, '#F42B87;#FFC6E9;#2AE8F5');
        } else if (palette == 3) {
            out = abi.encodePacked(out, '#fff001;#fd1999;#99fc20');
        } else if (palette == 4) {
            out = abi.encodePacked(out, '#00FF00;#0000FF');
        } else if (palette == 5) {
            out = abi.encodePacked(out, '#FF0000;#0000FF');
        } else if (palette == 6) {
            out = abi.encodePacked(out, '#FFFFFF;#000000');
        } else {
            out = abi.encodePacked(out, '#FF3300');
        }

        out = abi.encodePacked(out, '" dur="0.1s" repeatCount="indefinite" calcMode="discrete"/><animate attributeName="d" values="', firstPath, ';');
        
        for (uint p = 0; p < 5; p++) {
            out = abi.encodePacked(out, getPath(_generator[index] << (p+1)), ";");
        }

        if (_generator[index] % 6 == 0) {
            out = abi.encodePacked(out, firstPath, '" dur="0.95s" calcMode="discrete" repeatCount="indefinite"/><animate attributeName="stroke-width" values="10;50;10" dur="0.7s" repeatCount="indefinite" calcMode="discrete"/></path></svg>');
        } else {
            out = abi.encodePacked(out, firstPath, '" dur="0.95s" repeatCount="indefinite"/><animate attributeName="stroke-width" values="10;50;10" dur="0.7s" repeatCount="indefinite"/></path></svg>');
        }


        return string(abi.encodePacked('data:image/svg+xml;base64,', encode(out)));
    }


    function getPath(uint256 G) private pure returns (bytes memory) {
        bytes memory path = abi.encodePacked('M 50,', getPosOffset(G));

        path = abi.encodePacked(path, ' C ', getPointOffset(G, 7), ' ');

        for (uint x = 0; x < 3; x++) {
            path = abi.encodePacked(path, getPointOffset(G + x, x + 1), ' ', str(150 + 100*x), ',', getPosOffset(G << (x+1)), ' S ');
        }

        return abi.encodePacked(path, getPointOffset(G, 11), ' 450,', getPosOffset(G << 13));
    }

    function getPointOffset(uint256 G, uint256 i) private pure returns (bytes memory) {
        return abi.encodePacked(str(prng(G << i) % 300 + 100), ',', str(prng(G << (i + 1)) % 300 + 100));
    }

    function getPosOffset(uint256 G) private pure returns (bytes memory) {
        return abi.encodePacked(str(prng(G) % 200 + 150));
    }

    function str(uint value) internal pure returns (bytes memory) {
        if (value == 0) {
            return "0";
        }
        uint temp = value;
        uint digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = _DIGITS[value % 10];
            value /= 10;
        }
        return buffer;
    }

    // LuckySeven - @matiasbn_eth
    function prng(uint256 mu) internal pure returns (uint O) {
        assembly {
            let L := exp(10, 250) // 10^p
            let U := mul(L, 1) // 10^p * b
            let C := exp(10, 10) // 10^n
            let K := sub(C, mu) // 10^n - mu
            let Y := div(U, K) // (10^p * b)/(10^n - mu)
            let S := exp(10, add(2, 3)) // 10^(i+j)
            let E := exp(10, 2) // 10^i
            let V := mod(Y, S) // Y % 10^(i+j)
            let N := mod(Y, E) // Y % 10^i
            let I := sub(V, N) // (Y % 10^(i+j)) / (Y % 10^i)
            O := div(I, E)
        }
    }
    
    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }
}