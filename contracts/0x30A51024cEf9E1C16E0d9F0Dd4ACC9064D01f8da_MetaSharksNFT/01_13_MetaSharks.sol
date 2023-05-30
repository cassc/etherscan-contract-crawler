// SPDX-License-Identifier: MIT
// Authored by NoahN ✌️

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MetaSharksNFT is ERC721Enumerable{
    using SafeMath for uint256;
    using Strings for uint256;
    
    bool public sharkPresale = false;
    bool public sharkSale = false;
    address public owner;
    address constant admin = 0xCAE2c859148340705fF10C8Ef362274fdE9c1835;
    address constant mintPassAddress = 0x723Ec7F26a31385E207b819fE233c51169576202;
    mapping(address => uint) public purchasedPasses;
    uint public mintSharkPrice = 50000000000000000; // 0.05 ETH
    string public baseTokenURI;
    mapping(uint => uint) public mintPassUses;
    
    uint public metaSharkNextId = 0;
    uint public constant metaSharkMaxSupply = 10045;
    
    constructor(string memory _baseTokenURI)  ERC721("MetaSharks", "MS"){
        owner = msg.sender;
        baseTokenURI = _baseTokenURI;
    }
    
    modifier onlyTeam {
        require(msg.sender == owner || msg.sender == admin, "You are not the owner.");
        _;
    }

    function presaleMintMetaShark(uint mintPassId, uint mintNum) external payable{
        require(mintNum < 11, "That's too many for one transaction!");
        require(metaSharkNextId + mintNum < metaSharkMaxSupply, "No more MetaSharks left!");
        require(sharkPresale, "Not time to buy a MetaShark!");
        require(msg.value == mintNum * mintSharkPrice, "Wrong amount of ether sent!");
        require(mintPassUses[mintPassId] + mintNum < 11, "That's too many for this pass!");
        require(IERC721(mintPassAddress).ownerOf(mintPassId) == msg.sender, "You don't own that MintPass!");

        mintPassUses[mintPassId] += mintNum;
        
		for (uint i = 0; i < mintNum; i++) {
			_safeMint(msg.sender, metaSharkNextId);
			metaSharkNextId++;
		}        
    }
    
    function mintMetaShark(uint mintNum) external payable{
        require(mintNum < 11, "That's too many for one transaction!");
        require(metaSharkNextId + mintNum < metaSharkMaxSupply, "No more MetaSharks left!");
        require(sharkSale, "Not time to buy a MetaShark!");
        require(msg.value == mintNum * mintSharkPrice, "Wrong amount of ether sent!");

        for (uint i = 0; i < mintNum; i++) {
			_safeMint(msg.sender, metaSharkNextId);
			metaSharkNextId++;
		}
    }
    
    function updateMintPrice(uint newPrice) external onlyTeam {
        mintSharkPrice = newPrice;
    }
    
	function giftMetaSharks(address[] memory recipients, uint[] memory quantity) external onlyTeam {
        require(recipients.length == quantity.length, "Data length mismatch!");
        uint totalMintRequested = 0;
        for(uint i = 0; i < quantity.length; i++) {
            totalMintRequested += quantity[i];
        }
        require((totalMintRequested + metaSharkNextId) < metaSharkMaxSupply, "Minting this many would exceed supply!");

        for(uint i = 0; i < recipients.length; i++) {
            for(uint j = 0; j < quantity[i]; j++){
                _safeMint(recipients[i], metaSharkNextId);
			    metaSharkNextId++;
            }
        }
	}
	
    function withdraw()  public onlyTeam {
        payable(admin).transfer(address(this).balance.div(15)); 
        payable(owner).transfer(address(this).balance); 
    }

    function setBaseURI(string memory baseURI) public onlyTeam {
        baseTokenURI = baseURI;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
            return string(abi.encodePacked(baseTokenURI, tokenId.toString(),".json"));        
    }
    
    function toggleSharkSale() public onlyTeam {
        sharkSale = !sharkSale;
    }
	
    function toggleSharkPresale() public onlyTeam {
        sharkPresale = !sharkPresale;
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable) returns (bool) {
        return ERC721Enumerable.supportsInterface(interfaceId);
    }
}