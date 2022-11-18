// SPDX-License-Identifier: MIT


import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./Utils/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

pragma solidity ^0.8.7;

interface ERC721Partial {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

/// @title KOPOKO Mafia Council

contract KOPOKOMafiaCouncil is ERC721A, PaymentSplitter, Ownable, ReentrancyGuard {


    //To concatenate the URL of an NFT
    using Strings for uint256;

    //Price to mint
    uint64 public priceCustomBikkuri = 0.3 ether;
    uint64 public priceCustomSame = 0.25 ether;
    //URI of the NFTs when revealed
    string private baseURI;
    //The extension of the file containing the Metadatas of the NFTs
    string public baseExtension = ".json";

    //The different stages of selling the collection
    enum Steps {
        Before,
        Presale
    }

    Steps public sellingStep;
    
    //Owner of the smart contract
    address private _owner;

    //Genesis contract
    ERC721Partial tokenContract;

    //Keep a track of the token per tier
    mapping(uint => string) public tier;

    //Addresses of all the members of the team
    address[] private _team = [
        0x5B1a4ebd28b597fe47494A0a5766b2Eb6e6B3fcC
    ];

    //Shares of all the members of the team
    uint[] private _teamShares = [
        100
    ];
    
    //The different stages of selling the collection
    string[] tiers = ["Kyodai","Bikkuri","Same","Kujira","Monsuta"];
    
    //Constructor of the collection
    constructor() ERC721A("KPK Council", "KPKC") PaymentSplitter(_team, _teamShares) {
       
        transferOwnership(msg.sender);
        _owner = msg.sender;
        sellingStep = Steps.Before;
        
    
    }
  

    /**
     * To change the starting tokenId, please override this function.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    
    /**
    * @notice Change the price of one NFT for the bikkuri
    *
    * @param _priceCustomBikkuri The new price of one NFT for the presale
    **/
    function changePriceCustomBikurri(uint64 _priceCustomBikkuri) external onlyOwner {
        priceCustomBikkuri = _priceCustomBikkuri;
    }

    /**
    * @notice Change the price of one NFT for the sale
    *
    * @param _priceCustomSame The new price of one NFT for Same
    **/
    function changePriceCustomSame(uint64 _priceCustomSame) external onlyOwner {
        priceCustomSame = _priceCustomSame;
    }

    /**
    * @notice Initialise Merkle Root
    *
    * @param _theBaseURI Base URI=
    * @param _tokenContract The new Merkle Root
    **/
    function init(string memory _theBaseURI, ERC721Partial _tokenContract) external onlyOwner {

        baseURI = _theBaseURI;
        tokenContract = _tokenContract;
    }
    
    
    /**
    * @notice Change the base URI
    *
    * @param _newBaseURI The new base URI
    **/
    function setBaseUri(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    /**
    * @notice Return URI of the NFTs when revealed
    *
    * @return The URI of the NFTs when revealed
    **/
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
    * @notice Allows to change the base extension of the metadatas files
    *
    * @param _baseExtension the new extension of the metadatas files
    **/
    function setBaseExtension(string memory _baseExtension) external onlyOwner {
        baseExtension = _baseExtension;
    }

    /** 
    * @notice Allows to change the sellinStep to Presale
    **/
    function setUpPresale() external onlyOwner {
        sellingStep = Steps.Presale;
    }

    /**
    * @notice Allows to mint one NFT if whitelisted
    *
    * 
    * @param _tokenIds Tokens that sender want to transfer
    * @param _custom custom council
    **/
    function presaleMint(uint256[] calldata _tokenIds, bool _custom) external payable nonReentrant {
        uint numberNftSold = _totalMinted();
        uint price=0;
        //Are we in Presale ?
        require(sellingStep == Steps.Presale, "Presale has not started yet.");
        // Check length of token
        require(_tokenIds.length == 3 ||_tokenIds.length == 5 ||_tokenIds.length == 7 ||_tokenIds.length == 20, "Wrong length of tokens.");
        
        //Did the user send enought Ethers ?
        if(_tokenIds.length == 3 && _custom){
            price = priceCustomBikkuri;
        }else if(_tokenIds.length == 5 && _custom){
            price = priceCustomSame;
        }
        
        require(msg.value >= price, "Not enought funds.");
        

        for (uint index = 0; index < _tokenIds.length; index++) {
            require(msg.sender == tokenContract.ownerOf(_tokenIds[index]), "You don't own those token");
            tokenContract.safeTransferFrom(msg.sender, _owner, _tokenIds[index]);
            require(_owner == tokenContract.ownerOf(_tokenIds[index]), "Transaction fail..");
        }
        
        //Mint the user NFT
        _safeMint(msg.sender, 1);

        numberNftSold++;
        if(_tokenIds.length == 3){
            tier[numberNftSold] =  tiers[1];
        }else if(_tokenIds.length == 5){
            tier[numberNftSold] =  tiers[2];
        }else if(_tokenIds.length == 7){
            tier[numberNftSold] =  tiers[3];
        }else if(_tokenIds.length == 20){
            tier[numberNftSold] =  tiers[4];
        }
    }

    /**
    * @notice Allows to gift one NFT to an address
    *
    * @param _account The account of the happy new owner of one NFT
    **/
    function gift(address _account, string memory _tier) external onlyOwner {
        uint numberNftSold = _totalMinted();     
        _safeMint(_account, 1);
        numberNftSold++;
        tier[numberNftSold] =  _tier;
    }

      /**
    * @notice Allows to burn one NFT to an address payable
    *
    * @param tokenID The id of the token
    **/
    function burn(uint256 tokenID, bool _custom) external payable nonReentrant{
        
        uint numberNftSold = _totalMinted();
        uint price=0;
        
        //Did the user send enought Ethers ?
        if(compareStrings(tier[tokenID],tiers[1]) && _custom){
            price = priceCustomBikkuri;
        }else if(compareStrings(tier[tokenID],tiers[2]) && _custom){
            price = priceCustomSame;
        }
        require(msg.value >= price, "Not enought funds.");
        require(msg.sender == ownerOf(tokenID),"You don't own this token !");
        _burn(tokenID);

        //Mint the user NFT
        _safeMint(msg.sender, 1);

        numberNftSold++;
        if(compareStrings(tier[tokenID],tiers[0])){
            tier[numberNftSold] =  tiers[0];
        }else if(compareStrings(tier[tokenID], tiers[1])){
            tier[numberNftSold] =  tiers[1];
        }else if(compareStrings(tier[tokenID], tiers[2])){
            tier[numberNftSold] =  tiers[2];
        }else if(compareStrings(tier[tokenID], tiers[3])){
            tier[numberNftSold] =  tiers[3];
        }else if(compareStrings(tier[tokenID], tiers[4])){
            tier[numberNftSold] =  tiers[4];
        }
       
    }

    /** 
    * @notice Return true or false if the account is whitelisted or not
    *
    * @param a The account of the user
    * @param b The Merkle Proof
    *
    * @return true or false if the strings match
    **/

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
    return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
   }

    /**
    * @notice Allows to get the complete URI of a specific NFT by his ID
    *
    * @param _nftId The id of the NFT
    *
    * @return The token URI of the NFT which has _nftId Id
    **/
    function tokenURI(uint _nftId) public view override(ERC721A) returns (string memory) {
        
        uint numberNftSold = _totalMinted();
        require(_nftId <= numberNftSold && _nftId >= _startTokenId(), "This NFT doesn't exist.");

        string memory currentBaseURI = _baseURI();

        return 
            bytes(currentBaseURI).length > 0 
            ? string(abi.encodePacked(currentBaseURI,tier[_nftId],"/",_nftId.toString(), baseExtension))
            : "";
    }   

}