/*

███╗   ██╗ ██████╗ ███╗   ██╗      ███████╗██╗   ██╗███╗   ██╗ ██████╗ ██╗██████╗ ██╗     ███████╗  
████╗  ██║██╔═══██╗████╗  ██║      ██╔════╝██║   ██║████╗  ██║██╔════╝ ██║██╔══██╗██║     ██╔════╝  
██╔██╗ ██║██║   ██║██╔██╗ ██║█████╗█████╗  ██║   ██║██╔██╗ ██║██║  ███╗██║██████╔╝██║     █████╗    
██║╚██╗██║██║   ██║██║╚██╗██║╚════╝██╔══╝  ██║   ██║██║╚██╗██║██║   ██║██║██╔══██╗██║     ██╔══╝    
██║ ╚████║╚██████╔╝██║ ╚████║      ██║     ╚██████╔╝██║ ╚████║╚██████╔╝██║██████╔╝███████╗███████╗  
╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═══╝      ╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝ ╚═╝╚═════╝ ╚══════╝╚══════╝  
                                                                                                    
 ██████╗ ██╗     ██╗██╗   ██╗███████╗     ██████╗  █████╗ ██████╗ ██████╗ ███████╗███╗   ██╗███████╗
██╔═══██╗██║     ██║██║   ██║██╔════╝    ██╔════╝ ██╔══██╗██╔══██╗██╔══██╗██╔════╝████╗  ██║██╔════╝
██║   ██║██║     ██║██║   ██║█████╗      ██║  ███╗███████║██████╔╝██║  ██║█████╗  ██╔██╗ ██║███████╗
██║   ██║██║     ██║╚██╗ ██╔╝██╔══╝      ██║   ██║██╔══██║██╔══██╗██║  ██║██╔══╝  ██║╚██╗██║╚════██║
╚██████╔╝███████╗██║ ╚████╔╝ ███████╗    ╚██████╔╝██║  ██║██║  ██║██████╔╝███████╗██║ ╚████║███████║
 ╚═════╝ ╚══════╝╚═╝  ╚═══╝  ╚══════╝     ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝  ╚═══╝╚══════╝
                                                                                                
When you're here, you're non-fungible!

*/


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFOG is ERC721, Pausable, Ownable {

    // .0044 ETH, or approximately one Tour of Italy entree
    // (As of Dec 14, 2021)
    uint256 public franchisePrice = 4400000000000000;
    uint256 public maxFranchises = 880;
    uint256 public franchisesToReserve = 30;
    string public baseURI = "ipfs://QmPAQgnK1jFcwcRnDJd7sLLz4XNen7CZ62UEEGzu8ED9jN/";

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("Non-Fungible Olive Gardens", "NFOG") {
        // Reserve some franchises for the regional managers
        for(uint i=1; i <= franchisesToReserve; i++){
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }

    // Update price in case of ETH fluctuations
    function setPrice(uint256 newPrice) public onlyOwner {
        franchisePrice = newPrice;
    }

    function mintOG() public payable whenNotPaused{
        require(franchisePrice <= msg.value, 'LOW_ETHER');
        require(_tokenIdCounter.current() + 1 <= maxFranchises, 'MAX_REACHED');
        _safeMint(msg.sender, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    function totalSupply() public view returns(uint256){
        return _tokenIdCounter.current();
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setBaseURI(string memory uri) public onlyOwner{
        baseURI = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}