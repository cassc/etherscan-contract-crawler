pragma solidity ^0.8.0;

//from "@openzeppelin/[email protected]/token/common/ERC2981.sol";
import {ERC2981} from "./ERC2981.sol";

//from "@openzeppelin/[email protected]/access/Ownable.sol";
import {Ownable} from "./Ownable.sol";

import {UpdatableOperatorFilterer} from "./UpdatableOperatorFilterer.sol";

import {RevokableDefaultOperatorFilterer} from "./RevokableDefaultOperatorFilterer.sol";

import "./Strings.sol";

//from "@openzeppelin/[email protected]/token/ERC721/ERC721.sol";
import "./ERC721.sol";

//import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./MerkleProof.sol";


// TODEM, Created By: LatentCulture.
contract TODEM is ERC2981, ERC721, Ownable, RevokableDefaultOperatorFilterer {
  using Strings for uint256;

  string baseURI;
  string baseExtension = ".json";
  bool public paused = false;
  bool public isAllowListActive = true;
  uint256 public cost = 250000000000;
  uint256 public maxSupply = 1000;
  uint256 public currentSupply = 0;
  uint256 public charity_percentA = 10;
  uint256 public charity_percentB = 5;
  uint256 forCharityA = 0;
  uint256 forCharityB = 0;
  address public charityAddress;
  bytes32 public root;

  struct Entry {
      uint8 numberOfTokens;
      int discount;
      int list_type;
  }

  mapping(address => Entry) private _AllowList;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    bytes32 _root
  ) ERC721(_name, _symbol) {
    setCharity(owner());
    setRoyaltyInfo(owner(), 750);
    setBaseURI(_initBaseURI);
    root = _root;
  }

  function totalSupply() public view returns (uint256) {
      return currentSupply;
  }

  function verify(bytes32[] memory _proof, uint256 _tokenId) public view returns (bool) {
      bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(_tokenId))));
      return
          MerkleProof.verify(
              _proof,
              root,
              leaf
          );
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function calculatePrice(uint256 _tokenId) private view returns (int) {
    return int(_tokenId * cost);
  }

  //addresses: list of strings, discount: 0-100
  //address can mint with percent discount across numAllowedToMint
  function setPercentAllowList(address[] calldata addresses, uint8 numAllowedToMint, int discount) public onlyOwner {
      require(discount<=100, "discount too big");
      for (uint256 i = 0; i < addresses.length; i++) {
          _AllowList[addresses[i]] = Entry(numAllowedToMint, discount, 1);
      }
  }

  //addresses: list of strings, discount: price in wei
  //address can mint with eth discount across numAllowedToMint
  function setBasicAllowList(address[] calldata addresses, uint8 numAllowedToMint, int discount) public onlyOwner {
      for (uint256 i = 0; i < addresses.length; i++) {
          _AllowList[addresses[i]] = Entry(numAllowedToMint, discount, 0);
      }
  }

  //addresses: list of strings, discount: price in wei
  //address can mint up to eth discount across numAllowedToMint
  function setCumulativeAllowList(address[] calldata addresses, uint8 numAllowedToMint, int discount) public onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
        _AllowList[addresses[i]] = Entry(numAllowedToMint, discount, 2);
    }
  }

  function getMintPrice(uint256 _tokenId, address addy) public view returns (int){
    if (addy != owner()) {
        if (1 <= _AllowList[addy].numberOfTokens && (_AllowList[addy].list_type == 0 || _AllowList[addy].list_type == 2)){
            if (calculatePrice(_tokenId) - _AllowList[addy].discount <= 0){
                return 0;
            }
            else{
                return calculatePrice(_tokenId) - _AllowList[addy].discount;
            }
        }
        else if (1 <= _AllowList[addy].numberOfTokens && _AllowList[addy].list_type == 1){
            return calculatePrice(_tokenId) - (calculatePrice(_tokenId) * _AllowList[addy].discount / 100);
        }
        else{
            return calculatePrice(_tokenId);            
        }
    }
    else{
        return 0;
    }
  }

  function mint(uint256 _tokenId, bytes32[] memory _proof) public payable {
    require(verify(_proof, _tokenId), "Not a valid token id");
    require(!paused, "Minting paused");
    require(totalSupply() <= maxSupply, "Minting ended");
    if (msg.sender != owner()) {
        if (1 <= _AllowList[msg.sender].numberOfTokens && (_AllowList[msg.sender].list_type == 0 || _AllowList[msg.sender].list_type == 2)){
            require(isAllowListActive, "Allow list is not active");
            if (calculatePrice(_tokenId) - _AllowList[msg.sender].discount <= 0){
                uint256 price = 0;
                require(msg.value >= price);
                if (_AllowList[msg.sender].list_type == 2){
                    _AllowList[msg.sender].discount -= calculatePrice(_tokenId);
                }                
            }
            else{
                uint256 price = uint256(calculatePrice(_tokenId) - _AllowList[msg.sender].discount);
                require(msg.value >= price);
                if (_tokenId >= 73359200){forCharityA = forCharityA + price;}
                if (_tokenId >= 8954400 && _tokenId < 73359200){forCharityB = forCharityB + price;}
                if (_AllowList[msg.sender].list_type == 2){
                    _AllowList[msg.sender].discount = 0;
                }              
            }
            _AllowList[msg.sender].numberOfTokens -= 1;
            _safeMint(msg.sender, _tokenId);
            currentSupply += 1;
        }
        else if (1 <= _AllowList[msg.sender].numberOfTokens && _AllowList[msg.sender].list_type == 1){
            require(isAllowListActive, "Allow list is not active");
            uint256 price = uint256((calculatePrice(_tokenId) - (calculatePrice(_tokenId)*_AllowList[msg.sender].discount/100)));
            require(msg.value >= price);
            if (_tokenId >= 73359200){forCharityA = forCharityA + price;}
            if (_tokenId >= 8954400 && _tokenId < 73359200){forCharityB = forCharityB + price;}
            _AllowList[msg.sender].numberOfTokens -= 1;
            _safeMint(msg.sender, _tokenId);
            currentSupply += 1;
        }
        else{
            uint256 price = uint256(calculatePrice(_tokenId));
            require(msg.value >= price);        
            if (_tokenId >= 73359200){forCharityA = forCharityA + price;} 
            if (_tokenId >= 8954400 && _tokenId < 73359200){forCharityB = forCharityB + price;} 
            _safeMint(msg.sender, _tokenId); 
            currentSupply += 1;  
        }
    }else{
        _safeMint(msg.sender, _tokenId);
        currentSupply += 1;
    }
  }

  function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBips) public onlyOwner {
    _setDefaultRoyalty(_receiver, _royaltyFeesInBips);
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
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }
  
  function setAllowListActive(bool _isAllowListActive) public onlyOwner {
    isAllowListActive = _isAllowListActive;
  }

  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  //set new merkle root
  function setRoot(bytes32  _newRoot) public onlyOwner {
    root = _newRoot;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setCharity(address _charityAddress) public onlyOwner {
    charityAddress = _charityAddress;
  }

  //percent: 0-100, class: 0 (A) or 1 (B)
  function setCharityPercent(uint256 _charityPercent, uint256 _class) public onlyOwner {
      if(_class == 0){charity_percentA = _charityPercent;}
      if(_class == 1){charity_percentB = _charityPercent;}
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

  function query_charityA() public view onlyOwner returns (uint256){
    return forCharityA * charity_percentA / 100;
  }

  function query_charityB() public view onlyOwner returns (uint256){
    return forCharityB * charity_percentB/ 100;
  }

  function withdraw_charity()public payable onlyOwner {
    (bool c, ) = payable(charityAddress).call{value: forCharityA * charity_percentA / 100 + forCharityB * charity_percentB/ 100}("");
    require(c);
    forCharityA = 0;
    forCharityB = 0;
  }

  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance - forCharityA * charity_percentA / 100 - forCharityB * charity_percentB/ 100}("");
    require(os);
  }

  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
      super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
      super.approve(operator, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
      super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
      super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
      public
      override
      onlyAllowedOperator(from)
  {
      super.safeTransferFrom(from, to, tokenId, data);
  }

  function owner() public view virtual override(Ownable, UpdatableOperatorFilterer) returns (address) {
      return Ownable.owner();
  }

  function supportsInterface(bytes4 interfaceId)
      public
      view
      override(ERC721, ERC2981)
      returns (bool)
  {
      return super.supportsInterface(interfaceId);
  }
}