// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

//  ____    ______   __       ____    ____       
// /\  _`\ /\__  _\ /\ \     /\  _`\ /\  _`\     
// \ \ \L\ \/_/\ \/ \ \ \    \ \ \/\ \ \ \L\ \   
//  \ \  _ <' \ \ \  \ \ \  __\ \ \ \ \ \ ,  /   
//   \ \ \L\ \ \_\ \__\ \ \L\ \\ \ \_\ \ \ \\ \  
//    \ \____/ /\_____\\ \____/ \ \____/\ \_\ \_\
//     \/___/  \/_____/ \/___/   \/___/  \/_/\/ /                                            

// @jonathansnow x @tom_hirst

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract BildrHolderPass is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _nextTokenId;

    string private _baseTokenURI;

    uint256 public constant MAX_SUPPLY = 850;
    uint256 public constant MAX_PER_MINT = 5;
    uint256 public constant PRICE_WAVE_ONE =   0.08 ether;
    uint256 public constant PRICE_WAVE_TWO =   0.16 ether;
    uint256 public constant PRICE_WAVE_THREE = 0.24 ether;
    
    uint256 public numberAvailable;

    bool public saleIsActive;

    address r1 = 0xb6ba815DC649b7Db1Ed4dA400da9D76688ea8A54;
    address r2 = 0x3E7898c5851635D5212B07F0124a15a2d3C547EB;
    address r3 = 0x2C6B8C19dd7174F6e0cc56424210F19EeFe62f94;

    constructor() ERC721("BildrHolderPass", "BHDP") {
        _nextTokenId.increment();   // Start Token Ids at 1
        saleIsActive = false;       // Set sale to inactive
        numberAvailable = 100;      // Set initial number of available passes
    }

    // Function to handle minting passes
    function mint(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale is not active yet.");
        require(numberOfTokens > 0, "Quantity must be greater than 0.");
        require(numberOfTokens <= MAX_PER_MINT, "Exceeds max per mint.");
        require(totalSupply() + numberOfTokens <= numberAvailable, "Exceeds max available.");
        require(msg.value >= numberOfTokens * currentPrice(), "Wrong ETH value sent.");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, _nextTokenId.current());
            _nextTokenId.increment();
        }
    }

    // Function to determine the current price of a pass
    function currentPrice() public view returns (uint256) {
        uint256 totalMinted = totalSupply();
        if (totalMinted < 100) {
            return PRICE_WAVE_ONE;
        } else if (totalMinted < 350) {
            return PRICE_WAVE_TWO;
        } else {
            return PRICE_WAVE_THREE;
        }
    }

    // Function to return the number of passes available to mint
    function passesAvailable() public view returns (uint256) {
        return numberAvailable - totalSupply();
    }

    // Function to return the rnumber of passes remaining to mint
    function passesRemaining() public view returns (uint256) {
        return MAX_SUPPLY - totalSupply();
    }

    // Function to return how many passes have been minted
    function totalSupply() public view returns (uint256) {
        return _nextTokenId.current() - 1;
    }

    // Function to override the baseURI function
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // Function to set or update the baseURI
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    // Function to increase the number of passes available to mint
    function incrementAvailable() external onlyOwner {
        require(numberAvailable < MAX_SUPPLY, "Cannot increment further.");
        require(passesAvailable() == 0, "Please wait until current supply is sold");
    
        if (numberAvailable == 100) {
            numberAvailable = 350;
        } else if (numberAvailable == 350) {
            numberAvailable = 850;
        }
    }

    // Function to flip the sale on or off
    function toggleSale() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    // Function to withdraw ETH balance with splits
    function withdrawBalance() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(r1).transfer((balance * 950) / 1000);  // 95%   - Bildr
        payable(r2).transfer((balance * 25) / 1000);   // 2.5%  - Dev
        payable(r3).transfer((balance * 25) / 1000);   // 2.5%  - Dev
        payable(r1).transfer(address(this).balance); // Transfer remaining balance to treasury
    }

}