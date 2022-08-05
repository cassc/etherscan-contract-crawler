// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

// @creator: @carbone__music - carbonemusic.eth
// @title: C-Club
// @author: @devbhang - devbhang.eth
// @author: @hazelrah_nft - hazelrah.eth


/////////////////////////////////////////////////////////////////////
//                                                                 //
//     C-CLUB by Carbone                                           //
//                                                                 //
//      ____              ____     __       __  __  ____           //
//     /\  _`\           /\  _`\  /\ \     /\ \/\ \/\  _`\         //
//     \ \ \/\_\         \ \ \/\_\\ \ \    \ \ \ \ \ \ \L\ \       //
//      \ \ \/_/_  _______\ \ \/_/_\ \ \  __\ \ \ \ \ \  _ <'      //
//       \ \ \L\ \/\______\\ \ \L\ \\ \ \L\ \\ \ \_\ \ \ \L\ \     //
//        \ \____/\/______/ \ \____/ \ \____/ \ \_____\ \____/     //
//         \/___/            \/___/   \/___/   \/_____/\/___/      //
//                                                                 //
/////////////////////////////////////////////////////////////////////


import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract CClub is ERC721AQueryable, Ownable, ERC2981 {
	
	enum SaleStatus {
		NoSale,
		PreSale,
		PublicSale,
		SaleFinished
	}
	
	SaleStatus public saleStatus = SaleStatus.NoSale;
	
	address public treasuryAddress;
	
	string public baseURI;
	
	uint256 public publicPrice = 0.08 ether;
	uint256 public prePrice = 0.05 ether;
	
	uint256 public maxSupply = 199;
	
	bytes32 private _merkleRoot;
	
	constructor() ERC721A("C-Club", "CCLUB") {}
	
	function _startTokenId() internal view virtual override returns (uint256) {
		return 1;
	}
	
	function setRoyalty(address _address, uint96 _royalty) external onlyOwner {
		treasuryAddress = _address;
		_setDefaultRoyalty(_address, _royalty);
	}
	
	function setPrice(uint256 _publicPrice, uint256 _prePrice) external onlyOwner {
		publicPrice = _publicPrice;
		prePrice = _prePrice;
	}
	
	function getPrice() public view returns (uint256) {
		return saleStatus == SaleStatus.PreSale ? prePrice : publicPrice;
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
	
	function setSaleStatus(uint256 _saleStatus, bytes32 _root) external onlyOwner {
		saleStatus = SaleStatus(_saleStatus);
		_merkleRoot = _root;
	}
	
	function _claimToken(uint256 _amount) internal virtual {
		require(totalSupply() + (_amount * 2) < maxSupply, "MAX SUPPLY IS EXCEEDED");
		require(msg.value >= getPrice() * _amount, "NOT ENOUGH ETHERS SEND");
		
		_mint(msg.sender, _amount * 2);
	}
	
	function claimTokenPre(uint256 _amount, bytes32[] calldata _merkleProof) external payable {
		require(saleStatus == SaleStatus.PreSale, "PRE SALE IS NOT OPEN");
		require(MerkleProof.verify(_merkleProof, _merkleRoot, keccak256(abi.encodePacked(msg.sender))), "ADDRESS NOT WHITELISTED");
		
		_claimToken(_amount);
	}
	
	function claimTokenPublic(uint256 _amount) external payable {
		require(saleStatus == SaleStatus.PublicSale, "PUBLIC SALE IS NOT OPEN");
		
		_claimToken(_amount);
	}
	
	function airdrop(address[] calldata _to, uint256[] calldata _amount, uint256 _totalAmount) external onlyOwner {
		require(_to.length == _amount.length, "AMOUNT DATA LENGTH MUST MATCH ADDRESS DATA LENGTH");
		require(totalSupply() + (_totalAmount * 2) < maxSupply, "MAX SUPPLY IS EXCEEDED");
		
		for (uint i; i < _to.length; i++) {
			_mint(_to[i], _amount[i] * 2);
		}
	}
	
	function totalMinted(address _owner) external view returns (uint256) {
		return _numberMinted(_owner);
	}
	
	function withdraw() external onlyOwner {
		require(address(this).balance > 0, "INSUFFICIENT FUNDS");
		
		payable(treasuryAddress).transfer(address(this).balance);
	}
	
	function burn(uint256 _tokenId) external {
		require(saleStatus == SaleStatus.SaleFinished, "CAN'T BURN DURING SALE");
		
		_burn(_tokenId, true);
	}
}