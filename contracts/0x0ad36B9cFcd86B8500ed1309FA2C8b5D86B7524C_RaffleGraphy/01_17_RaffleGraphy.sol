// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

// @creator: HAGIA x TylersJourney
// @title: RaffleGraphy
// @author: @devbhang - devbhang.eth
// @author: @hazelrah_nft - hazelrah.eth
// @advisor: @berkozdemir - berk.eth

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

////////////////////////////////////////////////////////////////////////////////////////
//                                                                                    //
//                                                                                    //
//   +-+ +-+ +-+ +-+ +-+   +-+   +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+  //
//   |H| |A| |G| |I| |A|   |X|   |T| |Y| |L| |E| |R| |S| |J| |O| |U| |R| |N| |E| |Y|  //
//   +-+ +-+ +-+ +-+ +-+   +-+   +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+  //
//                                                                                    //
//                                                                                    //
//   +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+                                  //
//   |R| |A| |F| |F| |L| |E| |G| |R| |A| |P| |H| |Y|                                  //
//   +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+                                  //
//                                                                                    //
//                                                                                    //
//   +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+                                                  //
//   |E| |S| |T| |:| |2| |0| |2| |2|                                                  //
//   +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+                                                  //
//                                                                                    //
//                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////

contract RaffleGraphy is ERC721AQueryable, Ownable, ERC2981 {
	
	enum SaleStatus {
		NoSale,
		PreSale,
		PublicSale,
		SaleFinished
	}
	
	SaleStatus saleStatus = SaleStatus.NoSale;
	
	string public baseURI;
	
	uint256 public constant MAX_MINT_PRE = 11;
	uint256 public constant MAX_MINT_PUBLIC = 51;
	
	uint256 public price = 0.1 ether;
	
	uint256 public maxSupply = 501;

	address public treasuryAddress;
	
	bytes32 private _merkleRoot;
	
	constructor() ERC721A("RaffleGraphy", "RFLGRPHY") {}
	
	function setRoyalty(address _address, uint96 _royalty) external onlyOwner {
		treasuryAddress = _address;
		_setDefaultRoyalty(_address, _royalty);
	}
	
	function setPrice(uint256 _price) external onlyOwner {
		price = _price;
	}
	
	function editMaxSupply(uint256 _maxSupply) external onlyOwner {
		require(_maxSupply < maxSupply, "MAX SUPPLY CAN'T EXCEED INITIAL SUPPLY");
		
		maxSupply = _maxSupply;
	}

	function _startTokenId() internal view virtual override returns (uint256) {
		return 1;
	}
	
	function setBaseURI(string calldata _newBaseURI) external onlyOwner {
		baseURI = _newBaseURI;
	}
	
	function _baseURI() internal view virtual override returns (string memory) {
		return baseURI;
	}
	
	function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981, IERC165) returns (bool) {
		return super.supportsInterface(interfaceId);
	}
	
	function getSaleStatus() public view returns (SaleStatus) {
		return saleStatus;
	}
	
	function setSaleStatus(uint256 _saleStatus, bytes32 _root) external onlyOwner {
		saleStatus = SaleStatus(_saleStatus);
		_merkleRoot = _root;
	}
	
	function _claimToken(uint256 _amount, uint256 _maxMint) internal virtual {
		require(_numberMinted(msg.sender) + _amount < _maxMint, "MAX MINT PER WALLET IS EXCEEDED");
		require(totalSupply() + _amount < maxSupply, "MAX SUPPLY IS EXCEEDED");
		require(msg.value >= price * _amount, "NOT ENOUGH ETHERS SEND");
		
		_mint(msg.sender, _amount);
	}
	
	function claimTokenPre(uint256 _amount, bytes32[] calldata _merkleProof) external payable {
		require(saleStatus == SaleStatus.PreSale, "PRE SALE IS NOT OPEN");
		require(MerkleProof.verify(_merkleProof, _merkleRoot, keccak256(abi.encodePacked(msg.sender))), "ADDRESS NOT WHITELISTED");
		
		_claimToken(_amount, MAX_MINT_PRE);
	}
	
	function claimTokenPublic(uint256 _amount) external payable {
		require(saleStatus == SaleStatus.PublicSale, "PUBLIC SALE IS NOT OPEN");
		
		_claimToken(_amount, MAX_MINT_PUBLIC);
	}
	
	function claimAdmin(address[] calldata _to, uint256 _amount) external onlyOwner {
		require(totalSupply() + (_amount * _to.length) < maxSupply, "MAX SUPPLY IS EXCEEDED");
		
		for (uint i; i < _to.length; i++) {
			_mint(_to[i], _amount);
		}
	}
	
	function withdraw() external onlyOwner {
		require(saleStatus == SaleStatus.SaleFinished, "CAN'T WITHDRAW DURING SALE");
		require(address(this).balance > 0, "INSUFFICIENT FUNDS");
		
		payable(treasuryAddress).transfer(address(this).balance);
	}
	
	function burn(uint256 _tokenId) public {
		require(saleStatus == SaleStatus.SaleFinished, "CAN'T BURN DURING SALE");
		
		_burn(_tokenId, true);
	}
	
}