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
import "./IBEP20.sol";
contract CharacterNFT is ERC721Upgradeable, ERC721BurnableUpgradeable, OwnableUpgradeable, PausableUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter public _tokenIds;
    
    // using CharactersUpgradeable for Character;
    using MathUpgradeable for uint256;
    using MathUpgradeable for uint48;
    using MathUpgradeable for uint32;
    using MathUpgradeable for uint16;
    uint256 public version;
    struct Character {
        uint256 id;
        uint256 characterType;
        uint256 rank;
        uint256 star;
        uint256 exp;
        uint256 isDeleted;
        // uint256[] abilities;
    }
    event logCreateRandomThreeCharacter(uint256 nftId, uint256 characterType, uint256 rank, uint256 star, uint256 exp);

    // namely the ERC721 instances for name symbol decimals etc
    function initialize() public initializer {
        __ERC721_init("Character NFT BPLUS", "CHNB");
        __Ownable_init();
    }
    address public academyUpStar;
    modifier onlyAcademyUpStarOrOwner {
      require(msg.sender == academyUpStar || msg.sender == owner());
      _;
    }

    address public evolutionUpRank;
    modifier onlyEvolutionUpRankOrOwner {
      require(msg.sender == evolutionUpRank || msg.sender == owner());
      _;
    }

    mapping(address => mapping(uint256 => uint256)) public characters;// address - id - details // cach lay details = characters[address][characterId]
    mapping (uint256 => address) public characterIndexToOwner;

    address public boxNFT;
    modifier onlyBoxNFTOrOperatorOrOwner {
      require(msg.sender == boxNFT || msg.sender == owner()||msg.sender == operator);
      _;
    }

    address public characterMarketPlace;
    modifier onlyCharacterMarketPlaceOrOwner {
      require(msg.sender == characterMarketPlace || msg.sender == owner());
      _;
    }

  function createCharacter(address owner,uint256 characterType, uint256 rank, uint256  star,uint256  exp) public onlyBoxNFTOrOperatorOrOwner  returns (uint256) {
        _tokenIds.increment();
        uint256 newCharacterId = _tokenIds.current();
        //we can call mint from the ERC721 contract to mint our nft token
        // _safeMint(msg.sender, newCharacterId);
        _safeMint(owner, newCharacterId);
        characters[owner][newCharacterId] = encode(Character(newCharacterId,characterType,rank,star,exp,0));
        characterIndexToOwner[newCharacterId]=owner;
        return newCharacterId;
    }

  function updateCharacter(address owner,uint256 nftId, uint256 id, uint256 characterType, uint256 rank, uint256  star,uint256 exp,uint256 isDeleted) public onlyOperatorOrOwner returns (uint256) {
        characters[owner][nftId] = encode(Character(id,characterType,rank,star,exp,isDeleted));
        return nftId;
    }

  // function upStar(address _owner,uint256 _nftId) public onlyAcademyUpStarOrOwner {
  //   Character memory character= getCharacter(_owner,_nftId);
  //   character.star=character.star+1;
  //   character.exp=0;
  //   characters[_owner][_nftId] = encode(character);
  // }

   function upStarV2(address _owner,uint256 _nftId, uint _star) public onlyAcademyUpStarOrOwner {
    Character memory character= getCharacter(_owner,_nftId);
    require(character.star + _star <= 5 , 'Invalid number of stars'); 
    character.star=character.star + _star;
    character.exp=0;
    characters[_owner][_nftId] = encode(character);
  }

  function upRank(address _owner,uint256 _mainNftId, uint256[] memory _materialNftIds) public onlyEvolutionUpRankOrOwner {
    Character memory character= getCharacter(_owner,_mainNftId);
    character.rank=character.rank+1;
    character.star=1;
    character.exp=0;
    characters[_owner][_mainNftId] = encode(character);
    for(uint i = 0; i < _materialNftIds.length; i++){
       characters[_owner][_materialNftIds[i]]=encode(Character(_materialNftIds[i],0,0,0,0,1));
    }
  }

  // function upExp(address _owner,uint256 _nftId,uint256 _exp) public onlyAcademyUpStarOrOwner  {
  //   Character memory character= getCharacter(_owner,_nftId);
  //   character.exp=character.exp + _exp;
  //   characters[_owner][_nftId] = encode(character);
  // }

  function getCharacter(address owner, uint256 id) public view returns (Character memory _character) {
    uint256 details= characters[owner][id];
    _character.id = uint256(uint48(details>>100));
    _character.characterType = uint256(uint16(details>>148));
    _character.rank = uint256(uint16(details>>164));
    _character.star =uint256(uint16(details>>180));
    _character.exp =uint256(uint32(details>>196));
    _character.isDeleted =uint256(uint8(details>>228));
  }
  
