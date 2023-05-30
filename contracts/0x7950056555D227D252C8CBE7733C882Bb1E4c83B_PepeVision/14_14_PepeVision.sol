/**
 *Submitted for verification at Etherscan.io on 2022-01-21
 */
// SPDX-License-Identifier: MIT
/*
:,,,,,,,,,;??******?*:,:+???*??*:,,,,,,,,,,,,,,,,,,,,,,,,,,:
:,,,,,,,,+?*********??*??******?*:,,,,,,,,,,,,,,,,,,,,,,,,,:
:,,,,,,,+?************%?********?+,,,,,,,,,,,,,,,,,,,,,,,,,:
:,,,,,,;?****????????*??*********?:,,,,,,,,,,,,,,,,,,,,,,,,;
:,,,,,:?****???****???????????????+,,,,,,,,,,,,,,,,,,,,,,,,;
:,,,,,+?***??*********?%???????????+:,,,,,,,,,,,,,,,,,,,,,,:
:,,,,:?***********??????%?********???+,,,,,,,,,,,,,,,,,,,,,,
:,,,,+?********??????????%?*?????????%*,,,,,,,,,,,,,,,,,,,,,
:,,:+?********??????**????%%%???????%?%*,,,,,,,,,,,,,,,,,,,,
:,:*??******?????*?%#?,:;*????+?%##*;*?%;,,,,,,,,,,,,,,,,,,,
:,*???****?????+,?##%@*...,?+::@S#?#,.:+*,,,,,,,,,,,,,,,,,,,
:;?*??****????:[email protected]#%@S....;,.;@##[email protected];...+:,,,,,,,,,,,,,,,,,,
:?*********???:[email protected]@@@?...,:..;@@@@@:..:+:,,,,,,,,,,,,,,,,,,
+?***********??*:+#@@S,,,;?*::,%@@@?:+*?:,,,,,,,,,,,,,,,,,,,
?************????*?%?++*???????*?%????*;:,,,,,,,,,,,,,,,,,,,
?**************????????????*********??:,,,,,,,,,,,,,,,,,,,,,
?********************????***??***???+:,,,,,,,,,,,,,,,,,,,,,,
?******************????*****??%%????:,,,,,,,,,,,,,,,,,,,,,,,
?******************??***************?:,,,,,,,,,,,,,,,,,,,,,,
?***********************************?*,,,,,,,,,,,,,,,,,,,,,,
?************************************?:,,,,,,,,,,,,,,,,,,,,,
?*************?**********************?;,,,,,,,,,,,,,,,,,,,,,
?**********??????????***************???:,,,,,,,,,,,,,,,,,,,,
?*********?%???????????????????????????;,,,,,,,,,,,,,,,,,,,,
?*********????%%%%????????????????????*:,,,,,,,,,,,,,,,,,,,,
?*********???????????%%%???????????%%*,,,,,,,,,,,,,,,,,,,,,,
?*******??*?%??%?????????????????????+,,,,,,,,,,,,,,,,,,,,,,
?********??*******???????????????????:,,,,,,,,,,,,,,,,,,,,,,
+?********??***********?????????%%+;:,,,,,,,,,,,,,,,,,,,,,,,
%%??***************************?*:,,,,,,,,,,,,,,,,,,,,,,,,,,
SSS%????********************??*+:,,,,,,,,,,,,,,,,,,,,,,,,,,,
S%%S%%??????????*********???*;:,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
S%%%SSS%??????????????????S?:,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
*/
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract PepeVision is Ownable, ERC721 {
	using Counters for Counters.Counter;
	using Strings for uint256;

	Counters.Counter private currentTokenId;

	string public placeHolerTokenURI;
	string public baseTokenURI;
	string public mapHash;
	bool public isRevealed;
	bool public isMintingActive;
	uint256 public pepeCost;
	uint256 public maxSupply;
	uint256 public maxMint;
	address public pepeToken;
	address public treasury;

	constructor(uint256 _pepeCost) ERC721("Pepe Vision", "PPV") {
		pepeCost = _pepeCost;
		pepeToken = 0x6982508145454Ce325dDbE47a25d4ec3d2311933;
		treasury = 0xdc20E05e59D4359e7831C812f978313a7E90dfCd;
		maxSupply = 4200;
		maxMint = 69;
		mapHash = "8f7936f0acf561ae69d73866b513dbcdc01dd74e2838315d207b67883363a06f";
		placeHolerTokenURI = "ipfs://bafybeidmt76ztsjxengfjpyvsps6gj4mdbfmnoxaxycbqoezi7ohmfezde";
		baseTokenURI = "";
	}

	function mintWithPepe(uint256 amount) public {
		//total pepe amt * pepe cost
		uint256 totalPepe = amount * pepeCost;
		require(isMintingActive, "Minting is not active");
		require(currentTokenId.current() + amount <= maxSupply, "All Pepe Vision minted");
		require(amount <= maxMint, "Max mint is 69");
		require(IERC20(pepeToken).balanceOf(msg.sender) >= totalPepe, "Not enough Pepe");
		//Transfer Pepe to treasury
		require(IERC20(pepeToken).transferFrom(msg.sender, treasury, totalPepe));
		//Mint Pepe Vision
		for (uint256 i = 0; i < amount; i++) {
			currentTokenId.increment();
			uint256 newItemId = currentTokenId.current();
			_safeMint(msg.sender, newItemId);
		}
	}

	function tokenURI(uint256 tokenId) public view override returns (string memory) {
		require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
		if (isRevealed) {
			return string(abi.encodePacked(baseTokenURI, tokenId.toString()));
		} else {
			return placeHolerTokenURI;
		}
	}

	function teamDistoMint(address member, uint256 amount) external onlyOwner {
		require(currentTokenId.current() + amount <= maxSupply, "All Pepe Vision minted");
		for (uint256 i = 0; i < amount; i++) {
			currentTokenId.increment();
			uint256 newItemId = currentTokenId.current();
			_safeMint(member, newItemId);
		}
	}

	function mintFallback() external onlyOwner {
		// in the event we need to mint any stragglers
		uint256 remaining = maxSupply - currentTokenId.current();
		for (uint256 i = 0; i < remaining; i++) {
			currentTokenId.increment();
			uint256 newItemId = currentTokenId.current();
			_safeMint(msg.sender, newItemId);
		}
	}

	// because you never know
	function reSet(address _pepeToken, address _treasury, uint256 _cost) external onlyOwner {
		pepeToken = _pepeToken;
		treasury = _treasury;
		pepeCost = _cost;
	}

	function setURI(string memory _baseTokenURI) external onlyOwner {
		baseTokenURI = _baseTokenURI;
	}

	function setReveal(bool _isRevealed) external onlyOwner {
		isRevealed = _isRevealed;
	}

	function setMinting(bool _isMintingActive) external onlyOwner {
		isMintingActive = _isMintingActive;
	}
}