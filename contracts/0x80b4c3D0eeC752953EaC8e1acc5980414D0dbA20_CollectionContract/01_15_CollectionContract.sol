// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";


contract CollectionContract is ERC721,Pausable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    bool revealed = false;
    uint256 public maxSupply;
    string public baseExtension = ".json";
    uint256 mintPrice;
    uint256 maxMintCount;
    string private baseURI;
    //string public contractURI;
    address public benefactor;
    
    constructor(
        string memory name,
        string memory symbol,
        address _owner,
        uint supply,
        uint256 _mintPrice,
        string memory _prerevealURI,
        //string memory _contractURI,
        uint256 _maxMintCount,
        address _splitterAddress

        ) ERC721(name, symbol) Pausable() {
            maxSupply = supply;
            mintPrice = _mintPrice;
            maxMintCount = _maxMintCount;
            baseURI = _prerevealURI;
            //contractURI = _contractURI;
            benefactor = _splitterAddress;
            //pausing the contract initially help
            _transferOwnership(_owner);
            _pause();
        }
    //getters
    function tokenPrice() public view returns(uint256){
        return mintPrice;
    }

    function tokenURI(uint tokenId) public view virtual override returns (string memory){
        //token has to exist
        require(_exists(tokenId), "Token ID not found");
        
        
        //we mint in incremental order so if the tokenId requested is larger than current counter value
        //we  return prereveal metadata instead.
        
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI,  Strings.toString(tokenId), baseExtension)) : "";
    }

   

    //For open sea
    function baseTokenURI() public view returns (string memory) {
        return baseURI;
    }
    function totalSupply() public view returns(uint256){
        return _tokenIdCounter.current();
    }
   
    //onlyOwner
   

    function mint(uint256 _count) public payable whenNotPaused {
        uint256 tokenId = _tokenIdCounter.current();
        
        require(_count > 0,"Come on, mint at least 1");
        require(_count <= maxMintCount,"Hold you horses! That is too many tokens for a single transaction");
        require(tokenId + _count <= maxSupply,"Not enough supply to fullfill the request");
        require(msg.value >= mintPrice * _count,"Not enough money to mint");
        //This loop will mint x number of nfts
        for (uint256 i = 0; i < _count; i++) {
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenId+i);
        }
    }




    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
    //basically same as setBaseURI just more readable.
    //the revealed boolean value is just there as a set once property
    //and it can only be set to true. Once it is true the collection is revealed forever.
    //If you look closer you'll understand that we can call thiw function mulitple times
    //This is a safety feature to ensure that if anything were to go wrong with the launch
    //we can generate new metadata and point the contract to a new baseURI
    function reveal(string memory _newBaseURI) public onlyOwner {
        revealed = true;
        baseURI = _newBaseURI;
    }
    //allows us to update the contract metadata for opensea
    /*function setContractURI(string memory _newBaseURI) public onlyOwner {
        revealed = true;
        baseURI = _newBaseURI;
    }*/




    //Enable owner to send money to benefactor contract
    //Benefactor contract is just a simple Money Splitter to allow trustless and transparent
    //division of rewards to our team. We don't keep the splitter in this contract to reduce the contract complexity
    //which would increase gas cost for our community, and fuck that.
    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(benefactor).call{value: address(this).balance}("");
        require(success);
    }

    //function to

    //nifty helper function to get the balance of the contract
    function balance() public view onlyOwner returns(uint256){
        return address(this).balance;
    }



    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override
        {
            super._beforeTokenTransfer(from, to, tokenId);
        }
    



    //ERC2981

}