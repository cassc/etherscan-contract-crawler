// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "./ERC721A.sol";

contract GutterJuice is Context, ERC721A, Ownable, ReentrancyGuard {
	using Strings for uint256;

	string private _contractBaseURI = "https://clonejuiceapi.guttercatgang.com/metadata/clone_juice/";
	string private _contractURI = "ipfs://QmRbAP27dFmPwk3ghgtqC542VRp869tqGFVy9tSqW6CKMv";

	address public cloneMintingContract; //the future clone contract

	// Public sale params
	uint256 public publicSaleDuration = 4 hours;
	uint256 public publicSaleStartTime = 1646774400;

    // Starting prices
	uint256 public publicSaleJuiceStartingPrice = 0.9 ether;
	uint256 public publicSaleJuiceStartingPriceGang = 100 ether;

	// auction not less than 0.1 ETH or 10 $GANG
	uint256 public auctionEndingPrice = 0.1 ether;
	uint256 public auctionEndingPriceGang = 10 ether;

	//flags for eth/gang sale
	bool public isETHSaleLive;
	bool public isGangSaleLive;

	address private airdropAccount;

	//gang tokens
	address public gangToken;

	//increased on the next juices
	uint256 public maxSupply = 16000;

	modifier notContract() {
		require(!_isContract(msg.sender), "Contract not allowed");
		require(msg.sender == tx.origin, "Proxy contract not allowed");
		_;
	}

	constructor() ERC721A("Gutter Juice", "JUICE") {
		airdropAccount = msg.sender;
	}

	/**
	 * @dev purchase a juice with ETH
	 * @param qty - quantity of items
	 */
	function buyJuice(uint256 qty) external payable notContract nonReentrant {
		require(block.timestamp >= publicSaleStartTime, "not started yet");
		require(isETHSaleLive, "not started yet - flag");
		require(qty <= 20, "max 20 at once");
		require(totalSupply() + qty <= maxSupply, "out of stock");

		uint256 costToMint = getMintPrice() * qty;
		require(msg.value >= costToMint, "eth value incorrect");

		_safeMint(msg.sender, qty);
		if (msg.value > costToMint) {
			(bool success, ) = msg.sender.call{ value: msg.value - costToMint }("");
			require(success, "Address: unable to send value, recipient may have reverted");
		}
	}

	/**
	 * @dev purchase a juice with Gang. correct allowance must be set
	 * @param qty - quantity of items
	 */
	function buyJuiceWithGang(uint256 qty) external notContract nonReentrant {
		require(block.timestamp >= publicSaleStartTime, "not started yet");
		require(isGangSaleLive, "not started yet - flag");
		require(qty <= 20, "max 20 at once");
		require(totalSupply() + qty <= maxSupply, "out of stock");

		uint256 costToMint = getMintPriceGang() * qty;

		//transfer the market fee
		require(
			IERC20(gangToken).transferFrom(msg.sender, address(this), costToMint),
			"failed transfer"
		);

		_safeMint(msg.sender, qty);
	}

	/**
	 * @dev don't go over 50...
	 */
	function airdrop(address[] memory receivers) external {
		require(tx.origin == airdropAccount || msg.sender == airdropAccount, "need airdrop account");
		for (uint256 i = 0; i < receivers.length; i++) {
			_safeMint(receivers[i], 1);
		}
	}

	/**
	 * @dev only calable from cloneMintingContract, verify ownership there
	 */
	function burn(uint256 tokenID) external {
		require(
			tx.origin == cloneMintingContract || msg.sender == cloneMintingContract,
			"only clone contract"
		);
		_burn(tokenID);
	}

	function getMintPrice() public view returns (uint256) {
		uint256 elapsed = getElapsedSaleTime();
		if (elapsed >= publicSaleDuration) {
			return auctionEndingPrice;
		} else {
			uint256 currentPrice = ((publicSaleDuration - elapsed) * publicSaleJuiceStartingPrice) /
				publicSaleDuration;
			return currentPrice > auctionEndingPrice ? currentPrice : auctionEndingPrice;
		}
	}

	function getMintPriceGang() public view returns (uint256) {
		uint256 elapsed = getElapsedSaleTime();
		if (elapsed >= publicSaleDuration) {
			return auctionEndingPriceGang;
		} else {
			uint256 currentPrice = ((publicSaleDuration - elapsed) * publicSaleJuiceStartingPriceGang) /
				publicSaleDuration;
			return currentPrice > auctionEndingPriceGang ? currentPrice : auctionEndingPriceGang;
		}
	}

	function getElapsedSaleTime() internal view returns (uint256) {
		return publicSaleStartTime > 0 ? block.timestamp - publicSaleStartTime : 0;
	}

	function contractURI() public view returns (string memory) {
		return _contractURI;
	}

	function exists(uint256 _tokenId) public view returns (bool) {
		return _exists(_tokenId);
	}

	function tokenURI(uint256 _tokenId) public view override returns (string memory) {
		require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
		return string(abi.encodePacked(_contractBaseURI, _tokenId.toString()));
	}

	/** ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	 *  ~~~~~~~~~ ADMIN FUNCTIONS ~~~~~~~~~
	 *  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	 */

	/**
	@dev sets the contract address for gang token
	 */
	function setGangTokenAddress(address cAddress) external onlyOwner {
		gangToken = cAddress;
	}

	function adminMint(uint256 qty, address to) external onlyOwner {
		require(totalSupply() + qty <= maxSupply, "out of stock");
		_safeMint(to, qty);
	}

	function withdrawEarnings() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

	/**
	@dev setup the public sale
	* @param saleDuration - duration of the sale
	* @param saleStartPrice - price of the sale
	 */
	function startPublicSale(
		uint256 saleDuration,
		uint256 saleStartPrice,
		uint256 saleStartPriceGang
	) external onlyOwner {
		publicSaleDuration = saleDuration;
		publicSaleJuiceStartingPrice = saleStartPrice;
		publicSaleJuiceStartingPriceGang = saleStartPriceGang;
		publicSaleStartTime = block.timestamp;
	}

	/**
	@dev setup the public sale
	* @param inETH - for eth sales
	* @param inGang - for gang sales
	 */
	function setEndingPrices(uint256 inETH, uint256 inGang) external onlyOwner {
		auctionEndingPrice = inETH;
		auctionEndingPriceGang = inGang;
	}

	/**
	@dev sets a new base URI
	* @param newBaseURI - new base URI
	 */
	function setBaseURI(string memory newBaseURI) external onlyOwner {
		_contractBaseURI = newBaseURI;
	}

	function setContractURI(string memory newuri) external onlyOwner {
		_contractURI = newuri;
	}

	//sets the account that does the airdrop
	function setAirdropAccount(address newAddress) external onlyOwner {
		airdropAccount = newAddress;
	}

	//can be increased by admin for the next drops
	function setMaxSupply(uint256 newMaxSupply) external onlyOwner {
		maxSupply = newMaxSupply;
	}

	/**
	@dev sets the clone minting contract
	* @param addr - address of the contract
	 */
	function setCloneMintingContract(address addr) external onlyOwner {
		cloneMintingContract = addr;
	}

	/**
	 * @dev sets the flags for eth/gang sales
	 */
	function enableSales(bool enableETH, bool enableGang) external onlyOwner {
		isETHSaleLive = enableETH;
		isGangSaleLive = enableGang;
	}

	/**
	@dev gets a token back + market fees
	 */
	function reclaimERC20(address _tokenContract, uint256 _amount) external onlyOwner {
		require(IERC20(_tokenContract).transfer(msg.sender, _amount), "transfer failed");
	}

	/**
	@dev gets back an ERC721 token
	 */
	function reclaimERC721(IERC721 erc721Token, uint256 id) external onlyOwner {
		erc721Token.safeTransferFrom(address(this), msg.sender, id);
	}

	/**
	@dev gets back an ERC1155 token(s)
	 */
	function reclaimERC1155(
		IERC1155 erc1155Token,
		uint256 id,
		uint256 amount
	) external onlyOwner {
		erc1155Token.safeTransferFrom(address(this), msg.sender, id, amount, "");
	}

	/**
	 * @notice Check if an address is a contract
	 */
	function _isContract(address _addr) internal view returns (bool) {
		uint256 size;
		assembly {
			size := extcodesize(_addr)
		}
		return size > 0;
	}
}