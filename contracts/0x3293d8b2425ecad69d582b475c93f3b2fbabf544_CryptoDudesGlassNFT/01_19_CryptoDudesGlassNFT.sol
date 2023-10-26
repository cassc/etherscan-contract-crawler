// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//@author Mia Dude
//@title CryptoDudes NFT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol";
import "./extensions/ERC721AQueryable.sol";
import "./CryptoDudesNFT.sol";

contract CryptoDudesGlassNFT is Ownable, ERC721A, ERC721AQueryable {

    using Strings for uint;

    //URI of the NFTs when revealed
    string public baseURI;

    //start mint time
    uint public saleStartTime = 1659888000;

     //the current max supply
    uint public MAX_SUPPLY = 2222;

    // tokenId already minted ? => bool
   
    //mapping (uint => bool) isGlassMinted keep track of tokenid used, by nft contract;
    mapping(address => mapping(uint => bool)) public isGlassMinted;

    //nft contracts allowed to claim some free glass of white russian
    mapping(address => bool) isNFTContractAllowed;

    // **********************************************************************************
    // *********** CONSTRUCTOR 
    // **********************************************************************************

    constructor(string memory _baseURI, address _nft) ERC721A("WhiteRussian", "WHITERUSSIAN")  {
        baseURI = _baseURI;
        isNFTContractAllowed[_nft] = true;
    }
     
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }


    // **********************************************************************************
    // *********** PUBLIC MINT  
    // **********************************************************************************

    function publicMint(address _account, uint[] calldata tokenIds, address _nftContract) external callerIsUser {
        uint quantity = 0;
        uint tokenId;
        CryptoDudesNFT nft;

        require(currentTime() >= saleStartTime, "Public mint has not started yet");
        require(tokenIds.length > 0, "No CryptoDudesNFT token Ids provided");
        require(isNFTContractAllowed[_nftContract] == true, "NFT Contract not allowed");

        nft = CryptoDudesNFT(payable(_nftContract));

        for(uint i = 0; i < tokenIds.length ; i++){
            tokenId = tokenIds[i];
            if ( (nft.ownerOf(tokenId) == msg.sender) && (isGlassMinted[_nftContract][tokenId] == false) ) {
                isGlassMinted[_nftContract][tokenId] = true;
                quantity += 1;
            }
        }

        require (quantity > 0, "Ooops, no glass to mint for you");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Max supply exceeded");   

        _safeMint(_account, quantity);
    }

    // **********************************************************************************
    // *********** settings 
    // **********************************************************************************

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    // we can update the max supply (ex: for a second collection, we could mint extra glasses of white russians for the cryptodudes)
   
    function updateMaxSupply(uint _maxSupply) external onlyOwner {
        MAX_SUPPLY = _maxSupply;
    }

    //add or remove authorized collection
    function updateAllowedContract(address _nftContract, bool _allowed) external onlyOwner {
        isNFTContractAllowed[_nftContract] = _allowed;
    }


    function currentTime() internal view returns(uint) {
        return block.timestamp;
    }

    //we can update this if we need to stop the glass mint, for a futur drop
    function setSaleStartTime(uint _saleStartTime) external onlyOwner {
        saleStartTime = _saleStartTime;
    }


    // **********************************************************************************

    function tokenURI(uint _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");
        
        // uniq base uri, same glass
        return baseURI;
    }

}