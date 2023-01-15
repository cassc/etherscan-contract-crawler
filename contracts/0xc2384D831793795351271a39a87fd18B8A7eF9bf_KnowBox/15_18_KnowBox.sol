// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import {SignatureChecker} from "./libs/SignatureChecker.sol";

import "./libs/KnowBoxInfo.sol";
import "./RandomHelp.sol";

contract KnowBox is ERC721Royalty, Ownable, RandomHelp {
	using Strings for uint256;
	using KnowBoxInfo for KnowBoxInfo.MintInfo;
	using KnowBoxInfo for KnowBoxInfo.OpenInfo;

	bytes32 public immutable DOMAIN_SEPARATOR;
	bool _isInit = false;
	uint256 private maxSupply = 800;
	uint256 private maxBalance = 1;
	uint256 private total;
	//7 * 24 * 60 * 60
	uint256 private openDelay = 604800;
	mapping(uint256 => KnowBoxInfo.BoxInfo) private _boxInfo;
	mapping(string => bool) private _cdkeyMap;

	string private baseURI;
	string public nonOpenUri = "https://sky.infura-ipfs.io/ipfs/QmZZkoQveZs2qKxny3jW2y426sS7APtWnnS9SYg2oroK3T";

	event MintNotice(address minter, uint256 tokenId, string cdkey);
	event OpenNotice(address operator, uint256 tokenId, uint256 dataIndex);

	constructor(address _royaltyReceiver, uint96 royalty) ERC721("KNOWBOX", "CBK") RandomHelp(maxSupply) {
		DOMAIN_SEPARATOR = keccak256(
			abi.encode(
				0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f,
				0x545a712f02f365da9d9517134f9a5d25d56b9fdb8d344bd43f7457d18b3ef54a,
				0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6,
				block.chainid,
				address(this)
			)
		);
		_setDefaultRoyalty(_royaltyReceiver, royalty);
	}

	function mintBox(KnowBoxInfo.MintInfo calldata mintInfo) external {
		require(tx.origin == msg.sender, "KnowBox:Not allow Contract");
		require(mintInfo.minter == msg.sender, "KnowBox:Validate minter Error");
		require(SignatureChecker.verifyMint(mintInfo, DOMAIN_SEPARATOR), "KnowBox:Validate Sign Error");
		require(balanceOf(msg.sender) + 1 <= maxBalance, "KnowBox:mint would exceed max balance");
		require(total < maxSupply, "KnowBox:mint would exceed max supply");
		require(!_cdkeyMap[mintInfo.cdkey], "KnowBox:cdkey is already used");
		uint256 _token = total;
		_safeMint(msg.sender, _token);
		KnowBoxInfo.BoxInfo storage setBoxInfo = _boxInfo[_token];
		setBoxInfo.open = false;
		setBoxInfo.dataIndex = 0;
		setBoxInfo.openTime = block.timestamp + openDelay;
		_cdkeyMap[mintInfo.cdkey] = true;
		total++;
		emit MintNotice(msg.sender, _token, mintInfo.cdkey);
	}

	function openBox(KnowBoxInfo.OpenInfo calldata openInfo) external {
		require(_exists(openInfo.token), "KnowBox: invalid token ID");
		require(ownerOf(openInfo.token) == msg.sender, "KnowBox:This token does not belong to you");
		require(!_boxInfo[openInfo.token].open, "KnowBox:Box is already opend");
		require(_boxInfo[openInfo.token].openTime <= block.timestamp, "KnowBox:Box is not on time yet");
		require(SignatureChecker.verifyOpen(openInfo, DOMAIN_SEPARATOR), "KnowBox:Validate Sign Error");

		uint256 dataIndex = getRandomId(openInfo.salt);
		_boxInfo[openInfo.token].open = true;
		_boxInfo[openInfo.token].dataIndex = dataIndex;

		emit OpenNotice(msg.sender, openInfo.token, dataIndex);
	}

	function boxOpend(uint256 _tokenId) public view returns (bool) {
		require(_exists(_tokenId), "KnowBox: invalid token ID");
		return _boxInfo[_tokenId].open;
	}

	function _baseURI() internal view virtual override returns (string memory) {
		return baseURI;
	}

	function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
		if (boxOpend(_tokenId)) {
			string memory base = _baseURI();
			string memory dataIndex = _boxInfo[_tokenId].dataIndex.toString();
			return string(abi.encodePacked("ipfs://", base, "/", dataIndex, ".json"));
		} else {
			return nonOpenUri;
		}
	}

	function initBaseURI(string calldata baseURI_) external onlyOwner {
		require(!_isInit, "KnowBox: baseURI has inited");
		baseURI = baseURI_;
		_isInit = true;
	}

	function setMaxBalance(uint256 _maxBalance) external onlyOwner {
		maxBalance = _maxBalance;
	}

	function setOpenDelay(uint256 _openDelay) external onlyOwner {
		openDelay = _openDelay;
	}
}