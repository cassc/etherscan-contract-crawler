// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";

contract SVG {
	function render(string memory dateStr) public pure returns (string memory) {
		uint256 hue;
		uint256 sat;
		uint256 lum;
		{
			uint256 seed = uint256(keccak256(abi.encodePacked(dateStr)));
			uint256 maxHue;
			uint256 minHue;
			uint256 maxSat;
			uint256 minSat;
			uint256 maxLum;
			uint256 minLum;
			uint256 count = 0;
			uint256 noise = rand(seed, ++count) % 100;
			if (noise < 80) {
				maxHue = 181;
				minHue = 159;
				maxSat = 35;
				minSat = 12;
				maxLum = 12;
				minLum = 7;
				if (noise < 5) {
					maxSat = 100;
					minSat = 99;
					maxLum = 25;
					minLum = 15;
					if (noise < 1) {
						maxHue = 370;
						minHue = 350;
						maxLum = 40;
						minLum = 10;
					}
				}
			} else if (noise >= 80 && noise < 85) {
				maxHue = 59;
				minHue = 24;
				maxSat = 15;
				minSat = 8;
				maxLum = 13;
				minLum = 8;
			} else if (noise >= 85 && noise <= 100) {
				maxHue = 215;
				minHue = 205;
				maxSat = 90;
				minSat = 50;
				maxLum = 30;
				minLum = 15;
			}
			hue = minHue + (rand(seed, ++count) % (maxHue - minHue));
			sat = minSat + (rand(seed, ++count) % (maxSat - minSat));
			lum = minLum + (rand(seed, ++count) % (maxLum - minLum));
		}
		return
			string(
				abi.encodePacked(
					'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 660 500"><style>svg{background-color:#000;}@font-face{font-family:"Today";src:url("data:application/font-woff2;charset=utf-8;base64,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")format("woff2");}text{fill:#fff;font-family:Today;}</style><rect width="100%" height="100%" style="fill:hsl(',
					Strings.toString(hue),
					",",
					Strings.toString(sat),
					"%,",
					Strings.toString(lum),
					'%);" /><text x="50%" y="260px" text-anchor="middle" dominant-baseline="central" font-size="90px">',
					dateStr,
					"</text></svg>"
				)
			);
	}

	function rand(uint256 seed0, uint256 seed1) private pure returns (uint256) {
		return uint256(keccak256(abi.encodePacked(seed0, seed1)));
	}
}