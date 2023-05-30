// SPDX-License-Identifier: ISC

pragma solidity ^0.8.4;
import "erc721a/contracts/ERC721A.sol"; 
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Airdrop is ERC721A, Ownable {
    using Counters for Counters.Counter;  
    
    /* No proxy used in this contract as per the client's request */
    constructor(string memory _name, string memory _symbol, string memory baseTokenURI, uint32 maxTokenSupply)
      ERC721A(_name, _symbol) {
          _baseTokenURI = baseTokenURI;
        _maxSupply = maxTokenSupply;
        _contractFrozen = false;
        contractURIInput = "/contract";
        /*increment to start the tokenid at 1*/
         _tokenIdTracker.increment();
        }
      
    /* Variables needed to initailize contract */
    string private _baseTokenURI;
    /* input param to adjust contract URI*/
    string private contractURIInput;
    /* to avoid adding the tokenId as a param in the airdrop and lower gas. */
    Counters.Counter public _tokenIdTracker;
    /* Set for transparency reasons */    
    uint32 private _maxSupply;
    /** This starts off as false because we are able to mint tokens to wallets via airdrpo*/
    bool public closeMinting = false;
    /** Also set to false via constructor stating that the metadata can be adjusted*/
    bool _contractFrozen;
    /* Mappings for tokenURIs */   
    mapping (uint256 => bool) private _frozenURI;
    mapping (uint256 => string) private _tokenURI;
    
    /** Notify that no more tokens will be dispersed*/
    event MintingClosed(bool val);
    /** Notify frozen metadata*/
    event PermanentURI(string _value, uint256 indexed _id, bool _isfrozen, address indexed caller);
    /** Notify metadata changed*/
    event MetadataChanges(uint256 indexed _id, string _value, address indexed caller);
     /** Notify metadata changed*/
    event AllMetadataFrozen(bool _isfrozen);
    
    /* View functions to determine maxSupply, contractURI*/
    function maxSupply() external view virtual returns (uint32) {
        return _maxSupply;
        }
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
        }
    function contractURI() public view returns (string memory) {
        string memory baseURI = _baseURI();
        return string(abi.encodePacked(baseURI, contractURIInput));
        }
    
      /*
      * @notice airDropToken is an admin function that will mint one or more tokens to one or more recipients.
      * @param receivers: a list of addresses that will receive the air dropped token
      * @param uris: a list of URIs for the metadata associated with the token
      * @param intended_first_token_id: tokenid to begin set.
      * @dev this is to ensure that order stays as intended.
      * @require owner sets this to true after original tokens returned to ensure no more tokens are added to the collection. 
      * @return None
      * @dev The order and length of all lists must be equal for this function to succeed. */
       
     function airDropToken(address[] calldata receivers, string[] calldata  uris, uint256 intended_first_token_id) external onlyOwner  {
        require(closeMinting == false, "ALREADY_CLOSED");
        require(_tokenIdTracker.current() == intended_first_token_id, "WRONG_ID");
        require(_tokenIdTracker.current() + receivers.length <= _maxSupply + 1, "ALL_MINTED");
        for (uint256 i = 0; i < receivers.length; i++) {
            _mint(receivers[i], 1);
            _tokenURI[_tokenIdTracker.current()] = uris[i];
             _tokenIdTracker.increment();
           
             }
        }
    /* 
    @dev: overrides implementation to allow tokenURI setting 
    */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "INVALID_TOKENID");
        return _tokenURI[tokenId];
    }
    
    /* 
    dev: overrides implementation to allow start token Id's at 1 setting 
    */
     function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
    /* Function for owner of a token to or the contract to freeze metadata. */
    function freezeTokenMetadata(uint256 tokenId, bool freeze) external {
        require(_contractFrozen != true, "CONTRACT_FROZEN");
        require(msg.sender == ownerOf(tokenId) || msg.sender == owner() , "INVALID_CALLER");
        require(_exists(tokenId), "INVALID_TOKEN");
         _frozenURI[tokenId] = freeze;
        emit PermanentURI(_tokenURI[tokenId], tokenId, freeze, msg.sender);
        }
     
     /* Below are setter functions for the contract owner */
    
    /* Contract owner can set token metadata */
    function setMetadata(uint256 tokenId, string calldata uri) external onlyOwner {
       require(_contractFrozen != true, "CONTRACT_FROZEN");
       require(_exists(tokenId), "NONEXISTENT_TOKEN"); 
       require(_frozenURI[tokenId] == false, "URI_FROZEN");
          _tokenURI[tokenId] = uri;
         emit MetadataChanges(tokenId, uri, msg.sender);
     }
    
    /* 
    @notice Sets closing state to close 
    @dev Cannot undo this, make sure all tokens have been dispersed
    */
    function setMintingtoClosed() external onlyOwner {
        require(closeMinting == false, "ALREADY_CLOSED");
        closeMinting = true;
        emit MintingClosed(true);
    }
    /* 
    @notice: Contract owner freezes all token metadata 
    @dev: Contract owner can update in the case that someone has decided to not reveal token and need to do so.
    */
    function freezeContractMetadata() external onlyOwner {
        _contractFrozen = true;
        emit AllMetadataFrozen(true);
    }  
    /* 
    @param: newbaseURI replaces _baseTokenURI first part of contract uri by defaul followed by "/contract".
    @notice: The "_baseTokenURI" variable in the contract URI function above re: contractURI().
    @param: newContractURIInput replaces the contractURIInput initalized in the constructor.
    @notice: newContractURIInput is by default "/contract" it will likely not need to be adjusted.
    @dev: Contract owner can update to adjust the contract URI
    */ 
    function setContractURI(string calldata newbaseURI, string calldata newContractURIInput) external onlyOwner {
        _baseTokenURI = newbaseURI;
        contractURIInput = newContractURIInput;
     }
 
    /* Determine if the given token is frozen and no longer supports metadata updates */
    function tokenIsFrozen(uint256 tokenId) public view returns (bool isFrozen) {
        require(_exists(tokenId), "INVALID_TOKEN");
        return _frozenURI[tokenId];
    }
     /* Determine if the contract metadata is frozen and no longer supports metadata updates */
    function contractIsFrozen() external view returns (bool) {
        return _contractFrozen;
    }
}