// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Coliving is ERC721
 {
    
    // number of available rooms
    uint256 public immutable maxSupplyQueen = 17; 
    uint256 public immutable maxSupplyTwin = 6;

    function maxSupply() public pure returns (uint256) {
        return maxSupplyTwin + maxSupplyQueen;
    }

    uint256 public totalSupplyQueen = 1;
    uint256 public totalSupplyTwin = 1;

    function totalSupply() public view returns (uint256) {
        return totalSupplyQueen + totalSupplyTwin;
    }

    // hardcoded chainlink address
    address private immutable feed = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419; 

    // Rate and Price related functions
    function getRate() public view returns (uint256){
        return uint256(PriceFeed(feed).latestAnswer());
    }

    // prices in dollars
    uint256 public immutable priceQueenInUSD = 470 * 1e8;   // Price for Queen rooms
    uint256 public immutable priceTwinInUSD = 500 * 1e8;    // Price for Twin rooms

    // get Prices in ETH using current rate
    function getPriceQueen() public view returns (uint256) {
        return priceQueenInUSD * 1e18 / getRate() ; // returns price in wei
    }

    function getPriceTwin() public view returns (uint256) {
        return priceTwinInUSD * 1e18 / getRate() ; // returns price in wei
    }

    address private immutable owner;

    constructor() ERC721("Coliving by CNC", "Coliving") {
        owner = msg.sender;
        _safeMint(0xbd722F41bca276B05a27E0B716bdeC2cB801D952, 0); //hardcode first buyer
        _safeMint(0x4239187A55D9dbdCDAeF0d84e1F9470D919aB95B, 100); //hardcode second buyer
    }

    function tokenURI(uint256 tokenId) public pure override returns (string memory) {
        return 
            tokenId < 100   // different IPFS because different metadata
            ? "ipfs://QmQv5LhVdTSQtLe9QPbrkkHXwog2MkPEpqPLv7o9gcHwSe/" 
            : "ipfs://QmYpR5BC5okLk3djHXEEnsF6bZMoVvYpmPkPiLL1vCFNrj/"; // this is Twin room
    }

    function mintQueen(uint256 amount) external payable {
        require(totalSupplyQueen + amount <= maxSupplyQueen, "No Queen rooms left");
        require(priceQueenInUSD * 1e18 / getRate() * amount <= msg.value, "Inflation ser. Add more ETH");
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, totalSupplyQueen + i);
        }
        totalSupplyQueen += amount;
    }

    function mintTwin(uint256 amount) external payable {
        require(totalSupplyTwin + amount <= maxSupplyTwin, "No Twin rooms left");
        require(priceTwinInUSD * 1e18 / getRate() * amount <= msg.value, "Inflation ser. Add more ETH");
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, totalSupplyTwin + i + 100);
        }
        totalSupplyTwin += amount;
    }

    function withdrawAll() external {
        payable(owner).transfer(address(this).balance);
    }

}

abstract contract PriceFeed {
    function latestAnswer() virtual
        public
        view
        returns (int256 answer);
}