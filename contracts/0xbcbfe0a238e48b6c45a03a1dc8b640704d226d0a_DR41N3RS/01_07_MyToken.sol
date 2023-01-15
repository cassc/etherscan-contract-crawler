// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";

// import "operator-filter-registry/src/DefaultOperatorFilterer.sol"; We do not block marketplaces bc we are not BROKES!!!!! 

contract DR41N3RS is ERC721A, Ownable {
    uint public countDrainsUntilMaldives = 1111;
    uint public price = 0.003 ether;
    uint public maxDrainsPerWallet = 5;
    mapping(address => uint256) private countDrained; 
    string public baseURI;
    bool public isPublicDrainActive = false;
    event ThankYouForTheMoney();

    constructor(string memory _baseDR41N3RSURI) ERC721A("DR41N3RS", "DRAIN") {
        baseURI = _baseDR41N3RSURI;
    }

    function publicDrain(uint256 countToDrain) public payable {
        require(totalSupply() + countToDrain <= countDrainsUntilMaldives, "If your transaction wass reverted at this point, it means we've already left.");
        require(isPublicDrainActive == true, "Public drain is inactive");
        require(msg.value >= countToDrain * price, "Random ass poor, go make some money first :clown:");
        require(countDrained[msg.sender] + countToDrain <= maxDrainsPerWallet, "U have already been drained");
        
        countDrained[msg.sender] += countToDrain;
        _safeMint(msg.sender, countToDrain);
        emit ThankYouForTheMoney();
    }
    
    function togglePublicDrain() public onlyOwner {
        isPublicDrainActive = !isPublicDrainActive;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }


    function withdrawDrainedMoney(address receiver) public onlyOwner {
        // GUYS I REALLY HOPE THIS FUNCTION WORKS
        
        address payable _to = payable(receiver);
        address _thisContract = address(this);
        _to.transfer(_thisContract.balance);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseUri(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        
        return bytes(_baseURI()).length != 0 ? string(abi.encodePacked(_baseURI(), _toString(tokenId), ".json")) : '';
    }
    
    
    function teamDrain(uint256 count) public onlyOwner {
        _safeMint(msg.sender, count);
    }


    function _startTokenId() internal view override virtual returns (uint256) {
        return 1;
    }

    receive() external payable {
        // YOU ALL CORRECTLY UNDERSTAND. YOU CAN SEND US A DONATION TO BUY A GUCCI CAP
    } 
}