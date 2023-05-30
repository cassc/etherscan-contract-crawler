// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract XY is ERC721Tradable, ReentrancyGuard {
	using SafeMath for uint256;
	uint256 constant WIDTH = 128;
	uint256 constant HEIGHT = 128;
	string private contractURI_ = "https://assets.nfty.dev/xy/contract.json";

    function contractURI() public view returns (string memory) {
        return contractURI_;
    }

	function updateContractURI(string memory _contractURI) public onlyOwner {
	    contractURI_ = _contractURI;
	}
	    
    function getX(uint256 tokenId) public pure returns (uint256) {
		return SafeMath.mod(SafeMath.sub(tokenId, 1), WIDTH);
    }
    
    function getY(uint256 tokenId) public pure returns (uint256) {
		return SafeMath.div(SafeMath.sub(tokenId, 1), HEIGHT);
    }
	
    function getWidth() public pure returns (uint256) {
		return WIDTH;
    }
    
    function getHeight() public pure returns (uint256) {
		return HEIGHT;
    }

    function tokenURI(uint256 tokenId) override public pure returns (string memory) {
        string[17] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { font-family: monospace; font-size: 28px; }</style><rect width="100%" height="100%" fill="#543B23" /><text x="50%" y="50%" text-anchor="middle" fill="#81BE1C" class="base">(';

        parts[1] = toString(getX(tokenId));

        parts[2] = ',';

        parts[3] = toString(getY(tokenId));

        parts[4] = ')</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4]));
        
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Coordinate (', toString(getX(tokenId)), ',', toString(getY(tokenId)), ')", "description": "X,Y Coordinates are stored on chain and represent a ', toString(WIDTH), 'x', toString(HEIGHT), ' grid. Use it for maps, tiles, locations or anything else!", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    function claim(uint256 tokenId) public nonReentrant {
        require(tokenId > 0 && tokenId <= SafeMath.mul(WIDTH, HEIGHT), "Token ID invalid");
        _safeMint(_msgSender(), tokenId);
    }
	
    function claim(uint256 x, uint256 y) public nonReentrant {
		uint256 tokenId = SafeMath.add(SafeMath.add(x, SafeMath.mul(WIDTH, y)), 1);
        require(tokenId > 0 && tokenId <= SafeMath.mul(WIDTH, HEIGHT), "Coordinates invalid");
        _safeMint(_msgSender(), tokenId);
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
    
    constructor(address _proxyRegistryAddress)
        ERC721Tradable("X,Y Coordinates", "XYC", _proxyRegistryAddress)
    {}
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