function getCharacterPublic(address _owner, uint256 _id) public view returns (
        uint256 id,
        uint256 characterType,
        uint256 rank,
        uint256 star,
        uint256 exp,
        uint256 isDeleted
        ) {
    Character memory _character= getCharacter(_owner,_id);
    id=_character.id;
    characterType=_character.characterType;
    rank=_character.rank;
    star=_character.star;
    exp=_character.exp;
    isDeleted=_character.isDeleted;
  }

  function encode(Character memory character) public pure returns (uint256) {
  // function encode(Character memory character)  external view returns  (uint256) {
    uint256 value;
    value = uint256(character.id);
    value |= character.id << 100;
    value |= character.characterType << 148;
    value |= character.rank << 164;
    value |= character.star << 180;
    value |= character.exp << 196;
    value |= character.isDeleted << 228;
    return value;
  }



  function initByOwner(address _academyUpStar, address _evolutionUpRank,  address _characterMarketPlace, address _boxNFT) public onlyOwner{
    academyUpStar=_academyUpStar;
    evolutionUpRank=_evolutionUpRank;
    characterMarketPlace=_characterMarketPlace;
    boxNFT=_boxNFT;
  }

  function getCharacterOfSender(address sender) external view returns (Character[] memory ) {
        uint range=_tokenIds.current();
        uint i=1;
        uint index=0;
        uint x=0;
        for(i; i <= range; i++){
          Character memory character = getCharacter(sender,i);
          if(character.id !=0){
            index++;
          }
        }
        Character[] memory result = new Character[](index);
        i=1;
        for(i; i <= range; i++){
          Character memory character = getCharacter(sender,i);
          if(character.id !=0){
            result[x] = character;
            x++;
          }
        }
        return result;
  }

function transfer(uint256 _nftId, address _target)
        external whenNotPaused
    {
        require(_exists(_nftId), "Non existed NFT");
        require(
            ownerOf(_nftId) == msg.sender || getApproved(_nftId) == msg.sender,
            "Not approved"
        );
        require(_target != address(0), "Invalid address");
        if(msg.sender != characterMarketPlace){
          require(_target == characterMarketPlace, "function only support for Marketplace");
          require(msg.sender != _target, "Can not transfer myself");
        }
        Character memory character= getCharacter(ownerOf(_nftId),_nftId);
        // star will start = 1, exp will start = 0
        // character.star=1;
        // character.exp=0;

        characters[_target][_nftId] = encode(character);
        characters[ownerOf(_nftId)][_nftId]= encode(Character(0,0,0,0,0,0));
        characterIndexToOwner[_nftId]=_target;
        _transfer(ownerOf(_nftId), _target, _nftId);
    }

  function transferFrom(
        address from,
        address to,
        uint256 tokenId 
    )
        public  virtual override  whenNotPaused 
    {
      
        require(isTransfer == true, "Can not transfer");
        require(_exists(tokenId ), "Non existed NFT");
        require(ownerOf(tokenId ) == from, "Only owner NFT can transfer");
        require(from != to, "Can not transfer myself");
        require(
            ownerOf(tokenId ) == msg.sender || getApproved(tokenId ) == msg.sender,
            "Not approved"
        );
        require(to != address(0), "Invalid address");

        Character memory character= getCharacter(from,tokenId );
        characters[to][tokenId ] = encode(character);
        characters[from][tokenId ]= encode(Character(0,0,0,0,0,0));
        characterIndexToOwner[tokenId ]=to;
        _transfer(from, to, tokenId );
    }

  function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(isTransfer == true, "Can not transfer");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        require(from != to, "Can not transfer myself");
        Character memory character= getCharacter(from,tokenId );
        characters[to][tokenId ] = encode(character);
        characters[from][tokenId ]= encode(Character(0,0,0,0,0,0));
        characterIndexToOwner[tokenId ]=to;
        _safeTransfer(from, to, tokenId, _data);
    }  

  function approveMarketPlace(address to, uint256 tokenId) external onlyCharacterMarketPlaceOrOwner {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
         _approve(to,tokenId);
  }

  function approveEvolutionUpRank(address to, uint256 tokenId) external onlyEvolutionUpRankOrOwner {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
         _approve(to,tokenId);
  }

  function createCharacterWhileList(address[] memory owners,uint256 characterType) public onlyOwner {
        for (uint i=0; i<owners.length; i++) {
        _tokenIds.increment();
        uint256 newCharacterId = _tokenIds.current();
        _safeMint(owners[i], newCharacterId);
        characters[owners[i]][newCharacterId] = encode(Character(newCharacterId,characterType,1,1,0,0)); // 1,2,3,7
        characterIndexToOwner[newCharacterId]=owners[i];
        }
    }

