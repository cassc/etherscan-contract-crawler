// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Hats is ERC1155, Ownable {
	using Strings for string;

	mapping(uint256 => uint256) private _totalSupply;

	IERC1155 public gutterCatNFTAddress;
	IERC1155 public gutterRatNFTAddress;

	IERC721 public gutterPigeonNFTAddress;
	IERC721 public gutterDogNFTAddress;

	uint256 public burnedCounter;
	uint256 public totalMinted;

	mapping(uint256 => bool) private outOfStockForID;

	uint256 public btcHatPrice = 15000000000000000; //0.015 ETH
	uint256 public ethHatPrice = 15000000000000000; //0.015 ETH

	uint256 constant btcID = 1;
	uint256 constant ethID = 2;

	event CAction(uint256 petID, uint256 value, uint256 actionID, string payload);
	event Redeemed(address indexed from, uint256 id, uint256 uuid);

	string public _baseURI = "ipfs://xxx/";
	string public _contractURI = "ipfs://xxx";

	bool saleLive = false;
	bool burnLive = false;

	address payable public VAULT;

	constructor(
		address cats,
		address rats,
		address pigeons,
		address dogs
	) ERC1155(_baseURI) {
		gutterCatNFTAddress = IERC1155(cats); //0xEdB61f74B0d09B2558F1eeb79B247c1F363Ae452
		gutterRatNFTAddress = IERC1155(rats); //0xD7B397eDad16ca8111CA4A3B832d0a5E3ae2438C
		gutterPigeonNFTAddress = IERC721(pigeons); //0x950b9476a4de757BB134483029AC4Ec17E739e3A
		gutterDogNFTAddress = IERC721(dogs); //0x6e9da81ce622fb65abf6a8d8040e460ff2543add

		VAULT = payable(msg.sender);
	}

	function adminMint(
		address to,
		uint256 id,
		uint256 qty
	) public onlyOwner {
		require(qty > 0, "minimum 1 token");
		for (uint256 i = 0; i < qty; i++) {
			_mint(to, id, qty, "0x0000");
		}
	}

	function mintBTCHat(uint256 catId, uint256 qty) external payable {
		require(saleLive, "sale is not live");
		require(gutterCatNFTAddress.balanceOf(msg.sender, catId) > 0, "you have to own a cat");
		require(msg.value == btcHatPrice * qty, "insufficient ETH");
		require(outOfStockForID[btcID] == false, "item out of stock");
		require(qty <= 50, "only 50 can be minted at once");

		totalMinted = totalMinted + qty;
		_totalSupply[btcID] = _totalSupply[btcID] + qty;
		_mint(msg.sender, btcID, qty, "0x0000");
	}

	function mintETHHat(
		uint256 catId,
		uint256 ratId,
		uint256 qty
	) external payable {
		require(saleLive, "sale is not live");
		require(
			(gutterCatNFTAddress.balanceOf(msg.sender, catId) > 0) &&
				(gutterRatNFTAddress.balanceOf(msg.sender, ratId) > 0) &&
				gutterPigeonNFTAddress.balanceOf(msg.sender) > 0 &&
				gutterDogNFTAddress.balanceOf(msg.sender) > 0,
			"you have to own a full gutter set"
		);
		require(msg.value == ethHatPrice * qty, "insufficient ETH");
		require(outOfStockForID[ethID] == false, "item out of stock");
		require(qty <= 50, "only 50 can be minted at once");

		totalMinted = totalMinted + qty;
		_totalSupply[ethID] = _totalSupply[ethID] + qty;
		_mint(msg.sender, ethID, qty, "0x0000");
	}

	//redeem function
	function burn(
		address account,
		uint256 id,
		uint256 qty,
		uint256 uuid
	) public virtual {
		require(burnLive, "burn is not enabled");
		require(
			account == _msgSender() || isApprovedForAll(account, _msgSender()),
			"ERC1155: caller is not owner nor approved"
		);
		require(balanceOf(account, id) >= qty, "balance too low");

		burnedCounter = burnedCounter + qty;
		_burn(account, id, qty);
		emit Redeemed(account, id, uuid);
	}

	// to be used in the future
	function customAction(
		uint256 _nftID,
		uint256 _actionID,
		string memory payload
	) external payable {
		require(balanceOf(msg.sender, _nftID) > 0, "you must own this NFT");
		emit CAction(_nftID, msg.value, _actionID, payload);
	}

	function setBaseURI(string memory newuri) public onlyOwner {
		_baseURI = newuri;
	}

	function setContractURI(string memory newuri) public onlyOwner {
		_contractURI = newuri;
	}

	function uri(uint256 tokenId) public view override returns (string memory) {
		return string(abi.encodePacked(_baseURI, uint2str(tokenId)));
	}

	function contractURI() public view returns (string memory) {
		return _contractURI;
	}

	function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
		if (_i == 0) {
			return "0";
		}
		uint256 j = _i;
		uint256 len;
		while (j != 0) {
			len++;
			j /= 10;
		}
		bytes memory bstr = new bytes(len);
		uint256 k = len;
		while (_i != 0) {
			k = k - 1;
			uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
			bytes1 b1 = bytes1(temp);
			bstr[k] = b1;
			_i /= 10;
		}
		return string(bstr);
	}

	function totalSupply(uint256 id) public view virtual returns (uint256) {
		return _totalSupply[id];
	}

	function exists(uint256 id) public view virtual returns (bool) {
		return totalSupply(id) > 0;
	}

	// sets out of stock for an ID
	function setOutOfStockForID(uint256 _id, bool isOutOfStock) external onlyOwner {
		outOfStockForID[_id] = isOutOfStock;
	}

	// sets price for BTC hat
	function setBTCHatPrice(uint256 _newPrice) external onlyOwner {
		btcHatPrice = _newPrice;
	}

	// sets price for ETH hat
	function setETHHatPrice(uint256 _newPrice) external onlyOwner {
		ethHatPrice = _newPrice;
	}

	// enables sales
	function setSaleLive(bool _saleLive) external onlyOwner {
		saleLive = _saleLive;
	}

	// enables burn
	function setBurnLive(bool _burnLive) external onlyOwner {
		burnLive = _burnLive;
	}

	// reclaim accidentally sent tokens
	function reclaimERC20(IERC20 token) external onlyOwner {
		require(address(token) != address(0));
		uint256 balance = token.balanceOf(address(this));
		token.transfer(msg.sender, balance);
	}

	function reclaimERC1155(IERC1155 erc1155Token, uint256 id) public onlyOwner {
		erc1155Token.safeTransferFrom(address(this), msg.sender, id, 1, "");
	}

	function reclaimERC721(IERC721 erc721Token, uint256 id) public onlyOwner {
		erc721Token.safeTransferFrom(address(this), msg.sender, id);
	}

	// Set Vault address
	function setVaultAddress(address payable _vault) public onlyOwner {
		VAULT = _vault;
	}

	// withdraw earnings
	function withdrawToVault() public onlyOwner {
		VAULT.transfer(address(this).balance);
	}

	function withdrawToOwner() external onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}
}