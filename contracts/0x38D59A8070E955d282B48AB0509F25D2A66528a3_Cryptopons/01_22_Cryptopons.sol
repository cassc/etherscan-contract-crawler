// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;  
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol"; 
import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol"; 
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {DefaultOperatorFilterer} from "../DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
 
error InvalidCall();

contract Cryptopons is  Ownable,AccessControl,ERC2981,ReentrancyGuard,ERC721AQueryable,DefaultOperatorFilterer{ 
  using Strings for uint256;
  struct NewCollection{ 
    uint256 supplies;
    uint256 startTokenID;
    uint256 endTokenID;
    string collectionName;
    string baseURI;
  }

  address public signer = 0x00A5bAc26C0BE6A598d0E524725C85ad8F188BaF;   
  bytes32 private constant _APPROVED_ROLE = keccak256("APPROVED_ROLE"); 
  uint16 public constant MAX_SUPPLY = 3333;  
  string private _baseTokenURI = "ipfs:///";    
  
  mapping(address => uint256) public minted; 
  mapping(uint256 => NewCollection) public newCollections;
  
  bool public isStartPublicSale = false; 
  bool public isStartWhiteListSale = false; 
  bool public isStartWaitListSale = false; 

  uint256 public maxPerWallet = 1; 
  uint256 public mintPrice = 0 ether;    
  uint256 public nextNewCollectionID = 1; 
  mapping(uint256 => string) customBaseUri; 

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol
    )  ERC721A(_tokenName, _tokenSymbol) { 
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);  
    _safeMint(msg.sender, 1); // Setup 
    setRoyaltyInfo(0xE25345d9F65AB40B5F1aD5295d59a19D6D27fDDf, 750);
  } 

  function isApprovedForAll(
    address owner, 
    address operator
  ) public view override(ERC721A,IERC721A) returns(bool) {
    return hasRole(_APPROVED_ROLE, operator) 
      || super.isApprovedForAll(owner, operator);
  }  

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 tokenId) 
  public view virtual override(ERC721A,IERC721A) returns (string memory) {
    if(!_exists(tokenId)) revert InvalidCall();
 
    if (bytes(customBaseUri[tokenId]).length > 0) { 
        return customBaseUri[tokenId]; // Complete URL format
    }

    if(tokenId > MAX_SUPPLY){
        string memory newTokenURI = "";
        unchecked{ 
            for(uint256 i = 1 ; i < nextNewCollectionID ; i++){ 
                if(tokenId >= newCollections[i].startTokenID && tokenId <= newCollections[i].endTokenID){
                    newTokenURI = newCollections[i].baseURI;
                    break;
                }
            } 
        }
        return string(
            abi.encodePacked(newTokenURI, tokenId.toString(), ".json") // ipfs://newcollection/ format
        );
    }else{  
        return string( abi.encodePacked(_baseTokenURI, tokenId.toString(), ".json") );
    } 
  }  

  function mint(uint256 quantity) external payable nonReentrant {
    address recipient = _msgSender(); 
    if (recipient.code.length > 0 
      || !isStartPublicSale 
      || quantity == 0  
      || (quantity + minted[recipient]) > maxPerWallet 
      || (quantity * mintPrice) > msg.value 
      || (totalSupply() + quantity) > MAX_SUPPLY
    ) revert InvalidCall(); 
    minted[recipient] += quantity;
    _safeMint(recipient, quantity);
  } 

  function specialMint(
    uint256 quantity, 
    bytes memory proof
  ) external payable nonReentrant {
    address recipient = _msgSender(); 
    if (quantity == 0  
        || (!isStartWhiteListSale && !isStartWaitListSale)
        || (quantity + minted[recipient]) > maxPerWallet 
        || (quantity * mintPrice) > msg.value 
        || (totalSupply() + quantity) > MAX_SUPPLY 
        || ECDSA.recover( 
            ECDSA.toEthSignedMessageHash( 
            keccak256(abi.encodePacked("specialMint", recipient)) 
            ),  proof )  != signer
    ) revert InvalidCall(); 

    minted[recipient] += quantity;
    _safeMint(recipient, quantity);
  }  

  function setCustomBaseUri(uint256 _tokenID,string memory _customBaseUri,bytes memory _proof) external nonReentrant {
    if(!(owner() == msg.sender || ownerOf(_tokenID) == msg.sender)) revert InvalidCall(); 
    if(ECDSA.recover( 
      ECDSA.toEthSignedMessageHash( 
      keccak256(abi.encodePacked("setCustomBaseUri", _tokenID,_customBaseUri)) 
      ),  _proof )  != signer) revert InvalidCall(); 
    customBaseUri[_tokenID] = _customBaseUri;
  }

  function burnNFT(uint256 _tokenID,bytes memory _proof) external nonReentrant {
    if(!(owner() == msg.sender || ownerOf(_tokenID) == msg.sender)) revert InvalidCall(); 
    if(ECDSA.recover( 
      ECDSA.toEthSignedMessageHash( 
      keccak256(abi.encodePacked("burnNFT", _tokenID)) 
      ),  _proof )  != signer) revert InvalidCall(); 
    _burn(_tokenID);
  }

  function mintForAddress(
    address recipient,
    uint256 quantity
  ) external onlyOwner nonReentrant { 
    if (quantity == 0  
      || (totalSupply() + quantity) > MAX_SUPPLY
    ) revert InvalidCall();

    _safeMint(recipient, quantity);
  }
  
  function mintNewCollection( 
    address _recipient,
    uint256 _supplies,
    string memory _collectionName,
    string memory _baseURI
  ) external onlyOwner nonReentrant {   
    if(totalSupply() < MAX_SUPPLY) revert InvalidCall();
    if(address(0) == _recipient) revert InvalidCall();
    if(_supplies <= 0) revert InvalidCall();
    if(bytes(_baseURI).length <= 0) revert InvalidCall();
    if(bytes(_collectionName).length <= 0) revert InvalidCall();

    newCollections[nextNewCollectionID].collectionName = _collectionName;
    newCollections[nextNewCollectionID].supplies = _supplies;
    newCollections[nextNewCollectionID].baseURI = _baseURI;
    newCollections[nextNewCollectionID].startTokenID = totalSupply() + 1;
    newCollections[nextNewCollectionID].endTokenID = totalSupply() + _supplies;
    unchecked {
        nextNewCollectionID = nextNewCollectionID + 1;
    }
    _safeMint(_recipient, _supplies);
  }
  
  function modifyNewCollection( 
    uint256 _newCollectionID,
    string memory _collectionName,
    string memory _baseURI
  ) external onlyOwner nonReentrant { 
    if(newCollections[_newCollectionID].supplies <= 0) revert InvalidCall(); 
    if(bytes(_baseURI).length <= 0) revert InvalidCall();
    if(bytes(_collectionName).length <= 0) revert InvalidCall();

    newCollections[_newCollectionID].collectionName = _collectionName;
    newCollections[_newCollectionID].baseURI = _baseURI;
  }  

  function setSigner(address signer_) public onlyOwner{
      signer = signer_;
  } 

  function setBaseURI(string memory uri) external onlyOwner {
    _baseTokenURI = uri;
  } 
  
  function setMaxPerWallet(uint256 max) external onlyOwner {
    maxPerWallet = max;
  }  

  function setMintPrice(uint256 price) external onlyOwner {
    mintPrice = price;
  }  

  function setPausesStates(bool _isStartPublicSale,bool _isStartWhiteListSale,bool _isStartWaitListSale) 
  external onlyOwner {
    isStartPublicSale = _isStartPublicSale;
    isStartWhiteListSale = _isStartWhiteListSale;
    isStartWaitListSale = _isStartWaitListSale;
  }  
  
  function withdraw(address to) external onlyOwner nonReentrant {  
    payable(to).transfer(address(this).balance);
  }  

  function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBips) public onlyOwner {
    _setDefaultRoyalty(_receiver, _royaltyFeesInBips);
  } 

  function supportsInterface(
    bytes4 interfaceId
  ) public view override(AccessControl,ERC2981, ERC721A, IERC721A) returns(bool) { 
    return interfaceId == type(IERC721Metadata).interfaceId  
      || interfaceId == 0x2a55205a 
      || super.supportsInterface(interfaceId);
  }
  
  function transferFrom(address from, address to, uint256 tokenId) public payable virtual override(ERC721A,IERC721A) onlyAllowedOperator {
      super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public payable virtual override(ERC721A,IERC721A) onlyAllowedOperator {
      super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
      public payable virtual override(ERC721A,IERC721A)
      onlyAllowedOperator
  {
      super.safeTransferFrom(from, to, tokenId, data);
  } 
}