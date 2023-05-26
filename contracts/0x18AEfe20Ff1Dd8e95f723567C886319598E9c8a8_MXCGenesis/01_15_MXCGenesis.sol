// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

// @creator: METACOLLECTIVE aka MXC
// @title: MXC : GENESIS
// @author: @berkozdemir - berk aka PrincessCamel
// @author: @devbhang - bhang
// @author: @hazelrah_nft - hazelrah

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                    //
//                                        /\    /\      |@@@@@@@@ @@@@@@@@@     /\                                                                    //
//        /METAMETAMETA/    /METAX/      /@@\  /@@\     |@@         |%@|       /@@\                                                                   //
//       /METAMETAMETA/    /METAX/      /@@@&\/@@@@\    |@@@@@@@@   |%@|      /@@@@\                                                                  //
//              /META/    /METAX/      /@@%@*@/ \@@@\   |@@@@@@@@   |%@|     /@@  @@\                                                                 //
//             /META/    /METAX/      /@@@@/\/   \@@@\  |@@         |%@|    /@@@@@@@@\                                                                //
//       /METAMETAMETAMETAMETAMET/   /@@@@/       \@@@\ |@@@@@@@@   |%@|   /@@/    \@@\                                                               //
//      /META/METAMETAMETAMETAME/                                                                                                                     //
//     /META//METAMETAMETAMETAM/        /@@@@@\    /@@@@@@\     |@@|      |@@|      |@@@@@@|   /@@@@@@\   |@@@@@@@@|  |@@| \@@\    /@@/ |@@@@@@@|     //
//         /META/    /META/            /@@/  @@\  /@@/  \@@\   |@@|      |@@|      |@@|       /@@/  \@@\     |@@|           \@@\  /@@/  |@@|          //
//        /META/    /META/            (@@@        @@      @@  |@@|      |@@|      |@@@@@|    |@@|            |@@|     |@@|   \@@\/@@/   |@@@@@|       //
//       /META/    /METAMETAMETA/      \@@\ /@@/  \@@\  /@@/   |@@|      |@@|      |@@|       \@@\   /@@/    |@@|     |@@|    \@@@@/    |@@|          //
//      /META/    /METAMETAMETA/        \@@@@@/    \@@@@@@/     |@@@@@@|  |@@@@@@|  |@@@@@@|   \@@@@@@@/     |@@|     |@@|     \@@/     |@@@@@@@|     //
//                                                                                                                                                    //
//                                                                                                                                                    //
//        @@@@@@@       @@@@@@@            /@@@@@\       |@@@@@@@@@@\   |@@@@@@@@@@@@| |@@@@|    /@@@@@@@@\   |@@@@@@@@@@@@   /@@@@@@@@\              //
//      @@@@@/@@@@@   @@@@@@@@@@@         /@@@@@@@\      |@@@@@@@@@@@\  |@@@@@@@@@@@@| |@@@@|   /@@@@@@@@@@\  |@@@@@@@@@@@@  /@@@@@@@@@@\             //
//      @@@@   @@@@  @@@@     @@@@       /@@@/ \@@@\     |@@@|    @@@@|     |@@@@|     |@@@@|   |@@@@@            |@@@@      |@@@@@                   //
//       @@@@@@@@   @@@@       @@@@     /@@@/   \@@@\    |@@@@@@@@@@@/      |@@@@|     |@@@@|        @@@@@@\      |@@@@           @@@@@@\             //
//     @@@@@   @@@@@ @@@@     @@@@     /@@@@@@@@@@@@@\   |@@@@%@@@@|        |@@@@|     |@@@@|   /@/   |@@@@@\     |@@@@      /@/   |@@@@@\            //
//      @@@@@@@@@@@   @@@@@@@@@@@     /@@@/       \@@@\  |@@@|  \@@@@\      |@@@@|     |@@@@|  |@@@@@@@@@@@@|     |@@@@     |@@@@@@@@@@@@|            //
//        @@@@@@@       @@@@@@       /@@@/         \@@@\ |@@@|   \@@@@\     |@@@@|     |@@@@|   \@@@@@@@@@/       |@@@@      \@@@@@@@@@/              //
//                                                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract MXCGenesis is ERC721AQueryable, Ownable, ERC2981 {

	enum SaleStatus {
		NoSale,
		PrivateSale,
		PreSale,
		PublicSale,
		SaleFinished
	}
	
	SaleStatus saleStatus = SaleStatus.NoSale;
	
	string public baseURI;

	uint256 public constant MAX_MINT_PRIVATE = 81;
	uint256 public constant MAX_MINT_PRE = 41;
	uint256 public constant MAX_MINT_PUBLIC = 21;
	
	uint256 public price = 0.05 ether;
	
	uint256 public maxSupply = 1601;
	
	address public treasuryAddress;
	
	bytes32 private _merkleRoot;
	
	constructor() ERC721A("MXC Genesis", "MXCGNS") {}
	
	function addCreators(address[] calldata _creators) external onlyOwner {
		require(creators.length + _creators.length < MAX_MINT_PRIVATE, "TOO MANY CREATORS");
		
		for (uint i; i < _creators.length; i++) {
			creators.push(_creators[i]);
		}
	}
	
	function setRoyalty(address _address, uint96 _royalty) external onlyOwner {
		treasuryAddress = _address;
		_setDefaultRoyalty(_address, _royalty);
	}
	
	function setPrice(uint _price) external onlyOwner {
		price = _price;
	}
	
	function editMaxSupply(uint _maxSupply) external onlyOwner {
		require(_maxSupply < maxSupply, "MAX SUPPLY CAN'T EXCEED INITIAL SUPPLY");
		
		maxSupply = _maxSupply;
	}

	function setBaseURI(string calldata _newBaseURI) external onlyOwner {
		baseURI = _newBaseURI;
	}
	
	function _baseURI() internal view virtual override returns (string memory) {
		return baseURI;
	}
	
	function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
		return super.supportsInterface(interfaceId);
	}
	
	// SALE
	
	function getSaleStatus() public view returns (SaleStatus) {
		return saleStatus;
	}
	
	function setSaleStatus(uint256 _saleStatus, bytes32 _root) external onlyOwner {
		saleStatus = SaleStatus(_saleStatus);
		_merkleRoot = _root;
	}
	
	function _claimToken(uint _amount, uint _maxMint) internal virtual {
		require(tx.origin == msg.sender, "ONLY HUMANS ALLOWED");
		require(_amount < _maxMint, "MAX MINT PER TX IS EXCEEDED");
		require(_numberMinted(msg.sender) + _amount < MAX_MINT_PRIVATE, "MAX MINT PER WALLET IS EXCEEDED");
		require(totalSupply() + _amount < maxSupply, "MAX SUPPLY IS EXCEEDED");
		require(msg.value >= price * _amount, "NOT ENOUGH ETHERS SEND");
		
		_mint(msg.sender, _amount);
	}
	
	function claimTokenPrivate(uint _amount, bytes32[] calldata _merkleProof) external payable {
		require(saleStatus == SaleStatus.PrivateSale || saleStatus == SaleStatus.PreSale, "SALE IS NOT OPEN");
		require(MerkleProof.verify(_merkleProof, _merkleRoot, keccak256(abi.encodePacked(msg.sender))), "ADDRESS NOT WHITELISTED");
		
		uint _maxMint = saleStatus == SaleStatus.PrivateSale ? MAX_MINT_PRIVATE : MAX_MINT_PRE;
		
		_claimToken(_amount, _maxMint);
	}
	
	function claimTokenPublic(uint _amount) external payable {
		require(saleStatus == SaleStatus.PublicSale, "PUBLIC SALE IS NOT OPEN");
		
		_claimToken(_amount, MAX_MINT_PUBLIC);
	}
	
	function mintAdmin(address[] calldata _to, uint _amount) public onlyOwner {
		require(saleStatus == SaleStatus.SaleFinished, "CAN'T MINT DURING SALE");
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