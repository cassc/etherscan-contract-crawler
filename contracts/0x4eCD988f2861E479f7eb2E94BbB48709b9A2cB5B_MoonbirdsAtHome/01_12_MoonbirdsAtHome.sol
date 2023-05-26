/*

 _____ ______   ________  ________  ________   ________  ___  ________  ________  ________      
|\   _ \  _   \|\   __  \|\   __  \|\   ___  \|\   __  \|\  \|\   __  \|\   ___ \|\   ____\     
\ \  \\\__\ \  \ \  \|\  \ \  \|\  \ \  \\ \  \ \  \|\ /\ \  \ \  \|\  \ \  \_|\ \ \  \___|_    
 \ \  \\|__| \  \ \  \\\  \ \  \\\  \ \  \\ \  \ \   __  \ \  \ \   _  _\ \  \ \\ \ \_____  \   
  \ \  \    \ \  \ \  \\\  \ \  \\\  \ \  \\ \  \ \  \|\  \ \  \ \  \\  \\ \  \_\\ \|____|\  \  
   \ \__\    \ \__\ \_______\ \_______\ \__\\ \__\ \_______\ \__\ \__\\ _\\ \_______\____\_\  \ 
    \|__|     \|__|\|_______|\|_______|\|__| \|__|\|_______|\|__|\|__|\|__|\|_______|\_________\
                                                                                    \|_________|
                                                                                                
                                                                                                
 ________  _________                                                                            
|\   __  \|\___   ___\                                                                          
\ \  \|\  \|___ \  \_|                                                                          
 \ \   __  \   \ \  \                                                                           
  \ \  \ \  \   \ \  \                                                                          
   \ \__\ \__\   \ \__\                                                                         
    \|__|\|__|    \|__|                                                                         
                                                                                                
                                                                                                
                                                                                                
 ___  ___  ________  _____ ______   _______                                                     
|\  \|\  \|\   __  \|\   _ \  _   \|\  ___ \                                                    
\ \  \\\  \ \  \|\  \ \  \\\__\ \  \ \   __/|                                                   
 \ \   __  \ \  \\\  \ \  \\|__| \  \ \  \_|/__                                                 
  \ \  \ \  \ \  \\\  \ \  \    \ \  \ \  \_|\ \                                                
   \ \__\ \__\ \_______\ \__\    \ \__\ \_______\                                               
    \|__|\|__|\|_______|\|__|     \|__|\|_______|                                               
                                                              


Mom, can I have a Moonbird?
No honey, we have Moonbirds at home. 

Another CC0 project by nfttank.eth

*/                                                                                              


// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "./interfaces/OGStatsInterface.sol";

contract MoonbirdsAtHome is ERC721A, Ownable {
    using Strings for uint256;

    address private _ogStatsAddress = address(0);
    bool private _preSaleActive = false;
    bool private _publicSaleActive = false;

    string private _baseTokenURI;
    string public prerevealURL = 'ipfs://QmSvmQDAZp86N9zrq2cr2TUkaiWbA16HFDGv2xE5S5NFMM';
    bool private _addJson = true;

    uint256 private _birdPrice = 0.0169 ether;

    uint16 constant OG_WHALE_BALANCE = 10;
    uint16 constant MAX_BIRDS = 10000;

    mapping(address => uint) private _mintedPerAddress;
    
    constructor() ERC721A("Moonbirds At Home", "MAH") Ownable() { }

    function mint(uint16 quantity) public payable {

        require(_ogStatsAddress != address(0), "Contract is not active yet");
        require(_totalMinted() + quantity <= MAX_BIRDS, "Maximum amount of mints reached");

        address sender = _msgSender();
        
        if (sender != owner()) {

            require(quantity > 0 && quantity <= 50, "Minting is limited to max. 50 per wallet");
            require(balanceOf(sender) + quantity <= 50, "Minting is limited to max. 50 per wallet");
            
            MintInfo memory info = getMintInfo(sender, quantity);
            require(info.canMint, "Public sale is not open yet. Only OG holders can mint during pre-sale.");
            require(info.priceToPay <= msg.value, "Ether value sent is not correct");

            _mintedPerAddress[sender] += quantity;
        }

        _safeMint(sender, quantity);
    }

	function tokenURI(uint256 tokenId) public override view returns (string memory)
	{
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(_baseURI()).length > 0 
            ? string(abi.encodePacked(_baseURI(), tokenId.toString(), (_addJson ? ".json" : "")))
            : prerevealURL;
	}

    function getMintInfo(address buyer, uint16 quantity) public view returns (MintInfo memory) {

        uint16 freeMints = 0;

        Stats memory stats = getOgStats(buyer);

        bool hasOg = stats.balance >= 1;

        if (stats.ogDozen) {
            freeMints = 10;
        } else if (stats.meme) {
            freeMints = 5;
        } else if (stats.maxedOut || stats.balance >= OG_WHALE_BALANCE) {
            freeMints = 3;
        } else if (hasOg) {
            freeMints = 1;
        }

        uint16 quantityToPay = quantity;

        if(_mintedPerAddress[buyer] == 0) {
            if (freeMints < quantityToPay) {
                quantityToPay -= freeMints;
            }
            else {
                quantityToPay = 0;
            }
        }

        return MintInfo(
            /* undiscountedPrice */ _birdPrice * quantity,
            /* priceToPay */ _birdPrice * quantityToPay,
            /* canMint */ (hasOg && _preSaleActive) || _publicSaleActive,
            /* totalMints */ quantity,
            /* mintsToPay */ quantityToPay);
    }

    function getOgStats(address buyer) public view returns (Stats memory) {

        OGStatsInterface ogStats = OGStatsInterface(_ogStatsAddress);

        try ogStats.scan(buyer, OG_WHALE_BALANCE) returns (Stats memory stats) {
            return stats;
        }
        catch { }

        return Stats(0, false, false, false, false, new uint256[](0));
    }

	function _startTokenId() internal pure override returns (uint) {
		return 1;
	}

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function isPreSale() external view returns (bool) {
        return _preSaleActive;
    }

    function isPublicSale() external view returns (bool) {
        return _publicSaleActive;
    }

    function getBirdPrice() external view returns (uint256) {
        return _birdPrice;
    }

    function mintedCount(address addressToCheck) external view returns (uint) {
        return _mintedPerAddress[addressToCheck];
    }

    // --- owner stuff ---

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function shouldAddJson(bool value) external onlyOwner {
        _addJson = value;
    }

    function setStatsContract(address ogStatsAddress) external onlyOwner {
        _ogStatsAddress = ogStatsAddress;
    }

    function setPublicSale(bool publicSaleActive) external onlyOwner {
        _publicSaleActive = publicSaleActive;
    }

    function setPreSale(bool preSaleActive) external onlyOwner {
        _preSaleActive = preSaleActive;
    }

    function setBirdPrice(uint256 birdPrice) external onlyOwner {
        _birdPrice = birdPrice;
    }

	function airdrop(address to, uint16 quantity) external onlyOwner {
        require(_totalMinted() + quantity <= MAX_BIRDS, "Maximum amount of mints reached");
		_safeMint(to, quantity);
	}

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}

struct MintInfo {
    uint256 undiscountedPrice;
    uint256 priceToPay;
    bool canMint;
    uint16 totalMints;
    uint16 mintsToPay;
}