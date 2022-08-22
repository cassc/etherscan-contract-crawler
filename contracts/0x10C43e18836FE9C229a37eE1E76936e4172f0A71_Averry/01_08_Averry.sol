// SPDX-License-Identifier: CC0
pragma solidity ^0.8.14;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./Base64.sol";
import "./svg.sol";
import "./util.sol";

contract Averry is ERC721A, Ownable {
	string[][] public colorPalettes;

	constructor() ERC721A("AVERRY", "AVERRY") {
		colorPalettes.push(["#74DBD8", "#4AA5E1", "#6E59C2", "#FF7F6B", "#FFC663"]);
		colorPalettes.push(["#EBA5BF", "#EFCADB", "#F2F5F1", "#9CDEEC", "#D1D5F2"]);
		colorPalettes.push(["#ED5537", "#E47D49", "#EBB27D", "#E5D2AF", "#8BB2AA", "#239EA9", "#288EA3", "#3B4D6A"]);
		colorPalettes.push(["#D02B2F", "#315F8C", "#B8D9CD", "#FCD265", "#28A791", "#3B2C20"]);
		colorPalettes.push(["#C95239", "#4F9CBC", "#7FB7C3", "#E9E2D1", "#28252D"]);
		colorPalettes.push(["#2d3561", "#c05c7e", "#f3826f", "#ffb961"]);
		colorPalettes.push(["#f38181", "#fce38a", "#eaffd0", "#95e1d3"]);
		colorPalettes.push(["#48466d", "#3d84a8", "#46cdcf", "#abedd8"]);
		colorPalettes.push(["#cefff1", "#ace7ef", "#a6acec", "#a56cc1"]);
		colorPalettes.push(["#3a0088", "#930077", "#e61c5d", "#ffbd39"]);
		colorPalettes.push(["#35477d", "#6c5b7b", "#c06c84", "#f67280"]);
		colorPalettes.push(["#94978B", "#DBC6BE", "#E7E0D5", "#C59F93", "#554F4A", "#D1D0C7"]);
		colorPalettes.push(["#eb586f", "#d8e9f0", "#4aa0d5", "#454553"]);
		colorPalettes.push(["#511e78", "#8b2f97", "#cf56a1", "#fcb2bf"]);
		colorPalettes.push(["#f23557", "#f0d43a", "#22b2da", "#3b4a6b"]);
		colorPalettes.push(["#f9f7f7", "#dbe2ef", "#3f72af", "#112d4e"]);
		colorPalettes.push(["#e23e57", "#88304e", "#522546", "#311d3f"]);
		colorPalettes.push(["#ffb6b9", "#fae3d9", "#bbded6", "#8ac6d1"]);
		colorPalettes.push(["#d3f6f3", "#f9fce1", "#fee9b2", "#fbd1b7"]);
		colorPalettes.push(["#77857B", "#C2AD9C", "#5B5E60", "#E3D4CA", "#333333", "#F4F1E9"]);
		colorPalettes.push(["#454C56", "#CED2CA", "#9FB1B9", "#738084"]);
		colorPalettes.push(["#9A948B", "#ADAEA8", "#CFC8BC", "#77797C", "#D8D4D0"]);
		colorPalettes.push(["#000000", "#888888", "#ffffff"]);
	}

	function getColor(string memory _name, uint256 seed) internal view returns (string memory) {
		uint256 colorPalette = util.random(string.concat("color-pallete"), seed, 0, colorPalettes.length);
		// colorPalette = 0;
		uint256 color = util.random(_name, seed, 0, colorPalettes[colorPalette].length);
		return colorPalettes[colorPalette][color];
	}

	function point(uint256 x, uint256 y) internal pure returns (string memory) {
		return string.concat(util.i2s(x), ",", util.i2s(y), " ");
	}

	function getRect(
		uint256 seed,
		uint256 unit,
		uint256 x,
		uint256 y
	) internal view returns (string memory) {
		return
			svg.rect(
				string.concat(
					svg.prop("fill", getColor(string.concat("c", point(x, y)), seed)),
					svg.prop("x", util.i2s(x)),
					svg.prop("y", util.i2s(y)),
					svg.prop("width", util.i2s(unit)),
					svg.prop("height", util.i2s(unit))
				)
			);
	}

	function getTriangle(
		uint256 seed,
		uint256 unit,
		uint256 x,
		uint256 y,
		uint256 variation
	) internal view returns (string memory) {
		string memory points;
		if (variation == 0) points = string.concat(point(x, y), point(x + unit, y), point(x, y + unit));
		if (variation == 1) points = string.concat(point(x, y), point(x + unit, y), point(x + unit, y + unit));
		string memory shape2 = svg.el("polygon", string.concat(svg.prop("fill", getColor(string.concat("c2", point(x, y)), seed)), svg.prop("points", points)));
		return string.concat(getRect(seed, unit, x, y), shape2);
	}

	function getArc(
		uint256 seed,
		uint256 unit,
		uint256 x,
		uint256 y,
		uint256 variation
	) internal view returns (string memory) {
		string memory points;
		if (variation == 0) points = string.concat("M ", point(x, y), "A ", point(unit, unit), "0,0,0 ", point(x + unit, y + unit), "L ", point(x + unit, y), "Z");
		if (variation == 1) points = string.concat("M ", point(x, y + unit), "A ", point(unit, unit), "0,0,0 ", point(x + unit, y), "L ", point(x, y), "Z");
		if (variation == 2) points = string.concat("M ", point(x + unit, y + unit), "A ", point(unit, unit), "0,0,0 ", point(x, y), "L ", point(x, y + unit), "Z");
		if (variation == 3) points = string.concat("M ", point(x + unit, y), "A ", point(unit, unit), "0,0,0 ", point(x, y + unit), "L ", point(x + unit, y + unit), "Z");
		string memory shape2 = svg.el("path", string.concat(svg.prop("fill", getColor(string.concat("c2", point(x, y)), seed)), svg.prop("d", points)));
		return string.concat(getRect(seed, unit, x, y), shape2);
	}

	function getShape(
		uint256 seed,
		uint256 unit,
		uint256 x,
		uint256 y
	) internal view returns (string memory) {
		uint256 shapeSelect = util.random(string.concat("shape", point(x, y)), seed, 0, 10);
		string memory shape;

		if (shapeSelect < 3) {
			uint256 variation = util.random(string.concat("variation", point(x, y)), seed, 0, 2);
			shape = getTriangle(seed, unit, x, y, variation);
		} else if (shapeSelect < 6) {
			uint256 variation = util.random(string.concat("variation", point(x, y)), seed, 0, 4);
			shape = getArc(seed, unit, x, y, variation);
		} else {
			shape = getRect(seed, unit, x, y);
		}
		return shape;
	}

	function render(uint256 seed) internal view returns (string memory) {
		uint256 grid = util.random(string.concat("grid"), seed, 4, 9);
		uint256 border = 40;
		uint256 unit = (1000 - (border * 2)) / grid;

		string memory shapes = svg.rect(string.concat(svg.prop("fill", "#ffffff"), svg.prop("x", "0"), svg.prop("y", "0"), svg.prop("width", "1000"), svg.prop("height", "1000")));
		for (uint8 x = 0; x < grid; x++) {
			for (uint8 y = 0; y < grid; y++) {
				shapes = string.concat(shapes, getShape(seed, unit + 1, x * unit + border, y * unit + border));
			}
		}
		return svg.el("svg", string.concat(svg.prop("xmlns", "http://www.w3.org/2000/svg"), svg.prop("viewbox", "0 0 1000 1000"), svg.prop("width", "1000"), svg.prop("height", "1000")), shapes);
	}

	function preview(uint256 seed) external view returns (string memory) {
		return string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(bytes(render(seed)))));
	}

	////////// ERC721 and Ownable //////////

	mapping(uint256 => uint256) internal seeds;

	function __mint(address _address) internal {
		uint256 _tokenId = _nextTokenId();
		require(_tokenId <= 1000);

		_mint(_address, 1);
		seeds[_tokenId] = uint160(_address) + _tokenId;
	}

	function mint() external payable {
		__mint(msg.sender);
	}

	function airdrop(address _address) external onlyOwner {
		__mint(_address);
	}

	function withdraw() external payable onlyOwner {
		payable(owner()).transfer(address(this).balance);
	}

	function tokenURI(uint256 _tokenId) public view override returns (string memory) {
		require(_tokenId <= totalSupply());
		uint256 seed = seeds[_tokenId];
		require(seed > 0);

		string memory description = "AVERRY is a collection of geometric art on Ethereum generated 100% on-chain.";

		return
			string(
				abi.encodePacked(
					"data:application/json;base64,",
					Base64.encode(
						bytes(
							abi.encodePacked(
								'{"name":"AVERRY #',
								util.i2s(_tokenId),
								'", "description":"',
								description,
								'", ',
								'"attributes": [{"trait_type": "Seed", "value": "',
								util.i2s(seed),
								'"}]',
								', "image":"',
								string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(bytes(render(seed))))),
								'"}'
							)
						)
					)
				)
			);
	}
}