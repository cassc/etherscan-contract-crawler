// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/utils/Strings.sol";

contract WriteSVG {
    mapping(string => string) private LETTERS;
    mapping(string => uint256) private LETTER_WIDTHS;

    constructor() {
		LETTERS["0"] = "<path d='M1 1H2L2 4H1L1 1ZM1 1H0V4H1L1 5H2L2 4H3L3 1H2L2 0H1L1 1Z'/>";
		LETTERS["1"] = "<path d='M0 0V1H1V5H2V1V0H1H0Z'/>";
		LETTERS["2"] = "<path d='M2 1H0V0H3L3 1L3 3L2 3L1 3L1 4H3L3 5H0V4V3V2L2 2L2 1Z'/>";
		LETTERS["3"] = "<path d='M3 1L3 0H2H0V1L2 1V2L0 2V3L2 3V4H0V5H2H3L3 4L3 3L3 2V1Z'/>";
		LETTERS["4"] = "<path d='M3 5H2L2 3H1L0 3V2V0H1L1 2L2 2L2 0H3L3 2L3 3V5Z'/>";
		LETTERS["5"] = "<path d='M0 0H1H3V1H1V2H2V3H1H0V0ZM2 3H3V4V5H0V4H2V3Z'/>";
		LETTERS["6"] = "<path d='M0 4V3V2V0H0.999999L1 2H2L3 2L3 3L3 4L3 5H2H1H0V4ZM2 4V3L1 3L1 4H2Z'/>";
		LETTERS["7"] = "<path d='M3 1L3 0H2H0V1L2 1L2 5H3V1Z'/>";
		LETTERS["8"] = "<path d='M2 1L1 1L1 2L2 2V1ZM2 0H3L3 1L3 2L3 3L3 4L3 5H2H1H0V4V3V2V1V0H1H2ZM2 4V3L1 3L1 4H2Z'/>";
		LETTERS["9"] = "<path d='M1 1L2 1V2L1 2L1 1ZM1 0H2H3L3 1L3 2L3 3V5H2L2 3H1L0 3V2V1V0H1Z'/>";

		LETTERS["A"] = "<path d='M0 3V5H1V3L2 3V5H3V3V2V1V0H2H1H0V1V2V3ZM1 2H2V1H1V2Z'/>";
		LETTERS["B"] = "<path d='M1 0H0V5H1H2H3V3H2V2H3V0H2H1ZM2 2H1V1H2V2ZM2 4V3H1V4H2Z'/>";
		LETTERS["C"] = "<path d='M0 0H1H3V1L1 1V4H3V5H1H0V4V1V0Z'/>";
		LETTERS["D"] = "<path d='M0 1V4V5H1H2H3V1H2V0H1H0V1ZM2 4V1L1 1V4H2Z'/>";
		LETTERS["E"] = "<path d='M1 0H0V1V4V5H1H3V4H1V3H2V2H1L1 1L3 1V0H1Z'/>";
		LETTERS["F"] = "<path d='M0 0H1H3V1L1 1V2H2V3H1V5H0V3V2V1V0Z'/>";
		LETTERS["G"] = "<path d='M0 1V4V5H1H2H3V4V2H2V4H1V1L3 1V0H1H0V1Z'/>";
		LETTERS["H"] = "<path d='M0 0H1L1 2H2V0H3V2V3V5H2V3H1V5H0V0Z'/>";
		LETTERS["I"] = "<path d='M0 1V0H1H2H3V1L2 1V4H3V5H2H1H0V4H1V1L0 1Z'/>";
		LETTERS["J"] = "<path d='M0 0H2H3V1V4V5H2H1H0V4V3H1V4H2V1L0 1V0Z'/>";
		LETTERS["K"] = "<path d='M1 0H0V2V3V5H1V3H2V5H3L3 3H2V2H3L3 0H2L2 2H1V0Z'/>";
		LETTERS["L"] = "<path d='M1 0H0V4V5H1H3V4H1V0Z'/>";
		LETTERS["M"] = "<path d='M1 5H0V0H1L1 1L2 1V2L1 2L1 5ZM3 2V3H2L2 2L3 2ZM3 2L3 1L4 1L4 0H5L5 5H4V2H3Z'/>";
		LETTERS["N"] = "<path d='M0 0H1V5H0V0Z M1 1H2V3H1V1Z M2 2H3V4H2V2Z M3 0H4V5H3V0Z'/>";
		LETTERS["O"] = "<path d='M0 5H1H2H3L3 0H2H1H0V5ZM2 4L2 1L1 1L1 4H2Z'/>";
		LETTERS["P"] = "<path d='M0 5H1L1 3L3 3L3 2L3 1L3 0H1H0V5ZM2 1L1 1L1 2L2 2L2 1Z'/>";
		LETTERS["Q"] = "<path d='M0 5H1H2L2 4H3L3 0H2H1H0V5ZM1 4L1 1L2 1L2 4H1Z'/>";
		LETTERS["R"] = "<path d='M1 5H0V0H1H3L3 1V2L2 2L2 1L1 1V2L2 2L2 3H1V5ZM2 3H3L3 5H2L2 3Z'/>";
		LETTERS["S"] = "<path d='M1 3H0V0H1H3L3 1L1 1L1 2L2 2H3L3 3L3 4V5H2H0V4L2 4L2 3L1 3Z'/>";
		LETTERS["T"] = "<path d='M3 1L3 0H2H1H0V1L1 1L1 5H2L2 1L3 1Z'/>";
		LETTERS["U"] = "<path d='M1 5H0V4V0H1L1 4L2 4L2 0H3L3 4V5H2H1Z'/>";
		LETTERS["V"] = "<path d='M1 4H0V0H1L1 4ZM2 4H1V5H2L2 4ZM2 4L2 0H3L3 4H2Z'/>";
		LETTERS["W"] = "<path d='M4 0L5 0L5 5H4L4 4H3V3H4V0Z M2 3L2 2H3L3 3L2 3Z M2 3L2 4L1 4L1 5H0L0 0L1 0L1 3H2Z'/>";
		LETTERS["X"] = "<path d='M1 2H0V0H1L1 2ZM2 2H1L1 3H0V5H1L1 3H2L2 5H3L3 3H2L2 2ZM2 2L2 0H3L3 2H2Z'/>";
		LETTERS["Y"] = "<path d='M1 3H0V0H1L1 3ZM2 3H1V5H2L2 3ZM2 3L2 0H3L3 3H2Z'/>";
		LETTERS["Z"] = "<path d='M2 1H0V0H3L3 1L3 2L2 2L2 1ZM1 3L1 2L2 2L2 3H1ZM1 3L1 4H3L3 5H0V4V3L1 3Z'/>";
		LETTERS["a"] = LETTERS["A"];
		LETTERS["b"] = LETTERS["B"];
		LETTERS["c"] = LETTERS["C"];
		LETTERS["d"] = LETTERS["D"];
		LETTERS["e"] = LETTERS["E"];
		LETTERS["f"] = LETTERS["F"];
		LETTERS["g"] = LETTERS["G"];
		LETTERS["h"] = LETTERS["H"];
		LETTERS["i"] = LETTERS["I"];
		LETTERS["j"] = LETTERS["J"];
		LETTERS["k"] = LETTERS["K"];
		LETTERS["l"] = LETTERS["L"];
		LETTERS["m"] = LETTERS["M"];
		LETTERS["n"] = LETTERS["N"];
		LETTERS["o"] = LETTERS["O"];
		LETTERS["p"] = LETTERS["P"];
		LETTERS["q"] = LETTERS["Q"];
		LETTERS["r"] = LETTERS["R"];
		LETTERS["s"] = LETTERS["S"];
		LETTERS["t"] = LETTERS["T"];
		LETTERS["u"] = LETTERS["U"];
		LETTERS["v"] = LETTERS["V"];
		LETTERS["w"] = LETTERS["W"];
		LETTERS["x"] = LETTERS["X"];
		LETTERS["y"] = LETTERS["Y"];
		LETTERS["z"] = LETTERS["Z"];

		LETTERS["*"] = "<path d='M0 2V1H1L1 2L0 2ZM2 2L1 2V3H0V4L1 4V3L2 3V4L3 4V3L2 3V2ZM2 2L3 2V1H2V2Z'/>";
		LETTERS["="] = "<path d='M0 1V2L3 2V1H0ZM0 3V4L3 4V3L0 3Z'/>";
		LETTERS["<"] = "<path d='M1 4L0 4L0 5L1 5L1 4ZM2 3L2 4L1 4L1 3L2 3ZM2 2L2 3L3 3L3 2L2 2ZM1 1L1 2L2 2L2 1L1 1ZM1 1L1 0L0 0L0 1L1 1Z'/>";
		LETTERS[">"] = "<path d='M2 1H3L3 0H2V1ZM1 2L1 1H2V2H1ZM1 3L1 2H0V3H1ZM2 4L2 3H1L1 4H2ZM2 4V5H3L3 4H2Z'/>";
		LETTERS[","] = "<path transform='translate(0, 1)' d='M1 4H2L2 3H1L1 4ZM1 4H0V5H1L1 4Z'/>";
		LETTERS["."] = "<rect x='1' y='5' width='1' height='1' transform='rotate(180 1 5)'/>";
		LETTERS[":"] = "<path d='M0 1V2L1 2L1 1H0ZM0 3V4L1 4L1 3H0Z'/>";
		LETTERS[";"] = "<path d='M1 2L1 1H2V2L1 2ZM1 5L1 3H2V5L1 5ZM1 5V6H0V5H1Z'/>";
		LETTERS["!"] = "<path d='M0 3H1L1 0H0V3ZM0 5H1L1 4H0V5Z'/>";
		LETTERS["?"] = "<path d='M2 0H0V1H2V2H1V3H2V2H3V0H2ZM2 4H1V5H2V4Z'/>";
		LETTERS["+"] = "<path d='M2 1H1L1 2L0 2V3L1 3L1 4L2 4L2 3L3 3V2L2 2L2 1Z'/>";
		LETTERS["-"] = "<path d='M0 3L0 2L3 2V3L0 3Z'/>";
		LETTERS["$"] = "<path transform='translate(0, -1)' d='M1 1L1 0H2L2 1H3L3 2L1 2L1 3L2 3H3L3 4L3 5V6H2L2 7H1L1 6H0V5L2 5L2 4L1 4H0V1L1 1Z'/>";
		LETTERS["#"] = "<path d='M1 5H2L2 4H3V5H4V4H5V3H4V2H5V1H4V0H3V1H2L2 0H1L1 1H0V2H1L1 3H0V4H1L1 5ZM3 2H2L2 3H3V2Z'/>";
		LETTERS[" "] = "";

		LETTER_WIDTHS["DEFAULT"] = 3;
		LETTER_WIDTHS[" "] = 1;
		LETTER_WIDTHS["."] = 1;
		LETTER_WIDTHS[":"] = 1;
		LETTER_WIDTHS["!"] = 1;
		LETTER_WIDTHS[","] = 2;
		LETTER_WIDTHS[";"] = 2;
		LETTER_WIDTHS["N"] = 4;
		LETTER_WIDTHS["n"] = 4;
		LETTER_WIDTHS["#"] = 5;
		LETTER_WIDTHS["M"] = 5;
		LETTER_WIDTHS["m"] = 5;
		LETTER_WIDTHS["W"] = 5;
		LETTER_WIDTHS["w"] = 5;
    }

	function upperCase(string memory text, uint256 i) internal pure returns (string memory) {
		bytes memory firstCharByte = new bytes(1);
		firstCharByte[0] = bytes(text)[i];
		return 	string(firstCharByte);
	}

    function write(string memory text, string memory color, uint256 spacing, uint256 y) view public returns (string memory) {
		uint256 letterPos = 0;
		string memory letters = "";

		for (uint256 i = 0; i < bytes(text).length; i++) {
			string memory normalized = upperCase(text, i);
			string memory path = LETTERS[normalized];
			uint256 width = LETTER_WIDTHS[normalized] != 0
				? LETTER_WIDTHS[normalized]
				: LETTER_WIDTHS["DEFAULT"];

			if (bytes(path).length <= 0) continue;
			
			letters = string(abi.encodePacked(letters,"<g transform='translate(",Strings.toString(letterPos),")'>",path,"</g>"));
			letterPos = letterPos + width + spacing;
		}
		
		uint256 cx = (100 - (letterPos/2));
		string memory svg = string(abi.encodePacked("<g  transform='scale(0.5) translate(",Strings.toString(cx),",", Strings.toString(y),")' fill='",color,"' fill-rule='evenodd' clip-rule='evenodd' aria-label='",text,"'>",letters,"</g>"));
		return svg;
    }
}