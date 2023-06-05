// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./IERC4906.sol";

contract Vote is ERC721("Vote", "VOTE"), IERC4906, Ownable {
	mapping(uint256 => bool) yesByTokenId;
	uint256 private id = 0;
	uint256 private yesNum = 0;

	function I_am_not_happy() public {
		_vote(false);
	}

	function I_am_Happy() public {
		_vote(true);
	}

	function _vote(bool yes) private {
		bool beforeMint = _yes();
		if (yes) yesNum++;
		uint256 tokenId = ++id;
		yesByTokenId[tokenId] = yes;
		_mint(_msgSender(), tokenId);
		if (beforeMint != _yes()) emit BatchMetadataUpdate(1, tokenId);
	}

	function _yes() private view returns (bool) {
		return yesNum >= id - yesNum;
	}

	function totalSupply() public view returns (uint256) {
		return id;
	}

	function tokenURI(uint256 tokenId) public view override returns (string memory) {
		require(_exists(tokenId), "nonexistent token");
		bool yes = yesByTokenId[tokenId];
		string memory iam = "I am happy.";
		string memory weare = "We are happy.";
		string
			memory typography = '<g class="a"><path d="M135.1 302.3c12.8 53.7 18.7 78.1 28.3 130.6 3.7-19.8 23.9-104.7 28.6-129.1 8.5 52.9 14.8 77.2 22.6 130.6 1.9-14 19.3-85.6 29.3-131.3M262.8 403.6c4.8-.1 22.3-5.2 32.4-16.9 12.4-14.2 2.1-42.9-20.4-33.6-14.3 5.9-22.3 21.4-22.3 38.6 0 16.1 8 34.5 24.5 34.5 7.4 0 14.9-2.2 20.3-4.8M383.7 356.1c-3.7-4.5-7.8-6.9-13-6.9-18.2 0-31.5 28.9-31.5 50.9 0 12.6 6 22.1 16.5 22.1 21.7 0 30.3-42.3 30-54.7.8 6.5-4.6 24.8 11.4 52.1M410.5 348.8c3.1 10.9 3.8 18.5 4.5 29.8 1 16.6 1.6 35.5 1.5 52.2.5-16.3 1-45 10.3-58.3 11.3-16.1 18.3-21.3 29.1-25.9M465.1 393.3c5.5-.4 11.1-.8 16.5-2.3 5.3-1.5 9.9-4.5 13.8-8.1 16.8-15.9 9.3-34.1-8.1-34.1-19 0-31.9 14-31.9 36.2 0 21.9 8.3 38.7 23.2 38.7 11.1 0 19.1-6.5 22-9M548.6 302.3c-1.7 37.9-2.5 116.7-4.2 133.3 0-56.2 38.5-93.6 38.5-93.6s14.5 15.1 14.5 84M663.1 357.6c-2.3-3.4-9-10.8-16.4-10.8-18 0-31.6 29.3-31.6 46.9 0 16.8 9 28.7 22.8 28.7 16.1 0 31.1-16.7 23.5-60.3 2.2 18.2 9.3 39.7 17 60.3M696.6 344.9c0 44.7.1 77.2-1.5 114.8"/><path d="M688.6 350.3c35.1-3.7 53.1 8.4 53.1 33 0 32-26.6 38.7-37.5 38.7M759.2 346.9c.3 43.1-1.2 67.5-2.3 112.8M759.9 349.4c38.5-2.6 49.7 20.5 49.7 37 0 24.2-24.8 36.7-45.4 36.7M817.7 348.8c12.1 25.3 22.5 46.2 35.6 71"/><path d="M880.6 349.5c-17.5 44.5-30.9 67.4-50.2 110.2M896.6 423.9 896.7 426.9"/></g>';

		if (!yes) iam = "I am not happy.";
		if (!_yes()) {
			weare = "We are not happy.";
			typography = '<g class="b"><path d="M80.5 311.5c6.6 30.4 18.9 94.4 23.1 124.4 8.7-54.9 18.6-69.7 29.5-124.2 2.4 13.2 19.2 84 24.8 124.4 10.6-56.1 18.7-81.9 32.5-127.4M203.4 399.9c14.3-1.9 30.5-11.7 30.5-25 0-8.4-6.9-16-16.8-16-13 0-19.4 12.1-21.2 17.6-3.1 9.4-4.2 20.2-2 29.8 2.2 9.7 10 18.7 20 19.3 5 .3 13.3-2.3 18.8-6.6M314.1 368.7c-3.7-12.2-11.7-12.8-14.3-12.8-11.2 0-29.2 17.1-29.2 47.4 0 12.2 6.4 21.2 15.7 21.2 26.7 0 26.1-35.7 26.1-48 .4 18.2 3.5 29 10.5 45.6M337.3 355.9c5.3 24.9 3.8 52.8 4 76.6 0-18.1 1.2-40.4 10-56.5 3.4-6.3 14.4-15.1 22.1-18.3M381.8 403.4c10-1.8 38-11.2 38-30 0-12.1-9.6-16-19.1-16-15.3 0-24.6 19.1-24.6 38 0 10.3 5.2 29.4 22.1 29.4 9.1 0 17.4-4.7 21.9-8.3M458.6 358c2.7 20.3 3.5 52.5 3.5 73.5 0-11-.3-23.9 1.9-34.9 3.8-19.2 21.2-40.7 21.2-40.7s13.5 16.4 13.5 66.1M532.8 365c-7.7 2.6-18.2 12-18.2 30.5 0 23.7 12.6 28.2 20.3 28 7.7-.2 20.5-6.2 20.5-30.6 0-18.8-14-23.4-20.9-23.4M562.7 359.5c14.1.5 27.9.7 42 .7"/><path d="M584.9 330.4c-1.7 32.5-1.5 64-2.5 96M639 310c-2.3 51.4-3.6 71.8-3.4 121.7-.1-28.3 15.5-61.7 32.4-81.8 12.3 23.8 17.1 46.2 16.2 73.1M743 364.7c-4-4.9-9.7-10.4-18.9-10.4-6.9 0-26.6 16.6-26.6 44.2 0 11.7 5.6 23.2 19.5 23.2 22.7 0 25.1-40 25.6-50.2 2 17 5.8 33.9 11.3 50.2M774.4 355.9c0 32.5-3.1 78.4-4.3 103.5"/><path d="M766 357.9c6.2-.9 19.6-2.7 29.7 1.4 11.2 4.5 21.4 18.3 16.1 37.8-4.5 16.3-23.6 22.4-37.4 22.4M828.3 357c5.9 29.4 4.8 91.4 4.6 102.4M830.7 360.1c8.4-1.7 24.7-3.4 33.5 4.2 11.6 9.9 11.1 31.9 4.9 40-6.4 8.2-15.2 15.1-33.9 15.1M881 358.7c10.3 22.6 24.4 46.4 34.3 63.4"/><path d="M934.7 360.2c-5.1 14.6-28.9 70.8-38.7 97.7M953.4 413.9 953.5 416.4"/></g>';
		}

		return
			string(
				abi.encodePacked(
					"data:application/json;base64,",
					Base64.encode(
						abi.encodePacked(
							'{"name": "#',
							Strings.toString(tokenId),
							" \u201C",
							iam,
							'\u201D", "image": "data:image/svg+xml;base64,',
							Base64.encode(
								abi.encodePacked(
									'<svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 1024 768" xml:space="preserve"><style type="text/css">svg{background-color:#17191e;}g{stroke-width:22;stroke-miterlimit:10;stroke-linecap:square;stroke-linejoin:bevel;fill:none;}.a{stroke:#ff006f;}.b{stroke:#05f68f;}</style>',
									typography,
									"</svg>"
								)
							),
							'","attributes":[{"trait_type":"Voted","value":"',
							iam,
							'"}]}'
						)
					)
				)
			);
	}
}