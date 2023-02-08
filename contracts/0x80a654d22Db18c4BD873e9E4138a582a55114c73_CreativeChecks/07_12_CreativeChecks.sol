// SPDX-License-Identifier: MIT
                

//                      xx        
//                    xx                       
//                  xx                       
//                  xx             
//                xx                   
//       xx       xx
//     xxxxxx   xx
//          xx  xx
//           xxxx 
//            xx          CreativeChecks.com
//            xx          		- by AlphaDigger.eth


pragma solidity ^0.8.4;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./Errors.sol";

/**
 * @title CreativeChecks Smart Contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract CreativeChecks is ERC721AQueryable, Ownable, ReentrancyGuard {
	address private _withdrawalAddress;

	uint256 public mintStart;
	uint256 public mintEnd;
	string  public baseSvg = '<svg>';
	uint256 public mintPrice = 4000000000000000;
	string  public webURL = 'https://creativechecks.com/token/';

	string[] public badges = ["ffffff", "fece1f", "f7921b", "ff0521", "fe0c91", "4916a1", "1e42c9", "31a4f1", "1bb80c", "006506", "572800", "907135", "c1c1c1", "818080", "3f3e3f", "000000"];
	string[] public ticks = ["000000", "000000", "000000", "000000", "000000", "ffffff", "ffffff", "000000", "000000", "ffffff", "ffffff", "000000", "000000", "000000", "ffffff", "ffffff"];

	mapping(uint256 => bytes) public data;
	mapping(bytes => bool) public taken;


	constructor(string memory name, string memory symbol, address withdrawalAddress_, uint256 mintStart_, uint256 mintEnd_) ERC721A(name, symbol) {
		mintStart = mintStart_;
		mintEnd = mintEnd_;
		_withdrawalAddress = withdrawalAddress_;
	}


	/// @notice overrides original ERC721A _startTokenId()
	/// @return  uint256 new starting token id.
	function _startTokenId() override internal view virtual returns (uint256) {
		return 1;
	}


	/// @notice Mint one token with data and send to 'to' address.
	/// @param  to address that will receive the tokens.
	/// @param  data_ token data
	function ownerMint(address to, bytes calldata data_) external onlyOwner nonReentrant {
		if (block.timestamp > mintEnd) 
			revert Errors.MintOver();

		if (data_.length != 40) 
			revert Errors.DataInvalid();

		if (taken[data_])
			revert Errors.DataTaken();

		data[_nextTokenId()] = data_;
		taken[data_] = true;
		_safeMint(to, 1);
	}


	/// @notice Mint one token with data.
	/// @param  data_ token data
	function mint(bytes calldata data_) external payable nonReentrant {
		if (block.timestamp < mintStart) 
			revert Errors.MintNotStarted();

		if (block.timestamp > mintEnd) 
			revert Errors.MintOver();

		if (msg.value < mintPrice) 
			revert Errors.InsufficientFunds();

		if (data_.length != 40) 
			revert Errors.DataInvalid();

		if (taken[data_])
			revert Errors.DataTaken();


		data[_nextTokenId()] = data_;
		taken[data_] = true;
		_safeMint(msg.sender, 1);
	}


	/// @notice Returns token metadata.
	/// @param  tokenId id of the token.
	/// @return string token metadata.
	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
		if (!_exists(tokenId))
			revert Errors.TokenNotMinted();

		uint256[80] memory data_ = getUintArrayFromData(data[tokenId]);
		uint256 colors = countUnique(data_);

		string memory json    = Base64.encode(abi.encodePacked('{"name":"Creative Check #', Strings.toString(tokenId), '", "description": "This check may or may not be notable.", "external_url": "', string(abi.encodePacked(webURL, Strings.toString(tokenId))), '", "image":"', string(abi.encodePacked('data:image/svg+xml;base64,', Base64.encode(bytes(renderSvg(data_))))), '", "attributes": [{"trait_type": "Colors", "value": "', Strings.toString(colors), '"}]}'));
		string memory jsonUri = string(abi.encodePacked("data:application/json;base64,", json));

		return jsonUri;
	}


	/// @notice Generate a svg from token data
	/// @param  data_ uint256 array that contains the color index of each badge.
	/// @return string svg string.
	function renderSvg(uint256[80] memory data_) public view returns (string memory) {
		string memory svgString = baseSvg;
		for (uint i; i < 10; i++) {
			for (uint j; j < 8; j++) {
				svgString = string(abi.encodePacked(svgString, string(abi.encodePacked('<use xlink:href="#badge" fill="#', badges[data_[(i * 8) + j]], '" x="', Strings.toString(210 + j * 40), '" y="', Strings.toString(170 + i * 40), '" /><use xlink:href="#tick" fill="#', ticks[data_[(i * 8) + j]], '" x="', Strings.toString(210 + j * 40), '" y="', Strings.toString(170 + i * 40), '" />'))));
			}
		}

		svgString = string(abi.encodePacked(svgString, "</svg>"));
		return svgString;
	}


	/// @notice Returns token data as bytes.
	function tokenData(uint256 tokenId) public view returns (bytes memory) {
		if (!_exists(tokenId))
			revert Errors.TokenNotMinted();

		return data[tokenId];
	}

	/// @notice Withdraw all ether from the contract.
	function withdrawAll() external onlyOwner {
		uint256 balance = address(this).balance;
		if (balance == 0) revert Errors.NothingToWithdraw();
		(_withdrawalAddress.call{value: balance}(""));
	}
	
	/// @notice updates mintPrice.
	/// @param  mintPrice_ new mintPrice.
	function setMintPrice(uint256 mintPrice_) external onlyOwner {
		mintPrice = mintPrice_;
	} 

	/// @notice updates baseSvg.
	/// @param  baseSvg_ new baseSvg.
	function setBaseSvg(string calldata baseSvg_) external onlyOwner {
		baseSvg = baseSvg_;
	} 

	/// @notice updates webURL.
	/// @param  webURL_ new webURL.
	function setWebURL(string calldata webURL_) external onlyOwner {
		webURL = webURL_;
	} 

	/// @notice updates _withdrawalAddress.
	/// @param  newAddress new _withdrawalAddress.
	function setWithdrawalAddress(address newAddress) external onlyOwner {
		if (newAddress == address(0)) revert Errors.NewAddressCantBeZero();

		_withdrawalAddress = newAddress;
	} 

	/// @notice updates badges.
	/// @param  badges_ new badges.
	function setBadges(string[] memory badges_) external onlyOwner {
		if (badges_.length != 16)
			revert Errors.ArrayLengthInvalid();

		delete badges;
		badges = badges_;
	} 

	/// @notice updates ticks.
	/// @param  ticks_ new ticks.
	function setTicks(string[] memory ticks_) external onlyOwner {
		if (ticks_.length != 16)
			revert Errors.ArrayLengthInvalid();

		delete ticks;
		ticks = ticks_;
	} 

	/// @notice updates mint start date.
	/// @param  mintStart_ new start date.
	function setMintStartDate(uint256 mintStart_) external onlyOwner {
		mintStart = mintStart_;
	} 

	/// @notice updates mint end date.
	/// @param  mintEnd_ new end date.
	function setMintEndDate(uint256 mintEnd_) external onlyOwner {
		mintEnd = mintEnd_;
	}



	// Internal functions
	function getUintArrayFromData(bytes memory data_) internal pure returns (uint256[80] memory returnData) {
		for (uint i=0; i < data_.length * 2; i++) {
			uint256 value;
			uint256 index = i / 2;
			uint256 shift = i % 2 == 0 ? 4 : 0;

			assembly {
				let temp := mload(add(data_, add(index, 1)))
				value := shr(shift, and(shl(shift, shr(0xFC, not(0))), temp))
			}

			returnData[i] = value;
		}
	}

	function countUnique(uint256[80] memory arr) internal pure returns (uint256 count) {
		uint256[] memory uniqueArr = new uint256[](80);
		uint256 uniqueCount = 0;

		for (uint256 i = 0; i < arr.length; i++) {
			bool isUnique = true;
			for (uint256 j = 0; j < uniqueCount; j++) {
				if (arr[i] == uniqueArr[j]) {
					isUnique = false;
					break;
				}
			}

			if (isUnique) {
				uniqueArr[uniqueCount] = arr[i];
				uniqueCount++;
			}
		}

		count = uniqueCount;
	}
}