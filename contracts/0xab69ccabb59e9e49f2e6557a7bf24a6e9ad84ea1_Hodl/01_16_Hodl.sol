// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Hodl is ERC721, ERC721Enumerable, Ownable, ReentrancyGuard {
	using Counters for Counters.Counter;

	Counters.Counter private _tokenIds;
	uint256 private constant PRICE = 0.01 ether;
	uint256 private constant MAX_ELAPSED_TIME = 365 days;
	uint256 private constant MAX_SIZE = 1000;
	uint256 private constant MAX_SUPPLY = 100;
	mapping(uint256 => uint256) private _lastTransferTime;

	//-------------------------------------------

	constructor() ERC721("Hodl", "HODL") {}

	//-------------------------------------------

	function mint() public payable nonReentrant {
		require(_tokenIds.current() + 1 <= MAX_SUPPLY, "Exceeded max supply");
		require(msg.value == PRICE, "Incorrect payable amount");
		_tokenIds.increment();
		_safeMint(_msgSender(), _tokenIds.current());
	}

	function ownerMint(uint256 mintNum) public nonReentrant onlyOwner {
		require(_tokenIds.current() + mintNum <= MAX_SUPPLY, "Exceeded max supply");
		for (uint256 i = 0; i < mintNum; i++) {
			_tokenIds.increment();
			_safeMint(msg.sender, _tokenIds.current());
		}
	}

	//-------------------------------------------

	function getSize(uint256 tokenId) public view returns (uint256) {
		require(_exists(tokenId), "nonexistent token");
		uint256 elapsedTime = block.timestamp - _lastTransferTime[tokenId];
		return this.min(MAX_SIZE, this.max(0, (elapsedTime * MAX_SIZE) / MAX_ELAPSED_TIME));
	}

	function getMaxElapsedTime() external pure returns (uint256) {
		return MAX_ELAPSED_TIME;
	}

	function getMaxSize() external pure returns (uint256) {
		return MAX_SIZE;
	}

	function getPrice() external pure returns (uint256) {
		return PRICE;
	}

	function currentSupply() external view returns (uint256) {
		return _tokenIds.current();
	}

	function maxSupply() external pure returns (uint256) {
		return MAX_SUPPLY;
	}

	function isSoldOut() public view returns (bool) {
		bool _soldOut = false;
		if (_tokenIds.current() >= MAX_SUPPLY) {
			_soldOut = true;
		}
		return _soldOut;
	}

	//-------------------------------------------

	function tokenURI(uint256 tokenId) public view override returns (string memory) {
		require(_exists(tokenId), "nonexistent token");

		string[] memory colorStr = new string[](6);

		{
			uint256 count = 0;
			uint256[] memory totalRGB = new uint256[](3);
			uint256[] memory maxRGB = new uint256[](3);
			uint256[] memory targetRGB = new uint256[](3);

			for (uint256 i = 0; i < 3; i++) {
				maxRGB[i] = 300 + (this.rand(tokenId, ++count) % (600 - 300));
			}

			for (uint256 iy = 0; iy < 6; iy++) {
				for (uint256 ix = 0; ix < 3; ix++) {
					targetRGB[ix] = this.min(255, maxRGB[ix] - totalRGB[ix]);
					if (iy < 5) targetRGB[ix] = this.rand(tokenId, ++count) % targetRGB[ix];
					totalRGB[ix] += targetRGB[ix];
				}
				colorStr[iy] = string(
					abi.encodePacked(
						Strings.toString(targetRGB[0]),
						",",
						Strings.toString(targetRGB[1]),
						",",
						Strings.toString(targetRGB[2])
					)
				);
			}
		}

		uint256 radius;
		uint256 offset;
		string memory glowStr;

		{
			uint256 size = this.getSize(tokenId);

			uint256 minRadius = 50;
			uint256 maxRadius = 850;
			radius = minRadius + ((maxRadius - minRadius) * size) / MAX_SIZE;

			uint256 minOffset = 20;
			uint256 maxOffset = 250;
			offset = minOffset + ((maxOffset - minOffset) * size) / MAX_SIZE;

			uint256 minGlow = 0;
			uint256 maxGlow = 100;
			uint256 glow = minGlow + ((maxGlow - minGlow) * size) / MAX_SIZE;

			if (glow <= 0) glowStr = "0.5";
			else if (glow < 20) glowStr = "0.6";
			else if (glow < 40) glowStr = "0.7";
			else if (glow < 60) glowStr = "0.8";
			else if (glow < 80) glowStr = "0.9";
			else if (glow < 100) glowStr = "1.0";
			else if (glow == 100) glowStr = "2.0";
		}

		bytes memory svg;

		{
			svg = abi.encodePacked(
				'<?xml version="1.0" encoding="UTF-8"?><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 2048 2048"><defs><style>svg { background-color:#000; }g{ transform: translateY(calc(-0.01% * ',
				Strings.toString(offset),
				"));animation: 2.0s linear 0s infinite alternate loop2;}.cls {transform-origin: 50% calc(50% + calc(0.01% * ",
				Strings.toString(offset),
				'));animation: loop1 infinite linear;mix-blend-mode: screen;}@keyframes loop1 {0% { transform: rotate(0deg); }100% { transform: rotate(360deg); }}@keyframes loop2 {from { opacity: 1.0; }to { opacity: 0.9; }}g :nth-child(1) { animation-duration: calc(1.5s + 0.0s); animation-delay: -1.1s; }g :nth-child(2) { animation-duration: calc(1.5s + 0.2s); animation-delay: -0.7s; }g :nth-child(3) { animation-duration: calc(1.5s + 0.3s); animation-delay: -0.5s; }g :nth-child(4) { animation-duration: calc(1.5s + 0.5s); animation-delay: -0.3s; }g :nth-child(5) { animation-duration: calc(1.5s + 0.7s); animation-delay: -0.2s; }g :nth-child(6) { animation-duration: calc(1.5s + 1.1s); animation-delay: -0.0s; }</style><filter id="f" x="-20%" y="-20%" width="130%" height="130%" filterUnits="userSpaceOnUse"><feGaussianBlur in="SourceGraphic" result="f1" stdDeviation="200" /><feColorMatrix in="f1" result="f2" type="matrix" values="1 0 0 0 0 0 1 0 0 0 0 0 1 0 0 0 0 0 0.3 0" /><feGaussianBlur in="SourceGraphic" result="f3" stdDeviation="30" /><feColorMatrix in="f3" result="f4" type="matrix" values="1 0 0 0 0 0 1 0 0 0 0 0 1 0 0 0 0 0 0.7 0" /><feBlend in="f2" in2="f4" result="f5" mode="screen" /><feColorMatrix in="f5" result="f6" type="matrix" values="1 0 0 0 0 0 1 0 0 0 0 0 1 0 0 0 0 0 ',
				glowStr,
				' 0" /><feBlend in="SourceGraphic" in2="f6" mode="screen" /></filter><circle id="c" cx="50%" cy="50%" r="',
				Strings.toString(radius),
				'" filter="url(#f)" /></defs><g><use href="#c" class="cls" fill="rgb(',
				colorStr[0],
				')" /><use href="#c" class="cls" fill="rgb(',
				colorStr[1],
				')" /><use href="#c" class="cls" fill="rgb(',
				colorStr[2],
				')" /><use href="#c" class="cls" fill="rgb(',
				colorStr[3],
				')" /><use href="#c" class="cls" fill="rgb(',
				colorStr[4],
				')" /><use href="#c" class="cls" fill="rgb(',
				colorStr[5],
				')" /></g></svg>'
			);
		}

		bytes memory json;

		{
			uint256 elapsedTime = block.timestamp - _lastTransferTime[tokenId];
			uint256 day = elapsedTime / 86_400;
			string memory dayStr = " DAYS HODL #";
			if (day == 1) dayStr = " DAY HODL #";

			json = abi.encodePacked(
				'{"name": "',
				Strings.toString(day),
				dayStr,
				Strings.toString(tokenId),
				'", "description": "Hold On for Dear Life", "created_by": "bouze", "image_data": "data:image/svg+xml;base64,',
				Base64.encode(svg),
				'","attributes":[{"display_type": "number", "trait_type": "Days HODL", "value": "',
				Strings.toString(day),
				'"}]}'
			);
		}

		return string(abi.encodePacked("data:application/json;base64,", Base64.encode(json)));
	}

	//-------------------------------------------

	function withdraw() public onlyOwner {
		payable(owner()).transfer(address(this).balance);
	}

	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 tokenId
	) internal override(ERC721, ERC721Enumerable) {
		super._beforeTokenTransfer(from, to, tokenId);
		_lastTransferTime[tokenId] = block.timestamp;
	}

	function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
		return super.supportsInterface(interfaceId);
	}

	//-------------------------------------------

	function max(uint256 a, uint256 b) public pure returns (uint256) {
		return a >= b ? a : b;
	}

	function min(uint256 a, uint256 b) public pure returns (uint256) {
		return b >= a ? a : b;
	}

	function rand(uint256 seed0, uint256 seed1) public pure returns (uint256) {
		return uint256(keccak256(abi.encodePacked(seed0, seed1)));
	}
}