// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;




import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


struct ActOneConfig {
  uint32 startTime;
  uint32 endTime;
 
}

struct ActTwoConfig {
  uint32 startTime;
  uint32 endTime;
  
}

struct PublicSaleConfig {
  uint32 startTime;
  uint32 endTime;
 }


  contract BelowBored is Ownable, ERC721, ReentrancyGuard {
    using SafeCast for uint256;
        
    uint public maxPublicSupply = 10000;
    uint public maxSupply = 10169;
    uint public _reserveTokenId = maxPublicSupply;

    string internal baseTokenURI = "https://ipfssite.com/";
    using Counters for Counters.Counter;
    Counters.Counter private _tokenId;
 

    uint public price = 0.15 ether;


    //Percentages//

    //Laughing Ape Company 
    uint public p1 = 3737;
    //Founder 
    uint public p2 = 2500;
    //Partner
    uint public p3 = 1000;
    //Project Manager
    uint public p4 = 813;
    //Dev
    uint public p5 = 700;
    //Marketing
    uint public p6 = 100;
    //Community Manager
    uint public p7 = 600;
    //Architect
    uint public p8 = 500;
    //BK
    uint public p9 = 50;


     
    //Wallets//

    //Laughing Ape
    address public a1 = 0x0000000000000000000000000000000000000000;
    //Founder
    address public a2 = 0x0000000000000000000000000000000000000000;
    //Project Manager
    address public a3 = 0x0000000000000000000000000000000000000000;
    //Partner
    address public a4 = 0x0000000000000000000000000000000000000000;
    //Dev
    address public a5 = 0x0000000000000000000000000000000000000000;
    //Marketing
    address public a6 = 0x0000000000000000000000000000000000000000;
    //Community Manager
    address public a7 = 0x0000000000000000000000000000000000000000;
    //Architect
    address public a8 = 0x0000000000000000000000000000000000000000;
    //BK
    address public a9 = 0x0000000000000000000000000000000000000000;
    

   // EVENTS
  event ActOneConfigUpdated();
  event ActTwoConfigUpdated();
  event PublicSaleConfigUpdated();


  bool public isDeusXClaimActive;

    ActOneConfig public  actoneConfig;
    ActTwoConfig public acttwoConfig;
    PublicSaleConfig public  publicsaleConfig;

  mapping(address => uint8) public deusxAllowance;
 mapping(address => bool) public isAllowlisted;
   constructor(
   
  ) ERC721("Below Bored", "BBC") {
   
     
      actoneConfig = ActOneConfig({
      startTime: 1660068000, 
      endTime: 1660072140 
      });
     acttwoConfig = ActTwoConfig({
      startTime: 1660072142, 
      endTime: 1660076280 
     
    });
     publicsaleConfig = PublicSaleConfig({
      startTime: 1660076282, 
      endTime: 1660158000
     
    });
    
  }




 //Act One

  
    function ActOneMint(uint _amount) external payable {
        ActOneConfig memory _config = actoneConfig;
 require(
      block.timestamp >= _config.startTime && block.timestamp < _config.endTime,
      "Act one is not active"
    );
    require(_amount > 0, "You must mint at least 1 NFT");
        require(_tokenId.current() + _amount <= maxPublicSupply, "Max public supply exceeded");
        
        require(price * _amount == msg.value, "Wrong ETH amount");
  
       require(isAllowlisted[msg.sender], "Only Allow Listed users Authorized");
                     
        _mintBored(msg.sender,  _amount);
    
    }

  //Act Two
  
    function ActTwoMint(uint _amount) external payable {
          ActTwoConfig memory _config = acttwoConfig;
 require(
      block.timestamp >= _config.startTime && block.timestamp < _config.endTime,
      "Presale is not active"
    );
         require(_tokenId.current() + _amount <= maxPublicSupply, "Max public supply exceeded");
        
        require(price * _amount == msg.value, "Wrong ETH amount");

        
       require(isAllowlisted[msg.sender], "Only Allow Listed users Authorized");
    

        _mintBored(msg.sender, _amount);
    
    }

  //Public Mint

   function PublicMint( uint _amount) external payable {
          PublicSaleConfig memory _config = publicsaleConfig;
 require(
      block.timestamp >= _config.startTime && block.timestamp < _config.endTime,
      "Public Sale is not active"
    );
       require(_tokenId.current() + _amount <= maxPublicSupply, "Max public supply exceeded");
        require(price * _amount == msg.value, "Wrong ETH amount");

                  
        _mintBored(msg.sender, _amount);
    

   }

   //DeusX Claim
function claimDeusX() external {
    require(isDeusXClaimActive, "Airdrop is inactive");
    uint _allowance = deusxAllowance[msg.sender];
    require(_allowance > 0, "You have no airdrops to claim");
    require(_tokenId.current() + _allowance <= maxPublicSupply, "Max public supply exceeded");
    
      
      _mintBored(msg.sender, _allowance);
    
    deusxAllowance[msg.sender] = 0;
  }
  
  function devReserve(address _to, uint _amount) external onlyOwner {
        require(_reserveTokenId + _amount <= maxSupply, "Max reserve supply exceeded");
    for (uint i = 0; i < _amount; i++) {
      _reserveTokenId++;
      _safeMint(_to, _reserveTokenId);
    }
  }
 
 function _mintBored(address _to, uint _amount) internal {
         for (uint i = 0; i < _amount; i++) {
        _tokenId.increment();
            _safeMint(_to, _tokenId.current());
        }
    }


    //Sale Config
 function configureActOne(uint256 startTime, uint256 endTime)
    external
    onlyOwner
  {
    uint32 _startTime = startTime.toUint32();
    uint32 _endTime = endTime.toUint32();

    require(0 < _startTime, "Invalid time");
    require(_startTime < _endTime, "Invalid time");
        
    actoneConfig.startTime = _startTime;
    actoneConfig.endTime = _endTime;

    emit ActOneConfigUpdated();
  }



  function configureActTwo(uint256 startTime, uint256 endTime)
    external
    onlyOwner
  {
    uint32 _startTime = startTime.toUint32();
    uint32 _endTime = endTime.toUint32();

    require(0 < _startTime, "Invalid time");
    require(_startTime < _endTime, "Invalid time");
        
    acttwoConfig.startTime = _startTime;
    acttwoConfig.endTime = _endTime;

    emit ActTwoConfigUpdated();
  }
 

 function configurePublicSale(uint256 startTime, uint256 endTime)
    external
    onlyOwner
  {
    uint32 _startTime = startTime.toUint32();
    uint32 _endTime = endTime.toUint32();

    require(0 < _startTime, "Invalid time");
    require(_startTime < _endTime, "Invalid time");
        
    publicsaleConfig.startTime = _startTime;
    publicsaleConfig.endTime = _endTime;

    emit PublicSaleConfigUpdated();
  }
  
//DeusX Stuff
function setDeusxClaimActive(bool _state) public onlyOwner {
    isDeusXClaimActive = _state;
  }
 
  function setDeusxClaimAllowance(address[] calldata _users, uint8[] calldata _allowances) public onlyOwner {
      require(_users.length == _allowances.length, "Length mismatch");
      for(uint i = 0; i < _users.length; i++) {
          deusxAllowance[_users[i]] = _allowances[i];
      }
  }




    //Wallets
  function setMembersAddresses(address[] memory _a) external onlyOwner {
        a1 = _a[0];
        a2 = _a[1];
        a3 = _a[2];
        a4 = _a[3];
        a5 = _a[4];
        a6 = _a[5];
        a7 = _a[6];
        a8 = _a[7];
        a9 = _a[8];
       
    }



  //WITHDRAW FUNCTIONS
  function withdrawTeam() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(payable(a1).send((balance /10000) * p1));
        require(payable(a2).send((balance /10000) * p2));
        require(payable(a3).send((balance /10000) * p3));
        require(payable(a4).send((balance /10000) * p4));
        require(payable(a5).send((balance /10000) * p5));
        require(payable(a6).send((balance /10000) * p6));
        require(payable(a7).send((balance /10000) * p7));
        require(payable(a8).send((balance /10000) * p8));
        require(payable(a9).send((balance /10000) * p9));
    }

   

   
  function withdrawOwner() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }


    //Supply
     function totalSupply() public view returns(uint) {
     return _tokenId.current() + _reserveTokenId - maxPublicSupply;
   }



//TOKEN LOCATION
   

   function setBaseTokenURI(string calldata _uri) external onlyOwner {
        baseTokenURI = _uri;
    }
   

   function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    //PRICE

      function setPrice(uint _newPrice) external onlyOwner {
        price = _newPrice;
    }



function setMembersPercentages(uint[] memory _p) external onlyOwner {
        p1 = _p[0];
        p2 = _p[1];
        p3 = _p[2];
        p4 = _p[3];
        p5 = _p[4];
        p6 = _p[5];
        p7 = _p[6];
        p8 = _p[7];
        p9 = _p[8];
       
    }

//AllowList 


 function allowlist(address[] calldata _users) public onlyOwner {
      for (uint i = 0; i < _users.length; i++) {
          isAllowlisted[_users[i]] = true;
      }
  }
function unAllowlist(address[] calldata _users) public onlyOwner {
     for(uint i = 0; i < _users.length; i++) {
          isAllowlisted[_users[i]] = false;
     }



  }
  }