function updateCharacterIndexToOwner(uint256 nftId,address owner) public onlyOwner  {
        characterIndexToOwner[nftId]= owner;
    }

  function setVersion(uint256 _version) public onlyOwner {
    version=_version;
  }

  function setBoxNFT(address _boxNFT) public onlyOwner{
    boxNFT=_boxNFT;
  }  

  function setEvolutionUpRank(address _evolutionUpRank) public onlyOwner{
    evolutionUpRank=_evolutionUpRank;
  }  

  function setAcademyUpStar(address _academyUpStar) public onlyOwner{
    academyUpStar=_academyUpStar;
  }

  function setCharacterMarketPlace(address _characterMarketPlace) public onlyOwner{
    characterMarketPlace=_characterMarketPlace;
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
        Character memory character = getCharacter(sender,tokenId);
        string memory json=".json";
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI,character.characterType.toString(),"_",character.rank.toString(),json))  : "";
    }

  function setOperator(address _operator) public onlyOwner{
    operator = _operator;
    }  


   address public operator;
    modifier onlyOperatorOrOwner {
      require(msg.sender == operator || msg.sender == owner());
      _;
    }

    bool isTransfer;
    function setIsTransfer(bool _isTransfer) public onlyOwner{
    isTransfer=_isTransfer;
  }

  IBEP20 public token;
  function setIBEP20(address _tokenBEP20) public onlyOwner{
        token = IBEP20(_tokenBEP20);
  }
  function withdrawToken() external onlyOwner {
        uint256 _balance = token.balanceOf(address(this));
        token.transfer(msg.sender, _balance);
    }

  mapping (uint256 => uint256) public feeTransferByRank;
  function setFeeTransferByRank(uint256 rank,uint256 feeTransfer) public onlyOwner{
    feeTransferByRank[rank]= feeTransfer;
  }  
  function getFeeTransferByRank(uint256 rank) external view returns (uint256  _feeTransfer){
    _feeTransfer = feeTransferByRank[rank];
  } 

  function transferWithCost(uint256 _nftId, address _target, uint256 _fee)
        external whenNotPaused
    {
        require(_exists(_nftId), "Non existed NFT");
        require(
            ownerOf(_nftId) == msg.sender || getApproved(_nftId) == msg.sender,
            "Not approved"
        );
        require(_target != address(0), "Invalid address");
        if(msg.sender != characterMarketPlace){
          require(msg.sender != _target, "Can not transfer myself");
        }
        
        Character memory character= getCharacter(ownerOf(_nftId),_nftId);

        token.approve(address(this),_fee);
        token.transferFrom(msg.sender, address(this), _fee);

        require(feeTransferByRank[character.rank] == _fee, "Fee not correct");

        characters[_target][_nftId] = encode(character);
        characters[ownerOf(_nftId)][_nftId]= encode(Character(0,0,0,0,0,0));
        characterIndexToOwner[_nftId]=_target;
        _transfer(ownerOf(_nftId), _target, _nftId);
    }     
}