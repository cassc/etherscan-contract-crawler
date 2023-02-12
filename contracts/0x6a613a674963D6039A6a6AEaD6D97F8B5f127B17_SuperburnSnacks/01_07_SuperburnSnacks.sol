/*

███████ ██    ██ ██████  ███████ ██████  ██████  ██    ██ ██████  ███    ██ 
██      ██    ██ ██   ██ ██      ██   ██ ██   ██ ██    ██ ██   ██ ████   ██ 
███████ ██    ██ ██████  █████   ██████  ██████  ██    ██ ██████  ██ ██  ██ 
     ██ ██    ██ ██      ██      ██   ██ ██   ██ ██    ██ ██   ██ ██  ██ ██ 
███████  ██████  ██      ███████ ██   ██ ██████   ██████  ██   ██ ██   ████ 
                                                                            
                                                                            
███████ ███    ██  █████   ██████ ██   ██ ███████                           
██      ████   ██ ██   ██ ██      ██  ██  ██                                
███████ ██ ██  ██ ███████ ██      █████   ███████                           
     ██ ██  ██ ██ ██   ██ ██      ██  ██       ██                           
███████ ██   ████ ██   ██  ██████ ██   ██ ███████                           

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./Art.sol";

contract SuperburnSnacks is ERC721A, Ownable {
    uint mintEndTime = 1676246400; // Monday, February 13th, 12am (00:00) UTC
    constructor() ERC721A("Superburn Snacks", "SNACKS") {}

    // starts the token number at 1 vs the default of 0
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // sets a variable price throughout mint
    // tokens 1 - 100 ~~~~~~~~~~ free
    // tokens 101 - 1000 ~~~~~~~ .001 eth
    // tokens 1001 - 5000 ~~~~~~ .005 eth
    // tokens 5000+ ~~~~~~~~~~~~ .01 eth
    function getPrice(uint quantity) public view returns(uint) {
        uint cost = 0;
        for (uint i = 0; i < quantity; i++) {
            if (i + _nextTokenId() > 100 && i + _nextTokenId() < 1001) {
                cost += 1000000000000000; // .001 eth
            } else if (i + _nextTokenId() > 1000 && i + _nextTokenId() < 5001) {
                cost += 5000000000000000; // .005 eth
            } else if (i + _nextTokenId() > 5000) {
                cost += 10000000000000000; // .01 eth
            }
        }
        return cost;
    }

    function mint(uint quantity) public payable {
        require(msg.value >= getPrice(quantity), 'not enough eth');
        require(quantity <= 20,'max 20 per tx');
        require(block.timestamp <= mintEndTime, 'mint is closed');
        _mint(msg.sender, quantity);
    }

    // gets the seconds until a block timestamp
    function secondsRemaining(uint end) public view returns (uint) {
        if (block.timestamp <= end) {
            return end - block.timestamp;
        } else {
            return 0;
        }
    }

    // gets the minutes until a block timestamp
    function minutesRemaining(uint end) public view returns (uint) {
        if (secondsRemaining(end) >= 60) {
            return (end - block.timestamp) / 60;
        } else {
            return 0;
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return art.metadata(tokenId);
    }

    function withdraw() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

}