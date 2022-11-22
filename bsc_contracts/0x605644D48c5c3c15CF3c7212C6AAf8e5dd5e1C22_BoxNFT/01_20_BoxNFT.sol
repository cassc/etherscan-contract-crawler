// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "./CharacterNFT.sol";
import "./DiceNFT.sol";
import "./Utils.sol";
// import "./BuildingNFT.sol";
// import "./sol";

contract BoxNFT is ERC721Upgradeable, ERC721BurnableUpgradeable, OwnableUpgradeable, PausableUpgradeable{
    using MathUpgradeable for uint256;
    using MathUpgradeable for uint48;
    using MathUpgradeable for uint32;
    using MathUpgradeable for uint16;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter public _tokenIds;
    
    struct Box {
        uint256 id;
        uint256 rank;
    }
    CharacterNFT public characterNFT;
    DiceNFT public diceNFT;
    
    function initialize() public initializer {
      __ERC721_init("Box NFT BPLUS", "BONB");
      openBoxActive=false;
      __Ownable_init();
    }
    
    mapping(address => mapping(uint256 => Box)) public boxes;// address - id - details // cach lay details = boxes[address][boxId]
    
    address public boxMarketPlace;
    modifier onlyBoxMarketPlaceOrOwner {
      require(msg.sender == boxMarketPlace || msg.sender == owner());
      _;
    }

    address public boxNFTRound;
    modifier onlyBoxNFTRoundOrOwner {
      require(msg.sender == boxNFTRound || msg.sender == owner());
      _;
    }
    bool public openBoxActive;
    event randomData(uint256 characterId, uint256 diceId, uint256 randomCharacter,uint256 randomDice);
    
    

    function initByOwner(CharacterNFT _characterNFT, DiceNFT _diceNFT, address _boxNFTRound, address _boxMarketPlace, address _operator) public  onlyOwner {
        characterNFT = _characterNFT;
        diceNFT = _diceNFT;
        boxNFTRound=_boxNFTRound;
        boxMarketPlace=_boxMarketPlace;
        operator=_operator;
    }

  function createBox(address owner,uint256 rank) public onlyOperatorOrOwner returns (uint256) {
        _tokenIds.increment();
        uint256 newBoxId = _tokenIds.current();
        _safeMint(owner, newBoxId);
        boxes[owner][newBoxId] = Box(newBoxId,rank);
        return newBoxId;
    }
  
  function getBoxPublic(address _owner, uint256 _id) public view returns (
        uint256 id,
        uint256 rank
        ) {
    Box memory _box= boxes[_owner][_id];
    id=_box.id;
    rank=_box.rank;
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
        if(msg.sender != boxMarketPlace){
          require(msg.sender != _target, "Can not transfer myself");
        }
        Box memory box=boxes[ownerOf(_nftId)][_nftId];
        // star will start = 1, exp will start = 0

        boxes[_target][_nftId] = box;
        boxes[ownerOf(_nftId)][_nftId]= Box(0,0);
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
        require(ownerOf(tokenId ) == from, "Only owner NFT can transfer");
        require(
            ownerOf(tokenId ) == msg.sender || getApproved(tokenId ) == msg.sender,
            "Not approved"
        );
        require(from != to, "Can not transfer myself");
        require(to != address(0), "Invalid address");

        Box memory box= boxes[from][tokenId];
        boxes[to][tokenId ] = box;
        boxes[from][tokenId ]= Box(0,0);
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
        Box memory box= boxes[from][tokenId];
        boxes[to][tokenId ] = box;
        boxes[from][tokenId ]= Box(0,0);
        _safeTransfer(from, to, tokenId, _data);
    }    

  function approveMarketPlace(address to, uint256 tokenId) external whenNotPaused onlyBoxMarketPlaceOrOwner {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
         _approve(to,tokenId);
  }


function buyBox(address buyer,uint256 rank) external whenNotPaused onlyBoxNFTRoundOrOwner returns (uint256) {
        _tokenIds.increment();
        uint256 newBoxId = _tokenIds.current();
        _safeMint(buyer, newBoxId);
        boxes[buyer][newBoxId] =Box(newBoxId,rank);
        return newBoxId;
    }

function openBox(uint256 tokenId) external whenNotPaused returns (uint256 characterId,uint256 diceId,uint256 randomCharacter,uint256 randomDice){
        require(openBoxActive==true, "openBox not active");
        Box memory box = boxes[msg.sender][tokenId];
        boxes[msg.sender][tokenId]= Box(0,0);
        uint256 rank=box.rank;
        uint256 rankSelect=1;
        uint256 typeCharacter = 1;
        diceId=0;
        randomDice=0;
        randomCharacter=0;
        if(rank==11){
          randomCharacter = utils.random(1,100);
          uint256 randomRank = utils.random(1,100);
          if(1<= randomCharacter && randomCharacter<=10){
                typeCharacter=1;
           } else if (11 <= randomCharacter && randomCharacter<=20) {
                typeCharacter=2;
           } else if (21 <= randomCharacter && randomCharacter<=30) {
                typeCharacter=3;
           } else if (31 <= randomCharacter && randomCharacter<=40) {
                typeCharacter=4;
            }else if (41 <= randomCharacter && randomCharacter<=50) {
                typeCharacter=1;
           } else if (51 <= randomCharacter && randomCharacter<=60) {
                typeCharacter=6;
            } else if (61 <= randomCharacter && randomCharacter<=70) {
                typeCharacter=7;
           } else if (71 <= randomCharacter && randomCharacter<=80) {
                typeCharacter=8;
            } else if (81 <= randomCharacter && randomCharacter<=90) {
                typeCharacter=9;
           } else if (91 <= randomCharacter && randomCharacter<=100) {
                typeCharacter=9;
           }  
          if(1<= randomRank && randomRank<=82){
            rankSelect=1;
          } else if(83<= randomRank && randomRank<=95){
            rankSelect=2;
          }else if(96<= randomRank && randomRank<=100){
            rankSelect=3;
          }
          characterId=characterNFT.createCharacter(msg.sender,typeCharacter,rankSelect,1,0);

        }else{
        uint256 value = uint256(tokenId*block.timestamp);
            // uint256 randomHaveDice =  (value << 10) % 100+1;
            uint256 randomRank = (value << 20) % 100+1;
            bool haveDice=false;
            uint256 typeDice=0;
          
            // Random rank to get rank design
            if(rank==1){
              if(1<= randomRank && randomRank<=83){
                rankSelect=1; // 80% rank D
              }else{
                rankSelect=2; // 20% rank C
              }
            }else if(rank==2){
              if(1<= randomRank && randomRank<=75){
                rankSelect=2; // 75% rank C
              }else {
                rankSelect=3; // 25% rank B
              }
            }else if(rank==3){
              rankSelect=3;
            }

            // Random rank to get dice design
            
            if(tokenId<2870){
              haveDice=true;
            }

            if(rankSelect==1){
              randomCharacter = (value << 20)%100+1;
              if(1<= randomCharacter && randomCharacter<=10){
                typeCharacter=1;
              } else if (11 <= randomCharacter && randomCharacter<=20) {
                typeCharacter=2;
              } else if (21 <= randomCharacter && randomCharacter<=30) {
                typeCharacter=3;
              } else if (31 <= randomCharacter && randomCharacter<=40) {
                typeCharacter=4;
              }else if (41 <= randomCharacter && randomCharacter<=50) {
                typeCharacter=1;
              } else if (51 <= randomCharacter && randomCharacter<=60) {
                typeCharacter=2;
              } else if (61 <= randomCharacter && randomCharacter<=70) {
                typeCharacter=7;
              } else if (71 <= randomCharacter && randomCharacter<=80) {
                typeCharacter=8;
              } else if (81 <= randomCharacter && randomCharacter<=90) {
                typeCharacter=9;
              } else if (91 <= randomCharacter && randomCharacter<=100) {
                typeCharacter=9;
              }  
              characterId=characterNFT.createCharacter(msg.sender,typeCharacter,rankSelect,1,0);
              randomDice = (value << 30)%100+1;
              if(haveDice==true){
                if(1<= randomDice && randomDice<=20){
                  typeDice=11;
                } else if (21 <= randomDice && randomDice <= 60) {
                  typeDice=12;
                } else if (61 <= randomDice && randomDice<=100) {
                  typeDice=13;
                }
                diceId=diceNFT.createDice(msg.sender,typeDice);
              }
            }
            else if(rankSelect==2){
                randomCharacter = (value << 20)%100+1;
              if(1<= randomCharacter && randomCharacter<=10){
                typeCharacter=1;
              } else if (11 <= randomCharacter && randomCharacter<=20) {
                typeCharacter=2;
              } else if (21 <= randomCharacter && randomCharacter<=30) {
                typeCharacter=3;
              } else if (31 <= randomCharacter && randomCharacter<=40) {
                typeCharacter=4;
              }else if (41 <= randomCharacter && randomCharacter<=50) {
                typeCharacter=1;
              } else if (51 <= randomCharacter && randomCharacter<=60) {
                typeCharacter=2;
              } else if (61 <= randomCharacter && randomCharacter<=70) {
                typeCharacter=7;
              } else if (71 <= randomCharacter && randomCharacter<=80) {
                typeCharacter=8;
              } else if (81 <= randomCharacter && randomCharacter<=90) {
                typeCharacter=9;
              } else if (91 <= randomCharacter && randomCharacter<=100) {
                typeCharacter=9;
              } 
              characterId=characterNFT.createCharacter(msg.sender,typeCharacter,rankSelect,1,0);
              randomDice = (value << 10)%100+1;
              if(haveDice==true){
                if(1<= randomDice && randomDice<=10){
                  typeDice=2;
                } else if (11 <= randomDice && randomDice <= 55) {
                  typeDice=14;
                } else if (56 <= randomDice && randomDice<=100) {
                  typeDice=15;
                }
                diceId=diceNFT.createDice(msg.sender,typeDice);
              }
            }

            else if(rankSelect==3){
                randomCharacter = (value << 20)%100+1;
              if(1<= randomCharacter && randomCharacter<=10){
                typeCharacter=1;
              } else if (11 <= randomCharacter && randomCharacter<=20) {
                typeCharacter=2;
              } else if (21 <= randomCharacter && randomCharacter<=30) {
                typeCharacter=3;
              } else if (31 <= randomCharacter && randomCharacter<=40) {
                typeCharacter=4;
              }else if (41 <= randomCharacter && randomCharacter<=50) {
                typeCharacter=1;
              } else if (51 <= randomCharacter && randomCharacter<=60) {
                typeCharacter=2;
              } else if (61 <= randomCharacter && randomCharacter<=70) {
                typeCharacter=7;
              } else if (71 <= randomCharacter && randomCharacter<=80) {
                typeCharacter=8;
              } else if (81 <= randomCharacter && randomCharacter<=90) {
                typeCharacter=9;
              } else if (91 <= randomCharacter && randomCharacter<=100) {
                typeCharacter=9;
              }
              characterId=characterNFT.createCharacter(msg.sender,typeCharacter,rankSelect,1,0);
              randomDice = (value << 10)%100+1;
              if(haveDice==true){
                if(1<= randomDice && randomDice<=10){
                  typeDice=2;
                } else if (11 <= randomDice && randomDice <= 55) {
                  typeDice=14;
                } else if (56 <= randomDice && randomDice<=100) {
                  typeDice=15;
                }
                diceId=diceNFT.createDice(msg.sender,typeDice);
              }
            }

            else if(rankSelect==4){
                randomCharacter = (value << 20)%100+1;
              if(1<= randomCharacter && randomCharacter<=10){
                typeCharacter=1;
              } else if (11 <= randomCharacter && randomCharacter<=20) {
                typeCharacter=2;
              } else if (21 <= randomCharacter && randomCharacter<=30) {
                typeCharacter=3;
              } else if (31 <= randomCharacter && randomCharacter<=40) {
                typeCharacter=4;
              }else if (41 <= randomCharacter && randomCharacter<=50) {
                typeCharacter=1;
              } else if (51 <= randomCharacter && randomCharacter<=60) {
                typeCharacter=2;
              } else if (61 <= randomCharacter && randomCharacter<=70) {
                typeCharacter=7;
              } else if (71 <= randomCharacter && randomCharacter<=80) {
                typeCharacter=8;
              } else if (81 <= randomCharacter && randomCharacter<=90) {
                typeCharacter=9;
              } else if (91 <= randomCharacter && randomCharacter<=100) {
                typeCharacter=9;
              } 
              characterId=characterNFT.createCharacter(msg.sender,typeCharacter,rankSelect,1,0);
              randomDice = (value << 10)%100+1;
              if(haveDice==true){
                if(1<= randomDice && randomDice<=10){
                  typeDice=2;
                } else if (11 <= randomDice && randomDice <= 55) {
                  typeDice=14;
                } else if (56 <= randomDice && randomDice<=100) {
                  typeDice=15;
                }
                diceId=diceNFT.createDice(msg.sender,typeDice);
              }
            }
          emit randomData(
              typeCharacter,
              typeDice,
              randomCharacter,
              randomDice
            );
        }
        if(minBoxAccessory <= tokenId && tokenId <= maxBoxAccessory){
          if(rank>=5){
            rank=1;
          }
          accessories[tokenId] = Accessory(msg.sender,characterId,rank);
        }
        _burn(tokenId);
    }

  function getBoxesOfSender(address sender) external view returns (Box[] memory ) {
        uint range=_tokenIds.current();
        uint i=1;
        uint index=0;
        uint x=0;
        for(i; i <= range; i++){
          if(boxes[sender][i].id !=0){
            index++;
          }
        }
        Box[] memory result = new Box[](index);
        i=1;
        for(i; i <= range; i++){
          if(boxes[sender][i].id !=0){
            result[x] = boxes[sender][i];
            x++;
          }
        }
        return result;
  }  

  function setBoxNFTRound(address _boxNFTRound) public onlyOwner{
    boxNFTRound=_boxNFTRound;
  }

  function setOpenBoxActive(bool _openBoxActive) public onlyOwner{
    openBoxActive=_openBoxActive;
  }

  function setCharacterNFT(CharacterNFT _characterNFT) public onlyOwner{
    characterNFT=_characterNFT;
  }

  function setBoxMarketPlace(address _boxMarketPlace) public onlyOwner{
    boxMarketPlace=_boxMarketPlace;
  }

  function setOperator(address _operator) public onlyOwner{
    operator = _operator;
  }  

  function withdraw(address _target, uint256 _amount) external onlyOwner {
        require(_target != address(0), "Invalid address");
        payable(_target).transfer(_amount);
    }

  function updateBox(address owner,uint256 nftId, uint256 id, uint256 rank) public onlyOperatorOrOwner returns (uint256) {
        boxes[owner][nftId] =Box(id,rank);
        return nftId;
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
        Box memory box= boxes[sender][tokenId];
        string memory rank="";
        string memory json=".json";
        if(box.rank==1){
          rank="d";
        }
        else if(box.rank==2){
          rank="c";
        }
        else if(box.rank==3){
          rank="b";
        }
        else if(box.rank==4){
          rank="a";
        }
        else if(box.rank==5){
          rank="s";
        }
        else if(box.rank==6){
          rank="ss";
        }
        else if(box.rank==7){
          rank="sss";
        }
        else if(box.rank==11){
          rank="random";
        }
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI,rank,json))  : "";
    }

    address public operator;
    modifier onlyOperatorOrOwner {
      require(msg.sender == operator || msg.sender == owner());
      _;
    }

    Utils public utils;
    function setUtils(Utils _utils) public onlyOwner{
        utils = _utils;
    }

    struct Accessory {
        address owner;
        uint256 characterNft;
        uint256 typeAccessory;


    }
    mapping(uint256 => Accessory) public accessories; //character - type accessories
    uint256 public minBoxAccessory;
    uint256 public maxBoxAccessory;

  function setMinBoxAccessory(uint256 _minBoxAccessory) public onlyOwner{
    minBoxAccessory=_minBoxAccessory;
  }

  function setMaxBoxAccessory(uint256 _maxBoxAccessory) public onlyOwner{
    maxBoxAccessory=_maxBoxAccessory;
  }

  function getAccessory(uint256 _id) public view returns (
        address _owner,
        uint256 _characterNft,
        uint256 _typeAccessory
        ) {
        _owner = accessories[_id].owner;
        _characterNft = accessories[_id].characterNft;
        _typeAccessory = accessories[_id].typeAccessory;
  }


}