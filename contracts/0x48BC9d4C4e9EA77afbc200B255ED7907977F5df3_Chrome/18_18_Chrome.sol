// Chrome, Kim Asendorf & Leander Herzog, 2023
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Chrome is ERC721, ERC721Enumerable, ERC721Burnable, ReentrancyGuard, Pausable, Ownable {
	using Strings for uint256;

	uint256 public mintPrice;
	uint256 public supply;
	uint256 setId = 0;
	uint256 mintId = 128;

	string public title;
	string public description;
	string public script;
	string public imageURI;
	string public externalURL;

	mapping(address => bool) private allowlist;
	bool public isAllowlist = false;
	bool public isPublic = false;

	constructor(string memory _name, string memory _symbol, uint256 _mintPrice, uint256 _supply) ERC721(_name, _symbol) {
		mintPrice = _mintPrice;
		supply = _supply;
	}

	function pause() public onlyOwner {
		_pause();
	}

	function unpause() public onlyOwner {
		_unpause();
	}

	function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal whenNotPaused override(ERC721, ERC721Enumerable) {
		super._beforeTokenTransfer(from, to, tokenId, batchSize);
	}

	function mint(uint256 num) public payable whenNotPaused nonReentrant {
		require(isAllowlist && allowlist[msg.sender] || isPublic, "NOT_ELIGIBLE");
		require(mintId >= setId * 8 + num, "TOKENS_SOLD_OUT");
		require(mintPrice * num == msg.value, "WRONG_AMOUNT");
		for (uint256 i = 0; i < num; i++) {
			safeMint(mintId);
			mintId -= 1;
		}
	}

	function mintSet() public payable whenNotPaused nonReentrant {
		require(isAllowlist && allowlist[msg.sender] || isPublic, "NOT_ELIGIBLE");
		require(mintId >= setId * 8 + 8, "SETS_SOLD_OUT");
		require(mintPrice * 8 == msg.value, "WRONG_AMOUNT");
		for (uint256 i = 1; i <= 8; i++) {
			safeMint(setId * 8 + i);
		}
		setId += 1;
	}

	function ownerMint() public onlyOwner {
		safeMint(mintId);
		mintId -= 1;
	}

	function ownerMintSet() public onlyOwner {
		require(mintId >= (setId + 1) * 8, "SETS_SOLD_OUT");
		for (uint256 i = 1; i <= 8; i++) {
			safeMint(setId * 8 + i);
		}
		setId += 1;
	}

	function safeMint(uint256 tokenId) private {
		_safeMint(msg.sender, tokenId);
	}

	function withdraw(address recipient1, address recipient2) public payable onlyOwner {
		Address.sendValue(payable(recipient1), address(this).balance/2);
		Address.sendValue(payable(recipient2), address(this).balance);
	}

	function setMintPrice(uint256 _mintPrice) public onlyOwner {
		mintPrice = _mintPrice;
	}

	function setSupply(uint256 _supply) public onlyOwner {
		supply = _supply;
	}

	function getBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
		require(_exists(tokenId), "NOT_EXISTS");

		bytes memory html = buildHTML(tokenId);

		bytes memory attributes = abi.encodePacked(
			'[',
				'{"trait_type":"Set","value":"', ((tokenId-1)/8+1).toString(), '"},',
				'{"trait_type":"Layout","value":"', ((tokenId-1)%8+1).toString(), '"}',
			']'
		);

		bytes memory dataURI = abi.encodePacked(
			'{',
				'"name":"', title, ' ', tokenId.toString(), '",',
				'"description":"', description, '",',
				'"image":"', imageURI, tokenId.toString(), '.jpg",',
				'"external_url":"', externalURL, '?token=', tokenId.toString(), '",',
				'"animation_url":"data:text/html;base64,', Base64.encode(html), '",'
				'"attributes":', attributes,
			'}'
		);

		return string(
			abi.encodePacked(
				"data:application/json;base64,",
				Base64.encode(dataURI)
			)
		);
	}

	function _burn(uint256 tokenId) internal override(ERC721) {
		super._burn(tokenId);
	}

	function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
		return super.supportsInterface(interfaceId);
	}

	function setTitle(string memory _title) public onlyOwner {
		title = _title;
	}

	function setDescription(string memory _description) public onlyOwner {
		description = _description;
	}

	function setScript(string memory _script) public onlyOwner {
		script = _script;
	}

	function setImageURI(string memory _imageURI) public onlyOwner {
		imageURI = _imageURI;
	}

	function setExternalURL(string memory _externalURL) public onlyOwner {
		externalURL = _externalURL;
	}

	function addToAllowlist(address[] calldata toAdd) external onlyOwner {
		for (uint256 i = 0; i < toAdd.length; i++) {
			allowlist[toAdd[i]] = true;
		}
	}

	function removeFromAllowlist(address[] calldata toRemove) external onlyOwner {
		for (uint256 i = 0; i < toRemove.length; i++) {
			delete allowlist[toRemove[i]];
		}
	}

	function setIsAllowlist(bool _isAllowlist) public onlyOwner {
		isAllowlist = _isAllowlist;
	}

	function setIsPublic(bool _isPublic) public onlyOwner {
		isPublic = _isPublic;
	}

	function buildHTML(uint256 tokenId) internal view returns (bytes memory) {
		return abi.encodePacked(
			'<!DOCTYPE HTML><html>',
				'<head><meta name=\'viewport\' content=\'width=device-width,user-scalable=no,minimum-scale=1.0,maximum-scale=2.0\'></head>',
				'<body><script>let tId=', tokenId.toString(), ';', script, '</script></body></html>'
		);
	}

	function getHTML(uint256 tokenId) public view returns (string memory) {
		require(_exists(tokenId), "NOT_EXISTS");
		bytes memory html = buildHTML(tokenId);
		return string(html);
	}
}