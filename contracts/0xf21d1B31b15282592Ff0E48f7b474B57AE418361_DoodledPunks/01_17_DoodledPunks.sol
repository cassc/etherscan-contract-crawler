// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721Enum.sol";

contract DoodledPunks is ERC721Enum, Ownable, PaymentSplitter, Pausable,  ReentrancyGuard {

	using Strings for uint256;
	string public baseURI;
	uint256 public cost = 0.1 ether;
	uint256 public maxSupply = 2500;
	uint256 public maxMint = 5;
	bool public status = false;

	address[] private addressList = [
	0xBA21fdeabefAFEd10393B1DD769E6102872c3245,
	0x02Fe0168167e16Fa458498fb0b6E5e14041988a8,
	0x026f6eF045c8E0F8210c97f6A870DB8697D0e9AF
	];
	uint[] private shareList = [30, 30, 30];	

	constructor() ERC721S("Doodled Punks", "DPunk") PaymentSplitter( addressList, shareList){
	    setBaseURI("");
	}

	function _baseURI() internal view virtual returns (string memory) {
	    return baseURI;
	}

	function mint(uint256 _mintAmount) public payable nonReentrant{
		uint256 s = totalSupply();
		require(status, "Contract Not Enabled" );
		require(_mintAmount > 0, "Cant mint 0" );
		require(_mintAmount <= maxMint, "Cant mint more then maxmint" );
		require(s + _mintAmount <= maxSupply, "Cant go over supply" );
		require(msg.value >= cost * _mintAmount);
		for (uint256 i = 0; i < _mintAmount; ++i) {
			_safeMint(msg.sender, s + i, "");
		}
		delete s;
	}

	function gift(uint[] calldata quantity, address[] calldata recipient) external onlyOwner{
		require(quantity.length == recipient.length, "Provide quantities and recipients" );
		uint totalQuantity = 0;
		uint256 s = totalSupply();
		for(uint i = 0; i < quantity.length; ++i){
			totalQuantity += quantity[i];
		}
		require( s + totalQuantity <= maxSupply, "Too many" );
		delete totalQuantity;
		for(uint i = 0; i < recipient.length; ++i){
			for(uint j = 0; j < quantity[i]; ++j){
			_safeMint( recipient[i], s++, "" );
			}
		}
		delete s;	
	}
	
	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
	    require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
	    string memory currentBaseURI = _baseURI();
	    return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
	}

	function setCost(uint256 _newCost) public onlyOwner {
	    cost = _newCost;
	}
	function setMaxMintAmount(uint256 _newMaxMintAmount) public onlyOwner {
	    maxMint = _newMaxMintAmount;
	}
	function setmaxSupply(uint256 _newMaxSupply) public onlyOwner {
	    maxSupply = _newMaxSupply;
	}
	function setBaseURI(string memory _newBaseURI) public onlyOwner {
	    baseURI = _newBaseURI;
	}
	function setSaleStatus(bool _status) public onlyOwner {
	    status = _status;
	}
	function withdraw() public payable onlyOwner {
	(bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
	require(success);
	}
	function withdrawSplit() public onlyOwner {
        for (uint256 sh = 0; sh < addressList.length; sh++) {
            address payable wallet = payable(addressList[sh]);
            release(wallet);
        }
    }
}