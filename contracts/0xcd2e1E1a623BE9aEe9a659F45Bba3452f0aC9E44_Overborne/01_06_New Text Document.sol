// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Overborne is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public maxSupply = 2777;
    uint256 public price  = 0 ;
    uint256 private maxTransactionAmount =5;
    string baseURI = "your_uri";
    bool paused;



    constructor () ERC721A("Overborne Genesis","OG"){

    }

    function mint(uint256 _quantity) public payable{
        require(totalSupply()+_quantity <= maxSupply,"Exceeds Max Supply");
        if(msg.sender != owner()){
            require(!paused,"Minting Paused");
            require(msg.value >= _quantity * price,"Insufficient Fund");
            require(_quantity <= maxTransactionAmount,"You cannot mint more than 10");
        }
        _safeMint(msg.sender,_quantity);
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newURI) public onlyOwner{
        baseURI = newURI;
    }

    function tooglePause() public onlyOwner{
        paused = !paused;
    }

    

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory baseURIE = _baseURI();
        return baseURIE;
    }


    
}