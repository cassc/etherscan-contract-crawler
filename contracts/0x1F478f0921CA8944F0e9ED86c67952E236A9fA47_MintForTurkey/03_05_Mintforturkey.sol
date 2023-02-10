// SPDX-License-Identifier: MIT
/*  


          @                                                                                           
      &%%%%%%%&                         @%%%@@@@@%%                                     @@            
      @%%%%%%%%%@                  %%%%%%%%%%%%%%%%%%%%%                         @%%%%%%%%%%%         
     &%%%%%&@%@(%%%@%%%@@@%/   @%%%%%%%%%%%%%%%%%%%%%%%%%%%%@@         @%@   *%%%%%%%%%%%%%%%%%       
       @&@           @@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
    &%%%%%%%%%%%%%@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@  
   @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
    @@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@  
  @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
       @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@%%%
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@ @            
           @@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%&                        
               @ %%%%%%%%     @%%%%%%%%%%%%%%%@ @%%%@*  %%  @%%@                                      
                  @%%%@@/         %%%%%%%%%%         @%%%%                                            
                                    @                 @%@                                             
                                             (@                                                       
                                     %%%%%&                                                                                     
                                          

        ___  ________ _   _ _____  ______ ___________   _____ _   _______ _   __ _______   __
       |  \/  |_   _| \ | |_   _| |  ___|  _  | ___ \ |_   _| | | | ___ \ | / /|  ___\ \ / /
       | .  . | | | |  \| | | |   | |_  | | | | |_/ /   | | | | | | |_/ / |/ / | |__  \ V / 
       | |\/| | | | | . ` | | |   |  _| | | | |    /    | | | | | |    /|    \ |  __|  \ /  
       | |  | |_| |_| |\  | | |   | |   \ \_/ / |\ \    | | | |_| | |\ \| |\  \| |___  | |  
       \_|  |_/\___/\_| \_/ \_/   \_|    \___/\_| \_|   \_/  \___/\_| \_\_| \_/\____/  \_/ 



*/
pragma solidity ^0.8.4 ;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol" ;


contract MintForTurkey is ERC721A, Ownable {

// Contract Variables

uint256 public mintPrice = 0.006 ether ;
bool    public saleStatus;
bool    public isRevealed;

string  public baseTokenUrl = "ipfs://QmWQ7Uzefu8AXxaPNDfUKm4rLLn7N5CLfzmwRXszZuCA9E/";
string  public tokenUrlSuffix = ".json";
uint256 public mintEndDate = 1676383200; // According to the tweet of Haluk Levent, after 1 week donation address will expire
// NFT contract includes a function to change mintEndDate which can be used if the donation address will last longer


// Donation address of "Ahbap" NGO 

// Ethereum
address constant donationAddress   = 0xe1935271D1993434A1a59fE08f24891Dc5F398Cd ;
// Binance Smart Chain
// 0xB67705398fEd380a1CE02e77095fed64f8aCe463
// Avax
// 0x868D27c361682462536DfE361f2e20B3A6f4dDD8


constructor () ERC721A( "MintForTurkey" , "TURKEY") { }

// Mint


function publicMint (uint256 amount_) public payable mintRequirements(amount_) {
_withdraw(donationAddress , msg.value) ;
_safeMint(msg.sender, amount_);

}


// Owner Functions


function withdraw() external onlyOwner { // In case of somehow balance appears on the contract

uint256 balance = address(this).balance ;
require (balance > 0 , "Zero balance, can not withdraw") ;

_withdraw(donationAddress, (balance) ) ;

}

function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");   
        }


// Variable Changers
function setMintPrice (uint256 mintPrice_) external onlyOwner {
mintPrice = mintPrice_ ;
}

function setSaleStatus (bool saleStatus_) external onlyOwner {
    saleStatus = saleStatus_ ;
}

function setBaseTokenUrl(string memory _baseTokenUrl) public onlyOwner {
    baseTokenUrl = _baseTokenUrl;
  }

function setTokenUrlSuffix(string memory _tokenUrlSuffix) public onlyOwner {
    tokenUrlSuffix = _tokenUrlSuffix;
  }

function setMintEndDate(uint256 _mintEndDate) public onlyOwner {
    mintEndDate = _mintEndDate;
  }


function reveal(bool _isRevealed) external onlyOwner {

isRevealed = _isRevealed ;
  }


// View Functions

  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenUrl;
  }

  function _suffix() internal view virtual returns (string memory) {
    return tokenUrlSuffix;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
  {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

    string memory baseURI = _baseURI();
    string memory suffix = _suffix();
    string memory metadataId = isRevealed ? _toString(tokenId) : 'unrevealed'; 
    return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, metadataId, suffix)): "";
  
  }


// Modifiers

modifier mintRequirements (uint256 _amount) {
    require(_amount > 0 , "Mint amount can not be 0");
    require(saleStatus == true , "Public mint is inactive");
    require(msg.value >= _amount  * mintPrice , "Insufficient ETH");
    require(block.timestamp <= mintEndDate , "Wallet address is expired, mint has ended.");
    _;
    }


}