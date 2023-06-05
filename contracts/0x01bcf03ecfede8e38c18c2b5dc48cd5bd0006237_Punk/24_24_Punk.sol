// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "../DropNFT.sol";

interface IFont {
	function getFont(uint256 id) external view returns (string memory);
}

/// @title The PUNK NFT Drop
/// @author Tribute Brand LLC
/// @notice Interaction with this contract is mostly meant to happen through the main
///			TributeBrand.sol contract.
contract Punk is DropNFT {
	using Strings for uint;
	uint16 constant FONT_ID = 1;

	/// @dev Returns the token SVG in base64 encoding.
	function encodedSVG(
		uint256 tokenId,
		bool embeddedFont,
		SVGColor svgColor,
		SVGType svgType
	) public view returns (string memory svgData) {
		return
			Base64.encode(
				abi.encodePacked(
					tokenSVG(tokenId, embeddedFont, svgColor, svgType)
				)
			);
	}

	enum SVGType {
		Square,
		Unpadded,
		Icon
	}
	enum SVGColor {
		WhiteBlack,
		NoneWhite,
		NoneBlack
	}

	/// @dev Returns the token SVG
	function tokenSVG(
		uint256 tokenId,
		bool embeddedFont,
		SVGColor svgColor,
		SVGType svgType
	) public view returns (string memory) {
		(
			,
			Trait[4] memory typeTraits,
			Trait[4] memory rangeTraits,

		) = tokenIdToTraits(tokenId);
		return
			_tokenSVG(typeTraits, rangeTraits, embeddedFont, svgColor, svgType);
	}

	/// @dev Returns the token SVG
	function _tokenSVG(
		Trait[4] memory typeTraits,
		Trait[4] memory rangeTraits,
		bool embeddedFont,
		SVGColor svgColor,
		SVGType svgType
	) private view returns (string memory) {
		string memory viewBox = svgType == SVGType.Unpadded
			? "0 0 400 100"
			: "0 0 400 400";
		string memory fontSize = svgType == SVGType.Icon ? "400px" : "100px";

		string memory text;
		if (svgType == SVGType.Icon) {
			text = string.concat(
				unicode"<text x='50%' y='50%' style='baseline-shift: 25px;font-variation-settings: &#x22;wght&#x22; ",
				rangeTraits[0].trait_extra, // weight
				"'>",
				typeTraits[0].trait_extra, // char
				"</text>"
			);
		} else {
			text = "<text x='50%' y='50%'>";
			for (uint i = 0; i < 4; i++) {
				text = string.concat(
					text,
					unicode"<tspan style='font-variation-settings: &#x22;wght&#x22; ",
					rangeTraits[i].trait_extra, // weight
					"'>",
					typeTraits[i].trait_extra, // char
					"</tspan>"
				);
			}
			text = string.concat(text, "</text>");
		}

		return
			string.concat(
				"<svg viewBox='",
				viewBox,
				"' preserveAspectRatio='xMidYMid meet' xmlns='http://www.w3.org/2000/svg'><defs><style>",
				embeddedFont
					? string.concat(
						"@font-face{font-family:tb;font-weight:0 660;src:url(data:application/font-woff2;charset=utf-8;base64,",
						IFont(fontContractAddress).getFont(FONT_ID),
						") format('woff2')}"
					)
					: "",
				"text{font-family:tb;fill:",
				svgColor == SVGColor.NoneWhite ? "#fff" : "#000",
				";font-size:",
				fontSize,
				";text-anchor: middle;dominant-baseline: central;}</style></defs>",
				svgColor == SVGColor.WhiteBlack
					? "<rect width='100%' height='100%' fill='#fff' />"
					: "",
				text,
				"</svg>"
			);
	}

	/// @dev The stored base64 font
	address fontContractAddress;

	constructor(
		address tributeFactory,
		address _dnaStorageContractAddress,
		address _fontContractAddress,
		uint64 chainlinkKey
	)
		DropNFT(
			tributeFactory,
			_dnaStorageContractAddress,
			"PUNK",
			"PUNK",
			chainlinkKey
		)
	{
		fontContractAddress = _fontContractAddress;
	}

	/// @notice Set the storage contracts (font and dna).
	/// @dev This can only be done before entropy has been set,
	///		 i.e. before the minting has begun.
	/// @param font The address for the font storage contract
	/// @param dna The address for the dna storage contract
	function setResolvers(
		address font,
		address dna
	) external onlyOwnerOrDeployer {
		require(entropy == 0, "metadata already finalized");
		fontContractAddress = font;
		DNAResolverContract = ITokenDNAStorage(dna);
	}

	string[4] private LETTERS = ["P", "U", "N", "K"];

	string[5] private TYPES = [
		"0",
		"2",
		"3",
		"4",
		"1" // ORIGINAL but with a I instead of U.
	];

	string[20] private WEIGHTS = [
		"0", // Range 1
		"33",
		"66",
		"99",
		"132",
		"165",
		"198",
		"231",
		"264",
		"297",
		"330",
		"363",
		"396",
		"429",
		"462",
		"495",
		"561",
		"594",
		"628",
		"660" // Range 20
	];

	// "P","U","N","K",
	// "L","B","M","V",
	// "2","3","4","5",
	// "T","O","S","Z",
	// "P","I","N","K"
	// GLYPHS[4 * type + letter] = correct glyph
	string[20] private GLYPHS = [
		"P",
		"U",
		"N",
		"K",
		"L",
		"B",
		"M",
		"V",
		"2",
		"3",
		"4",
		"5",
		"T",
		"O",
		"S",
		"Z",
		"P",
		"I",
		"N",
		"K"
	];
	string[3] private MIXERS = ["STREETPRESS", "CREDOX", "UNICOPY"];

	/// @notice Traits for a specific token. Requires tokenDNA storage to exist.
	/// @param tokenId The ID of the token you require traits for
	function tokenIdToTraits(
		uint256 tokenId
	)
		public
		view
		returns (
			Trait memory mixerTrait,
			Trait[4] memory typeTraits, // First letterTrait is type, second is range or none.
			Trait[4] memory rangeTraits, // First letterTrait is type, second is range or none.
			Trait[] memory allTraits
		)
	{
		bytes4[4] memory letterDNA = [bytes4(0), 0, 0, 0];

		bytes16 dna = tokenDNA(tokenId);

		assembly {
			mstore(letterDNA, dna)
			mstore(add(letterDNA, 28), dna) // 28 = 32-4. See https://ethereum.stackexchange.com/a/35274
			mstore(add(letterDNA, 56), dna)
			mstore(add(letterDNA, 84), dna)
		}

		// DNA per letter:
		// byte 0 - type
		// byte 1 - range
		// byte 2 - mixer
		// byte 3 - UNUSED (set to 33 dec == 21 hex to make the delimeter clear)

		allTraits = new Trait[](9);
		uint256 traitsSet;

		// First trait is Mixer. Use 3rd byte of first letter to set it:
		uint8 mixerType = uint8(letterDNA[0][2]) % 3;
		mixerTrait = Trait("MACHINE", MIXERS[mixerType], "");
		allTraits[traitsSet++] = mixerTrait;

		for (uint l = 0; l < 4; l++) {
			// First byte decides type:
			uint8 letterType = uint8(letterDNA[l][0]) % 5; // dna for byte should not be over 4.

			typeTraits[l] = Trait(
				string.concat(LETTERS[l], " SERIES"),
				TYPES[letterType],
				GLYPHS[4 * letterType + l]
			);
			allTraits[traitsSet++] = typeTraits[l];

			// Set range through second byte.
			uint256 rangeType = uint8(letterDNA[l][1]) % 21; // The range. Always at least 1 and at most 20.

			rangeTraits[l] = Trait(
				string.concat(LETTERS[l], " COPY"),
				rangeType.toString(),
				WEIGHTS[rangeType - 1]
			);
			allTraits[traitsSet++] = rangeTraits[l];
		}
	}

	function dropUUID() external pure override returns (string memory) {
		return "";
	}

	function provenanceHash() external pure override returns (string memory) {
		return "";
	}

	function _encodedBaseURI() internal pure override returns (bytes32) {
		return
			0x7b957997f488ae05c66002a4b6416afff084b7065cbb580144af328e4bb5fd04;
	}

	function _unrevealedBaseURI()
		internal
		pure
		override
		returns (string memory)
	{
		return "";
	}

	function _reservedSupply() internal pure override returns (uint256) {
		return 500;
	}

	function _maxSupply() internal pure override returns (uint256) {
		return 10000;
	}

	function _isRevealed() internal pure override returns (bool) {
		return true;
	}

	function _useEntropy() internal pure override returns (bool) {
		return false;
	}

	function tokenURI(
		uint256 tokenId
	) public view override returns (string memory result) {
		if (!_exists(tokenId)) return "404";
		(
			,
			Trait[4] memory typeTraits,
			Trait[4] memory rangeTraits,
			Trait[] memory allTraits
		) = tokenIdToTraits(tokenId);

		string memory svg = _tokenSVG(
			typeTraits,
			rangeTraits,
			true,
			SVGColor.NoneBlack,
			SVGType.Square
		);

		result = string(
			abi.encodePacked(
				"data:application/json;base64,",
				Base64.encode(
					abi.encodePacked(
						'{"name":"PUNK #',
						tokenId.toString(),
						'","description": "PUNKS NOT DEAD"',
						',"attributes": [',
						_traitsToAttributeString(allTraits),
						'],"aspect_ratio": 1,"image": "data:image/svg+xml;base64,',
						Base64.encode(abi.encodePacked(svg)),
						'"',
						',"animation_url":"data:text/html;charset=utf-8;base64,',
						Base64.encode(
							abi.encodePacked(
								"<html><head><meta charset='UTF-8'><style>html,body,svg{margin:0;padding:0; width:100%;height:100%;text-align:center;}</style></head><body>",
								svg,
								"</body></html>"
							)
						),
						'"',
						"}"
					)
				)
			)
		);
	}

	function contractURI() external pure override returns (string memory) {
		bytes memory dataURI = abi.encodePacked(
			'{"name":"PUNK"',
			',"description": "THE PUNK DROP"',
			', "image":"https://imagedelivery.net/YHYKpZyJMGcjpDsPjj5XMw/52b8d6ca-081f-4459-b9bf-3046cd279800/public"',
			', "external_link":"https://tribute-brand.com/", "seller_fee_basis_points": 750, "fee_recipient": "0xCF04B138F6ec0f2a6E44fD36E244b4B07798027f" ',
			"}"
		);

		return
			string(
				abi.encodePacked(
					"data:application/json;base64,",
					Base64.encode(dataURI)
				)
			);
	}
}