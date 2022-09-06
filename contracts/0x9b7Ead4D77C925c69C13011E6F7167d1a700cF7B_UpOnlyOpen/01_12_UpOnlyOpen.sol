// SPDX-License-Identifier: MIT 
pragma solidity 0.8.9;

//                                                                                                                   
//                                                                                                                   
// UUUUUUUU     UUUUUUUU                             OOOOOOOOO                       lllllll                         
// U::::::U     U::::::U                           OO:::::::::OO                     l:::::l                         
// U::::::U     U::::::U                         OO:::::::::::::OO                   l:::::l                         
// UU:::::U     U:::::UU                        O:::::::OOO:::::::O                  l:::::l                         
//  U:::::U     U:::::Uppppp   ppppppppp        O::::::O   O::::::Onnnn  nnnnnnnn     l::::lyyyyyyy           yyyyyyy
//  U:::::D     D:::::Up::::ppp:::::::::p       O:::::O     O:::::On:::nn::::::::nn   l::::l y:::::y         y:::::y 
//  U:::::D     D:::::Up:::::::::::::::::p      O:::::O     O:::::On::::::::::::::nn  l::::l  y:::::y       y:::::y  
//  U:::::D     D:::::Upp::::::ppppp::::::p     O:::::O     O:::::Onn:::::::::::::::n l::::l   y:::::y     y:::::y   
//  U:::::D     D:::::U p:::::p     p:::::p     O:::::O     O:::::O  n:::::nnnn:::::n l::::l    y:::::y   y:::::y    
//  U:::::D     D:::::U p:::::p     p:::::p     O:::::O     O:::::O  n::::n    n::::n l::::l     y:::::y y:::::y     
//  U:::::D     D:::::U p:::::p     p:::::p     O:::::O     O:::::O  n::::n    n::::n l::::l      y:::::y:::::y      
//  U::::::U   U::::::U p:::::p    p::::::p     O::::::O   O::::::O  n::::n    n::::n l::::l       y:::::::::y       
//  U:::::::UUU:::::::U p:::::ppppp:::::::p     O:::::::OOO:::::::O  n::::n    n::::nl::::::l       y:::::::y        
//   UU:::::::::::::UU  p::::::::::::::::p       OO:::::::::::::OO   n::::n    n::::nl::::::l        y:::::y         
//     UU:::::::::UU    p::::::::::::::pp          OO:::::::::OO     n::::n    n::::nl::::::l       y:::::y          
//       UUUUUUUUU      p::::::pppppppp              OOOOOOOOO       nnnnnn    nnnnnnllllllll      y:::::y           
//                      p:::::p                                                                   y:::::y            
//                      p:::::p                                                                  y:::::y             
//                     p:::::::p                                                                y:::::y              
//                     p:::::::p                                                               y:::::y               
//                     p:::::::p                                                              yyyyyyy                
//                     ppppppppp                                                                                     
//                                                                                                                   

// @truedrewco

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract UpOnlyOpen is ERC721, Ownable {


    using Counters for Counters.Counter;
    Counters.Counter private _nextTokenId;

    string private _baseTokenURI;
    bool public saleIsActive;


    uint256 public MAX_PER_MINT = 1;
    uint256 public MINT_PRICE = .01 ether;


    address r1 = 0xb333449fd966227cF3Af0FfD3aAF9d4Ff6F7C3e4;


    constructor() ERC721("UpOnlyOpen", "UOO") {
        _nextTokenId.increment();   // Start Token Ids at 1
        saleIsActive = false;       // Set sale to inactive
    }


    // standard mint
    function mint(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale is not active.");
        require(numberOfTokens > 0, "Quantity must be greater than 0.");
        require(numberOfTokens <= MAX_PER_MINT, "Exceeds max per mint.");
        require(msg.value >= numberOfTokens * currentPrice(), "Requires more eth.");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, _nextTokenId.current());
            _nextTokenId.increment();
            MINT_PRICE += _nextTokenId.current() * .005 ether;
        }
    }

    // airdrop mint
    function airdropMint(uint256 numberOfTokens, address recipient) external onlyOwner payable {
        // require(saleIsActive, "Sale is not active."); // owner can airdrop mint even if sale is off... uncomment to restrict airdrop mints
        require(numberOfTokens > 0, "Quantity must be greater than 0.");
        require(numberOfTokens <= MAX_PER_MINT, "Exceeds max per mint.");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(recipient, _nextTokenId.current());
            _nextTokenId.increment();
            MINT_PRICE += _nextTokenId.current() * .005 ether;
        }
    }

    // set current price
    function setCurrentPrice(uint256 _price) external onlyOwner {
        MINT_PRICE = _price;
    }

    // return current price
    function currentPrice() public view returns (uint256) {
        return MINT_PRICE;
    }

    // set max per mint
    function setMaxPerMint(uint256 _maxPerMint) external onlyOwner {
        MAX_PER_MINT = _maxPerMint;
    }

    // return max per mint
    function maxPerMint() public view returns (uint256) {
        return MAX_PER_MINT;
    }


    // return how many tokens have been minted
    function totalSupply() public view returns (uint256) {
        return _nextTokenId.current() - 1;
    }

    // override the baseURI function
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // set or update the baseURI
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    // toggle sale on or off
    function toggleSale() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    // withdraw ETH balance
    function withdrawBalance() public onlyOwner {
        payable(r1).transfer(address(this).balance);   // Transfer remaining balance to r1 from top of contract
    }

}