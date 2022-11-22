// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
// import "./sol";

contract DiceNFT is ERC721Upgradeable, ERC721BurnableUpgradeable, OwnableUpgradeable, PausableUpgradeable {
    using MathUpgradeable for uint256;
    using MathUpgradeable for uint48;
    using MathUpgradeable for uint32;
    using MathUpgradeable for uint16;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter public _tokenIds;
    struct Dice {
        uint256 id;
        uint256 diceType;
        // uint256[] abilities;
    }
    
    mapping(address => mapping(uint256 => uint256)) public dices;// address - id - details // cach lay details = dices[address][diceId]

    address public boxNFT;
    modifier onlyBoxNFTOrOperatorOrOwner {
      require(msg.sender == boxNFT || msg.sender == owner()|| msg.sender == operator);
      _;
    }
    
    address public diceMarketPlace;
    modifier onlyDiceMarketPlaceOrOwner {
      require(msg.sender == diceMarketPlace || msg.sender == owner());
      _;
    }
    
    // namely the ERC721 instances for name symbol decimals etc
    function initialize() public initializer {
        __ERC721_init("Dice NFT BPLUS", "DINB");
        __Ownable_init();
    }

    function initByOwner(address _diceMarketPlace, address _boxNFT) public onlyOwner{
      diceMarketPlace=_diceMarketPlace;
      boxNFT=_boxNFT;
    }
    event logCreateRandomThreeDice(uint256 nftId, uint256 diceType);
    
    function createDice(address owner,uint256 diceType) public onlyBoxNFTOrOperatorOrOwner whenNotPaused returns (uint256) {
        _tokenIds.increment();
        uint256 newDiceId = _tokenIds.current();
        _safeMint(owner, newDiceId);
        dices[owner][newDiceId] = encode(Dice(newDiceId,diceType));
        diceIndexToOwner[newDiceId ]=owner;
        return newDiceId;
    }

    function updateDice(address owner,uint256 nftId, uint256 id, uint256 diceType) public onlyOperatorOrOwner returns (uint256) {
        dices[owner][nftId] = encode(Dice(id,diceType));
        return nftId;
    }


    // function createRandomThreeDice(address owner) public {
    //     for (uint i=0; i<3; i++) {
    //     _tokenIds.increment();
    //     uint256 newDiceId = _tokenIds.current();
    //     //we can call mint from the ERC721 contract to mint our nft token
    //     // _safeMint(msg.sender, newDiceId);
    //     _safeMint(owner, newDiceId);
        
    //     uint256 value = uint256(newDiceId*block.timestamp);
    //     uint256 diceTypeRandom = (value << 30+i*2)%10+1;

    //     emit logCreateRandomThreeDice(newDiceId,diceTypeRandom);
    //     dices[owner][newDiceId] = encode(Dice(newDiceId,diceTypeRandom));
    //     }
    // }

    function getDice(address owner, uint256 id) public view returns (Dice memory _dice) {
      uint256 details= dices[owner][id];
      _dice.id = uint256(uint48(details>>100));
      _dice.diceType = uint256(uint16(details>>148));
    }
  
  function getDicePublic(address _owner, uint256 _id) public view returns (
          uint256 id,
          uint256 diceType) {
      Dice memory _dice= getDice(_owner,_id);
      id=_dice.id;
      diceType=_dice.diceType;
    }

  function encode(Dice memory dice) public pure returns (uint256) {
    // function encode(Dice memory dice)  external view returns  (uint256) {
      uint256 value;
      value = uint256(dice.id);
      value |= dice.id << 100;
      value |= dice.diceType << 148;
      return value;
  }

  function getDiceOfSender(address sender) external view returns (Dice[] memory ) {
        uint range=_tokenIds.current();
        uint i=1;
        uint index=0;
        uint x=0;
        for(i; i <= range; i++){
          Dice memory dice = getDice(sender,i);
          if(dice.id !=0){
            index++;
          }
        }
        Dice[] memory result = new Dice[](index);
        i=1;
        for(i; i <= range; i++){
          Dice memory dice = getDice(sender,i);
          if(dice.id !=0){
            result[x] = dice;
            x++;
          }
        }
        return result;
  }

  function transfer(uint256 _nftId, address _target)
        external
    {
        require(_exists(_nftId), "Non existed NFT");
        require(
            ownerOf(_nftId) == msg.sender || getApproved(_nftId) == msg.sender,
            "Not approved"
        );
        require(_target != address(0), "Invalid address");
        if(msg.sender != diceMarketPlace){
          require(msg.sender != _target, "Can not transfer myself");
        }
        Dice memory dice= getDice(ownerOf(_nftId),_nftId);
        // star will start = 1, exp will start = 0
        dices[_target][_nftId] = encode(dice);
        dices[ownerOf(_nftId)][_nftId]= encode(Dice(0,0));
        diceIndexToOwner[_nftId]=_target;
        _transfer(ownerOf(_nftId), _target, _nftId);
    }

function transferFrom(
        address from,
        address to,
        uint256 tokenId 
    )
        public  virtual override  whenNotPaused 
    {
        require(_exists(tokenId ), "Non existed NFT");
        require(from != to, "Can not transfer myself");
        require(ownerOf(tokenId ) == from, "Only owner NFT can transfer");
        require(
            ownerOf(tokenId ) == msg.sender || getApproved(tokenId ) == msg.sender,
            "Not approved"
        );
        require(to != address(0), "Invalid address");

        Dice memory dice= getDice(from,tokenId );
        dices[to][tokenId ] = encode(dice);
        dices[from][tokenId ]= encode(Dice(0,0));
        diceIndexToOwner[tokenId ]=to;
        _transfer(from, to, tokenId );
    }

  function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        require(from != to, "Can not transfer myself");
        Dice memory dice= getDice(from,tokenId );
        dices[to][tokenId ] = encode(dice);
        dices[from][tokenId ]= encode(Dice(0,0));
        diceIndexToOwner[tokenId ]=to;
        _safeTransfer(from, to, tokenId, _data);
    }  

  function approveMarketPlace(address to, uint256 tokenId) external onlyDiceMarketPlaceOrOwner {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
         _approve(to,tokenId);
  }

  function setBoxNFT(address _boxNFT) public onlyOwner{
    boxNFT=_boxNFT;
  }  

  function setDiceMarketPlace(address _diceMarketPlace) public onlyOwner{
    diceMarketPlace=_diceMarketPlace;
  }  

  /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner whenNotPaused {
       _pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused {
       _unpause();
    }

     string public baseURI;
    using StringsUpgradeable for uint256;
    function setBaseURI(string memory _baseURI) public onlyOwner{
      baseURI=_baseURI;
    }  
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        address sender=ownerOf(tokenId);
        Dice memory dice = getDice(sender,tokenId);
        string memory json=".json";
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI,dice.diceType.toString(),json))  : "";
    }

    mapping (uint256 => address) public diceIndexToOwner;  
    function updateDiceIndexToOwner(uint256 nftId,address owner) public onlyOwner  {
        diceIndexToOwner[nftId]= owner;
    }

    function setOperator(address _operator) public onlyOwner{
    operator = _operator;
    }  

   address public operator;
    modifier onlyOperatorOrOwner {
      require(msg.sender == operator || msg.sender == owner());
      _;
    }   
}