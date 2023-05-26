// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Counters.sol";
import "./PaymentSplitter.sol";
import "./Pausable.sol";
import "./ERC721A.sol";

contract BunnyBuddies is ERC721A, Pausable, PaymentSplitter {

 struct PresaleConfig {
        uint256 startTime;
        uint256 duration;
        uint256 maxCount;
    }
    struct SaleConfig {
        uint256 startTime;
        uint256 maxCount;
    }
    uint256 public maxGiftSupply;
    uint256 public giftCount;
    uint256 public price;
    bool public isBurnEnabled;
    bool private isPresale;
    string public baseURI;
    PresaleConfig public presaleConfig;
    SaleConfig public saleConfig;
    Counters.Counter private _tokenIds;
    uint256[] private _teamShares = [25, 25, 25, 25];
    address[] private _team = [
        0xfDE43eBd4f75960CdaC70971B731e0bab144c8F2,
        0xC9e90603e1E0249EC00964BB180ab250A4d7bb86,
        0xEa3184Cd529a7a5a9f033bA98F405F3a56F323A0, 
        0x67Ee60ef898bEfd93D9D4b6921172FC4F74bE200
    ];
    mapping(address => bool) private _presaleList;
    mapping(address => uint256) public _presaleClaimed;
  

 constructor(
    uint256 _maxBatchSize,
    uint256 _maxTotalSupply, 
    uint256 _maxGiftSupply
  ) ERC721A("Bunny Buddies", "Bunny Buddies", _maxBatchSize, _maxTotalSupply)  
    PaymentSplitter(_team, _teamShares){

    require(
     ((_maxGiftSupply <= _maxTotalSupply) &&  (_maxBatchSize <= _maxTotalSupply)),
      "Bunny Buddies: larger collection size needed"
    );
    maxGiftSupply  = _maxGiftSupply;  
  }
 
function setBaseURI(string calldata _tokenBaseURI) external onlyOwner {
        baseURI = _tokenBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function addToPresaleList(address[] calldata _addresses)
        external
        onlyOwner
    {
        for (uint256 ind = 0; ind < _addresses.length; ind++) {
            require(
                _addresses[ind] != address(0),
                "Bunny Buddies: Can't add a zero address"
            );
            if (_presaleList[_addresses[ind]] == false) {
                _presaleList[_addresses[ind]] = true;
            }
        }
    }

    function isOnPresaleList(address _address) external view returns (bool) {
        return _presaleList[_address];
    }

    function removeFromPresaleList(address[] calldata _addresses)
        external
        onlyOwner
    {
        for (uint256 ind = 0; ind < _addresses.length; ind++) {
            require(
                _addresses[ind] != address(0),
                "Bunny Buddies: Can't remove a zero address"
            );
            if (_presaleList[_addresses[ind]] == true) {
                _presaleList[_addresses[ind]] = false;
            }
        }
    }

    function setUpPresale(uint256 _duration, uint256 _maxCount ) external onlyOwner {
      require( _duration > 0,
            "Bunny Buddies: presale duration is zero"
        );
        require(_maxCount <= maxBatchSize ,
            "Bunny Buddies: maxCount is higher than maxBatchSize "
        );
        uint256 _startTime = block.timestamp;
        presaleConfig = PresaleConfig(_startTime, _duration, _maxCount);
       
    }

    function setUpSale(uint256 _maxCount ) external onlyOwner {
        require(_maxCount <= maxBatchSize ,
            "Bunny Buddies: maxCount is higher than maxBatchSize "
        );
        PresaleConfig memory _presaleConfig = presaleConfig;
        uint256 _presaleEndTime = _presaleConfig.startTime +
            _presaleConfig.duration;
        require(
            block.timestamp > _presaleEndTime,
            "Bunny Buddies: Sale not started"
        );
        uint256 _startTime = block.timestamp;
        saleConfig = SaleConfig(_startTime, _maxCount);
    }

    function setPrice( uint256 _price) external onlyOwner   {
        price = _price;
    }

    function setIsBurnEnabled(bool _isBurnEnabled) external onlyOwner {
        isBurnEnabled = _isBurnEnabled;
    }

     function setIsPresale(bool _isPresale) external onlyOwner {
        isPresale = _isPresale; 
    }

    function promoAdminMint(uint256 _amount)
        external
        onlyOwner
        whenNotPaused
    {
        require(
            (totalSupply() + _amount) <= collectionSize,
            "Bunny Buddies:  max total sypply is is exceeded"
        );
        require(
            giftCount + _amount <= maxGiftSupply,
            "Bunny Buddies: max gift supply exceeded"
        );
            _safeMint(msg.sender, _amount);
    
            giftCount = giftCount + _amount;
        }



        function promoUserMint(address[] calldata _users) external onlyOwner
        whenNotPaused
        {
         require(
            (totalSupply() +  _users.length) <= collectionSize,
            "Bunny Buddies:  max total sypply is is exceeded"
            );
         require(
            giftCount + _users.length <= maxGiftSupply,
            "Bunny Buddies: max gift supply exceeded"
            );
        for (uint256 ind = 0; ind < _users.length; ind++) {
           
            require(
                _users[ind] != address(0),
                "Bunny Buddies: user is the zeo address"
            );
           
            _safeMint(_users[ind], 1);
        
        }
        giftCount = giftCount + _users.length;
    }

    function presaleMint(uint256 _amount) internal {
        PresaleConfig memory _presaleConfig = presaleConfig;
        require(
            _presaleConfig.startTime > 0,
            "Bunny Buddies: Presale must be active"
        );
        require(
            block.timestamp >= _presaleConfig.startTime,
            "Bunny Buddies: Presale not started"
        );
        require(
            block.timestamp <=
                _presaleConfig.startTime + _presaleConfig.duration,
            "Bunny Buddies: Presale is ended"
        );
        if (isPresale){
        require(
            _presaleList[msg.sender] == true,
            "Bunny Buddies: Caller is not on the presale list"
        );
        }
         require(
            (totalSupply() +  _amount) <= collectionSize,
            "Bunny Buddies:  max total sypply is is exceeded"
        );

        require(
            _presaleClaimed[msg.sender] + _amount <= _presaleConfig.maxCount,
            "Bunny Buddies: max count per transaction is exceeded"
        );
       
        require(
            (price * _amount) <= msg.value,
            "Bunny Buddies: Ether value sent is not correct"
        );
             _presaleClaimed[msg.sender] = _presaleClaimed[msg.sender] + _amount;
            _safeMint(msg.sender, _amount);
           
          
        }
        
    
    function saleMint(uint256 _amount) internal {
        SaleConfig memory _saleConfig = saleConfig;
        require(_amount > 0, "Bunny Buddies: zero amount");
        require(_saleConfig.startTime > 0, "Bunny Buddies: sale is not active");
        require(
            block.timestamp >= _saleConfig.startTime,
            "Bunny Buddies: sale not started"
        );
        require(
            _amount <= _saleConfig.maxCount,
            "Bunny Buddies: max count per transaction is exceeded"
        );

         require(
            (totalSupply() + _amount) <= collectionSize,
            "Bunny Buddies: max total sypply is exceeded"
        );
        require(
            (price * _amount) <= msg.value,
            "Bunny Buddies: Ether value sent is not correct"
        );

            _safeMint(msg.sender, _amount);
           
        }
    

    function mainMint(uint256 _amount) external payable whenNotPaused {
        require(
            block.timestamp > presaleConfig.startTime,
            "Bunny Buddies: presale not started"
        );
        if (
            block.timestamp <=
            (presaleConfig.startTime + presaleConfig.duration)
        ) {
            presaleMint(_amount);
        } else {
            saleMint(_amount);
        }
    }

    function burn(uint256 tokenId) external {
        require(isBurnEnabled, "Bunny Buddies: burning disabled");
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "Bunny Buddies: burn caller is not owner nor approved"
        );
        _burn(tokenId);
    }

   
}