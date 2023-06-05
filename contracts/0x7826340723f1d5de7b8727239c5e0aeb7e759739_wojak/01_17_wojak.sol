// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "./Pausable.sol";

contract wojak is ERC721Enumerable, Pausable, PaymentSplitter {
    using Counters for Counters.Counter;

    struct PresaleConfig {
        uint256 startTime;
        uint256 duration;
        uint256 maxCount;
		uint256 presalePrice;
    }
    struct SaleConfig {
        uint256 startTime;
        uint256 maxCount;
    }
    uint256 public maxTotalSupply = 10069;
    uint256 public maxGiftSupply = 69;
    uint256 public giftCount;
    uint256 public presaleCount;
	uint256 public presaleCount2;
	uint256 public presaleRound =0;
    uint256 public totalNFT;
	bool public isBurnEnabled;
    string public baseURI;
	string public caURI;
    PresaleConfig public presaleConfig;
    SaleConfig public saleConfig;
    Counters.Counter private _tokenIds;
    uint256[] private _teamShares = [5,5,5,2,5,78]; 
    address[] private _team = [
        0x3b4Bd977B5b9efd53FE17a196a4c972A1cDFf51a,
        0xb5e23fE9cF300e7121664BE4283d4186F554e96d,
		0xbB129e25c5793E8F6c67160F5ce17826951cD53A,
		0x28983F9888c1193f3E88970834Fb14F64e645Cc0,
		0x15B15A668074d315eB2F6A43Db521dE2868538B5,
        0xdf3a48f48725f48d52d5a65E7DcDFd121A48BB6a
    ];
    mapping(address => bool) private _presaleList;
	mapping(address => bool) private _presaleList2;
    mapping(address => uint256) public _presaleClaimed;
    mapping(address => uint256) public _giftClaimed;
    mapping(address => uint256) public _saleClaimed;
    mapping(address => uint256) public _totalClaimed;

    enum WorkflowStatus {
        CheckOnPresale,
        Presale,
        Sale,
        SoldOut
    }
    WorkflowStatus public workflow;

    event ChangePresaleConfig(
        uint256 _startTime,
        uint256 _duration,
        uint256 _maxCount,
		uint256 _presalePrice
    );
    event ChangeSaleConfig(uint256 _startTime, uint256 _maxCount);
    event ChangeIsBurnEnabled(bool _isBurnEnabled);
    event ChangeBaseURI(string _baseURI);
	event ChangeContractURI(string _caURI);
    event GiftMint(address indexed _recipient, uint256 _amount);
    event PresaleMint(address indexed _minter, uint256 _amount, uint256 _price);
    event SaleMint(address indexed _minter, uint256 _amount, uint256 _price);
    event WorkflowStatusChange(
        WorkflowStatus previousStatus,
        WorkflowStatus newStatus
    );

    constructor()
        ERC721("World of Wojak", "WOW")
        PaymentSplitter(_team, _teamShares)
    {}

    function setBaseURI(string calldata _tokenBaseURI) external onlyOwner {
        baseURI = _tokenBaseURI;
        emit ChangeBaseURI(_tokenBaseURI);
    }
	function setContractURI(string calldata _contractTokenURI) external onlyOwner {
        caURI = _contractTokenURI;
        emit ChangeContractURI(_contractTokenURI);
    }
    function contractURI() public view returns (string memory) {
        return  caURI;
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
                "wojak: Can't add a zero address"
            );
            if (_presaleList[_addresses[ind]] == false) {
                _presaleList[_addresses[ind]] = true;
            }
        }
    }
	function addToPresaleList2(address[] calldata _addresses)
        external
        onlyOwner
    {
        for (uint256 ind = 0; ind < _addresses.length; ind++) {
            require(
                _addresses[ind] != address(0),
                "wojak: Can't add a zero address"
            );
            if (_presaleList2[_addresses[ind]] == false) {
                _presaleList2[_addresses[ind]] = true;
            }
        }
    }
	
    function isOnPresaleList(address _address) external view returns (bool) {
        return _presaleList[_address];
    }
	 function isOnPresaleList2(address _address) external view returns (bool) {
        return _presaleList2[_address];
    }

    function removeFromPresaleList(address[] calldata _addresses)
        external
        onlyOwner
    {
        for (uint256 ind = 0; ind < _addresses.length; ind++) {
            require(
                _addresses[ind] != address(0),
                "wojak: Can't remove a zero address"
            );
            if (_presaleList[_addresses[ind]] == true) {
                _presaleList[_addresses[ind]] = false;
            }
        }
    }
	function removeFromPresaleList2(address[] calldata _addresses)
        external
        onlyOwner
    {
        for (uint256 ind = 0; ind < _addresses.length; ind++) {
            require(
                _addresses[ind] != address(0),
                "wojak: Can't remove a zero address"
            );
            if (_presaleList2[_addresses[ind]] == true) {
                _presaleList2[_addresses[ind]] = false;
            }
        }
    }

    function setUpPresaleNextRound(uint256 _duration, uint256 _presalePrice) external onlyOwner {
        require(
            workflow == WorkflowStatus.CheckOnPresale || workflow == WorkflowStatus.Presale ,
            "wojak: Unauthorized Transaction"
        );
		if (presaleRound==0) {
		baseURI="https://www.worldofwojak.com/api/";
	    caURI= "https://worldofwojak.com/contract/";
		}
		presaleRound = presaleRound+1;
		uint256 _maxCount=2;
		if (presaleRound==1) 
		{
		  _maxCount=2;
		}
		if (presaleRound==2) {
            _maxCount=5;
			}
			
        uint256 _startTime = block.timestamp;
        presaleConfig = PresaleConfig(_startTime, _duration, _maxCount, _presalePrice );
        emit ChangePresaleConfig(_startTime, _duration, _maxCount, _presalePrice );
        workflow = WorkflowStatus.Presale;
        emit WorkflowStatusChange(
            WorkflowStatus.CheckOnPresale,
            WorkflowStatus.Presale
        );
    }

    function setUpSale() external onlyOwner {
        require(
            workflow == WorkflowStatus.Presale,
            "wojak: Unauthorized Transaction"
        );
        PresaleConfig memory _presaleConfig = presaleConfig;
        uint256 _presaleEndTime = _presaleConfig.startTime +
            _presaleConfig.duration;
        require(
            block.timestamp > _presaleEndTime,
            "wojak: Sale not started"
        );
        uint256 _startTime = block.timestamp;
        uint256 _maxCount = 3;
        saleConfig = SaleConfig(_startTime, _maxCount);
        emit ChangeSaleConfig(_startTime, _maxCount);
        workflow = WorkflowStatus.Sale;
        emit WorkflowStatusChange(WorkflowStatus.Presale, WorkflowStatus.Sale);
    }

    function getPrice() public view returns (uint256) {
        uint256 _price;
        PresaleConfig memory _presaleConfig = presaleConfig;
        SaleConfig memory _saleConfig = saleConfig;
        if (
            block.timestamp <=
            _presaleConfig.startTime + _presaleConfig.duration
        ) {
            _price = _presaleConfig.presalePrice; 
        } else if (block.timestamp >= _saleConfig.startTime + 30 minutes) {
            _price = 70000000000000000; //0.07 ETH
			
        } else if (
     		(block.timestamp >= _saleConfig.startTime ) &&
            (block.timestamp < _saleConfig.startTime + 30 minutes)
        ) {
		 uint256 _minutes=(block.timestamp-_saleConfig.startTime)/60;
		 uint256 _decrease= _minutes*16600000000000000;
            _price = 568000000000000000-_decrease; // price decreasing during dutch auction
        } else {
            _price = 568000000000000000; //0.568 ETH ( this price is never used for mint )
        }
        return _price;
    }

    function setIsBurnEnabled(bool _isBurnEnabled) external onlyOwner {
        isBurnEnabled = _isBurnEnabled;
        emit ChangeIsBurnEnabled(_isBurnEnabled);
    }

    function giftMint(address[] calldata _addresses)
        external
        onlyOwner
        whenNotPaused
    {
        require(
            totalNFT + _addresses.length <= maxTotalSupply,
            "wojak: max total supply exceeded"
        );

        require(
            giftCount + _addresses.length <= maxGiftSupply,
            "wojak: max gift supply exceeded"
        );

        uint256 _newItemId;
        for (uint256 ind = 0; ind < _addresses.length; ind++) {
            require(
                _addresses[ind] != address(0),
                "wojak: recepient is the null address"
            );
            _tokenIds.increment();
            _newItemId = _tokenIds.current();
            _safeMint(_addresses[ind], _newItemId);
            _giftClaimed[_addresses[ind]] = _giftClaimed[_addresses[ind]] + 1;
            _totalClaimed[_addresses[ind]] = _totalClaimed[_addresses[ind]] + 1;
            totalNFT = totalNFT + 1;
            giftCount = giftCount + 1;
        }
    }

    function presaleMint(uint256 _amount) internal {
        PresaleConfig memory _presaleConfig = presaleConfig;
        require(
            _presaleConfig.startTime > 0,
            "wojak: Presale must be active to mint Ape"
        );
        require(
            block.timestamp >= _presaleConfig.startTime,
            "wojak: Presale not started"
        );
        require(
            block.timestamp <=
                _presaleConfig.startTime + _presaleConfig.duration,
            "wojak: Presale is ended"
        );
		if (presaleRound==1) 
		{
		require(_presaleList[msg.sender] == true);
		require(_presaleClaimed[msg.sender] + _amount <= 2);
		}
		if (presaleRound==2) 
		{
		require(_presaleList2[msg.sender] == true);
		
			if (_presaleList[msg.sender]==false){
				require(_presaleClaimed[msg.sender] + _amount <= 3);
			}
			else{
				require(_presaleClaimed[msg.sender] + _amount <= 5);
			}
        }       			
        require(
            totalNFT + _amount <= maxTotalSupply,
            "wojak: max supply exceeded"
        );
        uint256 _price = getPrice();
        require(
            _price * _amount <= msg.value,
            "wojak: Ether value sent is not correct"
        );
		uint256 _newItemId;
        for (uint256 ind = 0; ind < _amount; ind++) {
            _tokenIds.increment();
            _newItemId = _tokenIds.current();
            _safeMint(msg.sender, _newItemId);
            _presaleClaimed[msg.sender] = _presaleClaimed[msg.sender] + 1;
            _totalClaimed[msg.sender] = _totalClaimed[msg.sender] + 1;
            totalNFT = totalNFT + 1;
            presaleCount = presaleCount + 1;
        }
		
        emit PresaleMint(msg.sender, _amount, _price);
    }

    function saleMint(uint256 _amount) internal {
        SaleConfig memory _saleConfig = saleConfig;
        require(_amount > 0, "wojak: zero amount");
        require(_saleConfig.startTime > 0, "wojak: sale is not active");
        require(
            block.timestamp >= _saleConfig.startTime,
            "wojak: sale not started"
        );
        require(
            _amount <= _saleConfig.maxCount,
            "wojak:  Can only mint 10 tokens at a time"
        );
        require(
            totalNFT + _amount <= maxTotalSupply,
            "wojak: max supply exceeded"
        );
        uint256 _price = getPrice();
        require(
            _price * _amount <= msg.value,
            "wojak: Ether value sent is not correct"
        );
		require(_totalClaimed[msg.sender]-_giftClaimed[msg.sender]+_amount<=3);
		uint256 _newItemId;
        for (uint256 ind = 0; ind < _amount; ind++) {
            _tokenIds.increment();
            _newItemId = _tokenIds.current();
            _safeMint(msg.sender, _newItemId);
            _saleClaimed[msg.sender] = _saleClaimed[msg.sender] + 1;
            _totalClaimed[msg.sender] = _totalClaimed[msg.sender] + 1;
            totalNFT = totalNFT + 1;
        }
        emit SaleMint(msg.sender, _amount, _price);
    }

    function mainMint(uint256 _amount) external payable whenNotPaused {
        require(
            block.timestamp > presaleConfig.startTime,
            "wojak: presale not started"
        );
        if (
            block.timestamp <=
            (presaleConfig.startTime + presaleConfig.duration)
        ) {
            presaleMint(_amount);
        } else {
            saleMint(_amount);
        }
        if (totalNFT + _amount == maxTotalSupply) {
            workflow = WorkflowStatus.SoldOut;
            emit WorkflowStatusChange(
                WorkflowStatus.Sale,
                WorkflowStatus.SoldOut
            );
        }
    }

    function burn(uint256 tokenId) external {
        require(isBurnEnabled, "wojak: burning disabled");
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "wojak: burn caller is not owner nor approved"
        );
        _burn(tokenId);
        totalNFT = totalNFT - 1;
    }

    function getWorkflowStatus() public view returns (uint256) {
        uint256 _status;
        if (workflow == WorkflowStatus.CheckOnPresale) {
            _status = 1;
        }
        if (workflow == WorkflowStatus.Presale) {
            _status = 2;
        }
        if (workflow == WorkflowStatus.Sale) {
            _status = 3;
        }
        if (workflow == WorkflowStatus.SoldOut) {
            _status = 4;
        }
        return _status;
    }
}