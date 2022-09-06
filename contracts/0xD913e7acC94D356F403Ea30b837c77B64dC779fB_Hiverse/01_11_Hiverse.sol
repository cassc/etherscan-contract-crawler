//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
/*
  _    _  _____ __      __ ______  _____    _____  ______ 
 | |  | ||_   _|\ \    / /|  ____||  __ \  / ____||  ____|
 | |__| |  | |   \ \  / / | |__   | |__) || (___  | |__   
 |  __  |  | |    \ \/ /  |  __|  |  _  /  \___ \ |  __|  
 | |  | | _| |_    \  /   | |____ | | \ \  ____) || |____ 
 |_|  |_||_____|    \/    |______||_|  \_\|_____/ |______|
                                                          
*/

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Hiverse is ERC721, Ownable {
    uint256[] public ticketId = [0, 150, 250, 300];
    uint256[] public limitId = [149, 249, 299, 332];
    uint256 public _tokenPrice;
    uint8 public mintStatus = 0;
    mapping(address => bool) public notoriousMembers;
    mapping(address => uint256) public amountPerUser;
    mapping(uint256 => mapping(address => bool)) whitelistMember;
    string public baseTokenURI;

    constructor(string memory baseURI, uint256 tokenPrice) ERC721("HIVERSE TICKETS", "HTCK"){
        setBaseURI(baseURI);
        _tokenPrice = tokenPrice;
    }

    function mintTicket(uint256 amount, uint256 ticketType) public payable {
        require(mintStatus == 1 || mintStatus == 2, "Sale is not active Yet.");
        require(ticketId[ticketType] + amount - 1 <= limitId[ticketType], "Sold Out.");
        if(mintStatus == 1) {
          require(ticketType == 0 || ticketType == 1 || ticketType == 2 || ticketType == 3, "Invalid Ticket Type!");
          require(whitelistMember[ticketType][msg.sender] == true, "Not Allowed Mint.");
          if(notoriousMembers[msg.sender] == true) {
            require(amount + amountPerUser[msg.sender] <= 2, "Exceed Mintable Amount.");
          } else {
            require(amount + amountPerUser[msg.sender] <= 1, "Exceed Mintable Amount.");
          }
          
          for(uint i = 0; i < amount; i++) {
            _safeMint(msg.sender, ticketId[ticketType]);
          }
          amountPerUser[msg.sender] += amount;
        } else {
          require(msg.value >= _tokenPrice, "Insufficient Funds For Mint.");
          for(uint i = 0; i < amount; i++) {
            _safeMint(msg.sender, ticketId[ticketType]);
          }
        }
        ticketId[ticketType] += amount;
    }

    function bulkMintForTeam(uint256[] memory _tokenIds) public onlyOwner {
      for(uint i = 0; i < _tokenIds.length; i++) {
        _safeMint(msg.sender, _tokenIds[i]);
      }
    }

    function setWhitelist(address[] memory _whitelistMember, uint256 ticketType) public onlyOwner {
        for(uint i = 0; i < _whitelistMember.length; i++) {
            whitelistMember[ticketType][_whitelistMember[i]] = true;
        }
    } 

    function setNotoriousMember(address[] memory _notoriousMembers) public onlyOwner {
        for(uint i = 0; i < _notoriousMembers.length; i++) {
           notoriousMembers[_notoriousMembers[i]] = true;
        }
    }

    function removeWhitelist(address _blackAddr) public onlyOwner {
      for(uint i = 0; i < 4; i++) {
        whitelistMember[i][_blackAddr] = false;
      }
      notoriousMembers[_blackAddr] = false;
    }

    function setTokenPrice(uint256 newPrice) public onlyOwner {
        _tokenPrice = newPrice;
    }

    function setMintStatus(uint8 newStatus) public onlyOwner {
        mintStatus = newStatus;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
    
    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}