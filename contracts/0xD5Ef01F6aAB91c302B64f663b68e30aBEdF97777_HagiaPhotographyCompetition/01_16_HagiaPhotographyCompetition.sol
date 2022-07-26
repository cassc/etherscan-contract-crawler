// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// @creator: HAGIA
// @title: Hagia Photography Competition
// @author: @devbhang - devbhang.eth
// @author: @hazelrah_nft - hazelrah.eth
// @author: @berkozdemir - berk.eth

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                     //
//                                                                                                     //
//   +-+ +-+ +-+ +-+ +-+   +-+   +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+                   //
//   |H| |A| |G| |I| |A|   |X|   |T| |Y| |L| |E| |R| |S| |J| |O| |U| |R| |N| |E| |Y|                   //
//   +-+ +-+ +-+ +-+ +-+   +-+   +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+                   //
//                                                                                                     //
//                                                                                                     //
//                                                                                                     //
//   +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+   +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+         //
//   |P| |H| |O| |T| |O| |G| |R| |A| |P| |H| |Y|   |C| |O| |M| |P| |E| |T| |I| |T| |I| |O| |N|         //
//   +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+   +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+         //
//   +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+   +-+ +-+ +-+ +-+ +-+   +-+ +-+ +-+ +-+ +-+ +-+ +-+   //
//   |A| |P| |P| |L| |I| |C| |A| |T| |I| |O| |N|   |W| |H| |E| |R| |E|   |B| |O| |R| |D| |E| |R| |S|   //
//   +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+   +-+ +-+ +-+ +-+ +-+   +-+ +-+ +-+ +-+ +-+ +-+ +-+   //
//   +-+ +-+ +-+ +-+   +-+ +-+   +-+ +-+ +-+ +-+ +-+ +-+                                               //
//   |M| |A| |K| |E|   |N| |O|   |S| |E| |N| |S| |E| |.|                                               //
//   +-+ +-+ +-+ +-+   +-+ +-+   +-+ +-+ +-+ +-+ +-+ +-+                                               //
//                                                                                                     //
//                                                                                                     //
//                                                                                                     //
//   +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+                                                                   //
//   |E| |S| |T| |:| |2| |0| |2| |2|                                                                   //
//   +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+                                                                   //
//                                                                                                     //
//                                                                                                     //
/////////////////////////////////////////////////////////////////////////////////////////////////////////


contract HagiaPhotographyCompetition is ERC721AQueryable, Ownable, ERC2981 {
	
	enum SaleStatus {
		NoSale,
		PublicSale,
		SaleFinished
	}
	
	SaleStatus saleStatus = SaleStatus.NoSale;
	
	string public baseURI;
	
	uint256 public price = 0.03 ether;
	
	address public treasuryAddress;
	
	constructor() ERC721A("HagiaPhotographyCompetition", "HAGIAPC") {}
	
	function setRoyalty(address _address, uint96 _royalty) external onlyOwner {
		treasuryAddress = _address;
		_setDefaultRoyalty(_address, _royalty);
	}
	
	function setPrice(uint256 _price) external onlyOwner {
		price = _price;
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
	
	function getSaleStatus() external view returns (SaleStatus) {
		return saleStatus;
	}
	
	function setSaleStatus(uint256 _saleStatus) external onlyOwner {
		saleStatus = SaleStatus(_saleStatus);
	}
	
	function claimToken(uint256 _amount) external payable {
		require(saleStatus == SaleStatus.PublicSale, "PUBLIC SALE IS NOT OPEN");
		require(msg.value >= price * _amount, "NOT ENOUGH ETHERS SEND");
		
		_mint(msg.sender, _amount);
	}
	
	function mintAdmin(address[] calldata _to, uint256[] calldata _amount) external onlyOwner {
		require(_to.length == _amount.length, "AMOUNT DATA LENGTH MUST MATCH ADDRESS DATA LENGTH");
		
		for (uint i; i < _to.length; i++) {
			_mint(_to[i], _amount[i]);
		}
	}
	
	function totalMinted(address _owner) external view returns (uint256) {
		return _numberMinted(_owner);
	}
	
	function withdraw() external onlyOwner {
		require(saleStatus == SaleStatus.SaleFinished, "CAN'T WITHDRAW DURING SALE");
		require(address(this).balance > 0, "INSUFFICIENT FUNDS");
		
		payable(treasuryAddress).transfer(address(this).balance);
	}
	
	function burn(uint256 _tokenId) external {
		require(saleStatus == SaleStatus.SaleFinished, "CAN'T BURN DURING SALE");
		
		_burn(_tokenId, true);
	}
	
}