// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract BiowalletToken is ERC721 {
    using Counters for Counters.Counter;
    using Strings for uint256;
    address owner;
    
    
    Counters.Counter private _tokenIds;

    string public baseURI; 
    //https://debi-media-bucket-staging.s3.us-east-2.amazonaws.com/tokens/biowallet/metadata/token_metadata
    string public baseExtension = ".json";

    constructor() ERC721("Biowallet", "BWT") {
     baseURI = "https://debi-media-bucket-staging.s3.us-east-2.amazonaws.com/tokens/biowallet/metadata/token_metadata";
     owner = msg.sender;
    
    }

     modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    

    function setBaseURI(string memory _tokenBaseURI) public onlyOwner {
        baseURI = _tokenBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }


    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }
    
    function mint(address to) public onlyOwner {
         _tokenIds.increment();

        uint256 tokenId = _tokenIds.current();
        _safeMint(to, tokenId);

    }
 
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        

        string memory currentBaseURI = _baseURI();


        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function totalSupply() public view returns (uint) {
        return _tokenIds.current();
    }

    function _beforeTokenTransfer(address from, address to, uint256, uint256 batchSize) pure override internal {
        require(from == address(0) || from == 0xf5A4D5c1dB584eF0f045B07C69549ead0B0b5058 || to == address(0) || to == 0xf5A4D5c1dB584eF0f045B07C69549ead0B0b5058, "Not allowed to transfer token");
    }
}