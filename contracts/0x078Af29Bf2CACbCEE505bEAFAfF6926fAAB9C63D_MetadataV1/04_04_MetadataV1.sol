// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./IMetadata.sol";
import "./Base64.sol";

contract MetadataV1 is IMetadata {
	using Strings for uint256;

	string internal constant SVG_HEADER =
		"data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' version='1.2' viewBox='0 0 16 16' shape-rendering='crispEdges' width='512px' height='512px'>";
	string internal constant SVG_FOOTER = "</svg>";
	string internal constant WHITE = "FFFFFF";
	string internal constant BLACK = "000000";

	bytes1[8] bitMask;

	constructor() {
		bitMask[0] = (0x7F);
		bitMask[1] = (0xBF);
		bitMask[2] = (0xDF);
		bitMask[3] = (0xEF);
		bitMask[4] = (0xF7);
		bitMask[5] = (0xFB);
		bitMask[6] = (0xFD);
		bitMask[7] = (0xFE);
	}

	function getTokenURI(
		uint256 _tokenId,
		uint256 _incrementalId,
		address _creator,
        string calldata _creatorName
	) external view returns (string memory uri) {
		bytes memory authorNameAttribute;

		if (bytes(_creatorName).length > 0) {
			authorNameAttribute = abi.encodePacked(',{ "trait_type": "Author", "value": "', _creatorName, '" }');
		} else {
			authorNameAttribute = "";
		}

		return
			string(
				abi.encodePacked(
					"data:application/json;base64,",
					Base64.encode(
						bytes(
							abi.encodePacked(
								'{"name":"PXC-256 #',
								_incrementalId.toString(),
								'", "image": "',
								getImage(_tokenId),
								'","description":"",',
								'"attributes": [{"trait_type": "Author Wallet","value": "',
								toString(abi.encodePacked(_creator)),
								'"}',
                                authorNameAttribute,
                                ']}'
							)
						)
					)
				)
			);
	}

	function getImage(uint256 _tokenId) internal view returns (string memory svg) {
		bytes32 _bytes = bytes32(_tokenId);
		string memory color;
		uint256 x;
		uint256 y;

		svg = string.concat(svg, SVG_HEADER);

		for (uint256 i; i < 32; i++) {
			for (uint256 c; c < bitMask.length; c++) {
				color = (bitMask[c] | _bytes[i] == bytes1(uint8(0xFF))) ? BLACK : WHITE;
				svg = drawPixel(svg, x + c, y, color);
			}

			x += 8;
			if (x % 16 == 0) {
				y++;
				x = 0;
			}
		}

		svg = string.concat(svg, SVG_FOOTER);
	}

	function drawPixel(
		string memory _svg,
		uint256 _x,
		uint256 _y,
		string memory _color
	) internal pure returns (string memory) {
		return
			string.concat(
				_svg,
				"<rect x='",
				_x.toString(),
				"' y='",
				_y.toString(),
				"' width='1' height='1' fill='#",
				_color,
				"'/>"
			);
	}

	function toString(bytes memory data) internal pure returns (string memory) {
		bytes memory alphabet = "0123456789abcdef";

		bytes memory str = new bytes(2 + data.length * 2);
		str[0] = "0";
		str[1] = "x";
		for (uint256 i = 0; i < data.length; i++) {
			str[2 + i * 2] = alphabet[uint256(uint8(data[i] >> 4))];
			str[3 + i * 2] = alphabet[uint256(uint8(data[i] & 0x0f))];
		}
		return string(str);
	}

    function addressToString(address _address) internal pure returns(string memory) {
		bytes32 _bytes = bytes32(uint256(uint160(_address)));
		bytes memory HEX = "0123456789abcdef";
		bytes memory _string = new bytes(42);
		_string[0] = '0';
		_string[1] = 'x';
		
		for(uint i = 0; i < 20; i++) {
			_string[2+i*2] = HEX[uint8(_bytes[i + 12] >> 4)];
			_string[3+i*2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
		}
	
		return string(_string);
	}
}