// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "./Pausable.sol";

contract TheMetaStars is ERC721Enumerable, Pausable, PaymentSplitter {
    using Counters for Counters.Counter;

    struct FirstPresaleConfig {
        uint256 startTime;
        uint256 duration;
        uint256 maxCount;
    }

    struct PresaleConfig {
        uint256 startTime;
        uint256 duration;
        uint256 maxCount;
    }

    struct SaleConfig {
        uint256 startTime;
        uint256 maxCount;
    }

    uint256 public maxTotalSupply = 8888;
    uint256 public maxGiftSupply = 2222;
    uint256 public maxFirstPresaleSupply = 444;
    uint256 public giftCount;
    uint256 public firstPresaleCount;
    uint256 public presaleCount;
    uint256 public totalNFT;
    bool public isBurnEnabled;
    string public baseURI;
    FirstPresaleConfig public firstPresaleConfig;
    PresaleConfig public presaleConfig;
    SaleConfig public saleConfig;
    Counters.Counter private _tokenIds;
    uint256[] private _teamShares = [37, 25, 18, 20];
    address[] private _team = [
        0xa07b279A79E1258eEFC6Ac73F2C122e41D073311,
        0x260bE9FC0BFCCDFd479e525d1c228B4C2A64b544,
        0xAB55f43A5B9Fcd752DF0CB93DE92C95Eaf8c34F1,
        0x2107dffD15DF330c23849646C6D6F533B1001B60
    ];
    mapping(address => bool) private _presaleList;
    mapping(address => uint256) public _firstPresaleClaimed;
    mapping(address => uint256) public _presaleClaimed;
    mapping(address => uint256) public _giftClaimed;
    mapping(address => uint256) public _saleClaimed;
    mapping(address => uint256) public _totalClaimed;

    enum WorkflowStatus {
        FirstPresale,
        CheckOnPresale,
        Presale,
        Sale,
        SoldOut
    }

    WorkflowStatus public workflow;

    event ChangeFirstPresaleConfig(
        uint256 _startTime,
        uint256 _duration,
        uint256 _maxCount
    );

    event ChangePresaleConfig(
        uint256 _startTime,
        uint256 _duration,
        uint256 _maxCount
    );

    event ChangeSaleConfig(uint256 _startTime, uint256 _maxCount);
    event ChangeIsBurnEnabled(bool _isBurnEnabled);
    event ChangeBaseURI(string _baseURI);
    event GiftMint(address indexed _recipient, uint256 _amount);
    event FirstPresaleMint(
        address indexed _minter,
        uint256 _amount,
        uint256 _price
    );
    event PresaleMint(address indexed _minter, uint256 _amount, uint256 _price);
    event SaleMint(address indexed _minter, uint256 _amount, uint256 _price);
    event WorkflowStatusChange(
        WorkflowStatus previousStatus,
        WorkflowStatus newStatus
    );

    constructor()
        ERC721("TheMetaStars", "MT")
        PaymentSplitter(_team, _teamShares)
    {}

    function setBaseURI(string calldata _tokenBaseURI) external onlyOwner {
        baseURI = _tokenBaseURI;
        emit ChangeBaseURI(_tokenBaseURI);
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
                "TheMetaStars: Can't add a zero address"
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
                "TheMetaStars: Can't remove a zero address"
            );
            if (_presaleList[_addresses[ind]] == true) {
                _presaleList[_addresses[ind]] = false;
            }
        }
    }

    function setUpFirstPresale(uint256 _duration) external onlyOwner {
        require(
            workflow == WorkflowStatus.FirstPresale,
            "TheMetaStars: Unauthorized Transaction"
        );
        uint256 _startTime = block.timestamp;
        uint256 _maxCount = 2;
        firstPresaleConfig = FirstPresaleConfig(
            _startTime,
            _duration,
            _maxCount
        );
        emit ChangeFirstPresaleConfig(_startTime, _duration, _maxCount);
        workflow = WorkflowStatus.CheckOnPresale;
        emit WorkflowStatusChange(
            WorkflowStatus.FirstPresale,
            WorkflowStatus.CheckOnPresale
        );
    }

    function setUpPresale(uint256 _duration) external onlyOwner {
        require(
            workflow == WorkflowStatus.CheckOnPresale,
            "TheMetaStars: Unauthorized Transaction"
        );
        FirstPresaleConfig memory _firstPresaleConfig = firstPresaleConfig;
        uint256 _firstPresaleEndTime = _firstPresaleConfig.startTime +
            _firstPresaleConfig.duration;
        require(
            block.timestamp > _firstPresaleEndTime,
            "TheMetaStars: PreSale not started"
        );
        uint256 _startTime = block.timestamp;
        uint256 _maxCount = 2;
        presaleConfig = PresaleConfig(_startTime, _duration, _maxCount);
        emit ChangePresaleConfig(_startTime, _duration, _maxCount);
        workflow = WorkflowStatus.Presale;
        emit WorkflowStatusChange(
            WorkflowStatus.CheckOnPresale,
            WorkflowStatus.Presale
        );
    }

    function setUpSale() external onlyOwner {
        require(
            workflow == WorkflowStatus.Presale,
            "TheMetaStars: Unauthorized Transaction"
        );
        PresaleConfig memory _presaleConfig = presaleConfig;
        uint256 _presaleEndTime = _presaleConfig.startTime +
            _presaleConfig.duration;
        require(
            block.timestamp > _presaleEndTime,
            "TheMetaStars: Sale not started"
        );
        uint256 _startTime = block.timestamp;
        uint256 _maxCount = 10;
        saleConfig = SaleConfig(_startTime, _maxCount);
        emit ChangeSaleConfig(_startTime, _maxCount);
        workflow = WorkflowStatus.Sale;
        emit WorkflowStatusChange(WorkflowStatus.Presale, WorkflowStatus.Sale);
    }

    function getPrice() public view returns (uint256) {
        uint256 _price;
        FirstPresaleConfig memory _firstPresaleConfig = firstPresaleConfig;
        PresaleConfig memory _presaleConfig = presaleConfig;
        SaleConfig memory _saleConfig = saleConfig;
        if (
            block.timestamp <=
            _firstPresaleConfig.startTime + _firstPresaleConfig.duration
        ) {
            _price = 100000000000000000;
        } else if (
            block.timestamp <=
            _presaleConfig.startTime + _presaleConfig.duration
        ) {
            _price = 100000000000000000;
        } else if (block.timestamp <= _saleConfig.startTime + 3 hours) {
            _price = 250000000000000000;
        } else if (
            (block.timestamp > _saleConfig.startTime + 3 hours) &&
            (block.timestamp <= _saleConfig.startTime + 6 hours)
        ) {
            _price = 250000000000000000;
        } else {
            _price = 250000000000000000;
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
            "TheMetaStars: max total supply exceeded"
        );

        require(
            giftCount + _addresses.length <= maxGiftSupply,
            "TheMetaStars: max gift supply exceeded"
        );

        uint256 _newItemId;
        for (uint256 ind = 0; ind < _addresses.length; ind++) {
            require(
                _addresses[ind] != address(0),
                "TheMetaStars: recepient is the null address"
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

    function firstPresaleMint(uint256 _amount) internal {
        FirstPresaleConfig memory _firstPresaleConfig = firstPresaleConfig;
        require(
            _firstPresaleConfig.startTime > 0,
            "TheMetaStars: First Presale must be active to mint Stars"
        );
        require(
            block.timestamp >= _firstPresaleConfig.startTime,
            "TheMetaStars: First Presale not started"
        );
        require(
            block.timestamp <=
                _firstPresaleConfig.startTime + _firstPresaleConfig.duration,
            "TheMetaStars: First Presale is ended"
        );
        require(
            _firstPresaleClaimed[msg.sender] + _amount <=
                _firstPresaleConfig.maxCount,
            "TheMetaStars: Can only mint 2 tokens for first presale" //TODO
        );
        require(
            totalNFT + _amount <= maxFirstPresaleSupply,
            "TheMetaStars: max first presale supply exceeded"
        );
        require(
            totalNFT + _amount <= maxTotalSupply,
            "TheMetaStars: max supply exceeded"
        );
        uint256 _price = getPrice();
        require(
            _price * _amount <= msg.value,
            "TheMetaStars: Ether value sent is not correct"
        );
        uint256 _newItemId;
        for (uint256 ind = 0; ind < _amount; ind++) {
            _tokenIds.increment();
            _newItemId = _tokenIds.current();
            _safeMint(msg.sender, _newItemId);
            _firstPresaleClaimed[msg.sender] =
                _firstPresaleClaimed[msg.sender] +
                _amount;
            _totalClaimed[msg.sender] = _totalClaimed[msg.sender] + _amount;
            totalNFT = totalNFT + 1;
            firstPresaleCount = firstPresaleCount + 1;
        }
        emit FirstPresaleMint(msg.sender, _amount, _price);
    }

    function presaleMint(uint256 _amount) internal {
        PresaleConfig memory _presaleConfig = presaleConfig;
        require(
            _presaleConfig.startTime > 0,
            "TheMetaStars: Presale must be active to mint Stars"
        );
        require(
            block.timestamp >= _presaleConfig.startTime,
            "TheMetaStars: Presale not started"
        );
        require(
            block.timestamp <=
                _presaleConfig.startTime + _presaleConfig.duration,
            "TheMetaStars: Presale is ended"
        );
        require(
            _presaleClaimed[msg.sender] + _amount <= _presaleConfig.maxCount,
            "TheMetaStars: Can only mint 2 tokens"
        );
        require(
            totalNFT + _amount <= maxTotalSupply,
            "TheMetaStars: max supply exceeded"
        );
        uint256 _price = getPrice();
        require(
            _price * _amount <= msg.value,
            "TheMetaStars: Ether value sent is not correct"
        );
        uint256 _newItemId;
        for (uint256 ind = 0; ind < _amount; ind++) {
            _tokenIds.increment();
            _newItemId = _tokenIds.current();
            _safeMint(msg.sender, _newItemId);
            _presaleClaimed[msg.sender] = _presaleClaimed[msg.sender] + _amount;
            _totalClaimed[msg.sender] = _totalClaimed[msg.sender] + _amount;
            totalNFT = totalNFT + 1;
            presaleCount = presaleCount + 1;
        }
        emit PresaleMint(msg.sender, _amount, _price);
    }

    function saleMint(uint256 _amount) internal {
        SaleConfig memory _saleConfig = saleConfig;
        require(_amount > 0, "TheMetaStars: zero amount");
        require(_saleConfig.startTime > 0, "TheMetaStars: sale is not active");
        require(
            block.timestamp >= _saleConfig.startTime,
            "TheMetaStars: sale not started"
        );
        require(
            _amount <= _saleConfig.maxCount,
            "TheMetaStars:  Can only mint 10 tokens at a time"
        );
        require(
            totalNFT + _amount <= maxTotalSupply,
            "TheMetaStars: max supply exceeded"
        );
        uint256 _price = getPrice();
        require(
            _price * _amount <= msg.value,
            "TheMetaStars: Ether value sent is not correct"
        );
        uint256 _newItemId;
        for (uint256 ind = 0; ind < _amount; ind++) {
            _tokenIds.increment();
            _newItemId = _tokenIds.current();
            _safeMint(msg.sender, _newItemId);
            _saleClaimed[msg.sender] = _saleClaimed[msg.sender] + _amount;
            _totalClaimed[msg.sender] = _totalClaimed[msg.sender] + _amount;
            totalNFT = totalNFT + 1;
        }
        emit SaleMint(msg.sender, _amount, _price);
    }

    function mainMint(uint256 _amount) external payable whenNotPaused {
        require(
            block.timestamp > presaleConfig.startTime ||
                block.timestamp > firstPresaleConfig.startTime,
            "TheMetaStars: first presale or presale not started"
        );
        if (
            block.timestamp <=
            (firstPresaleConfig.startTime + firstPresaleConfig.duration)
        ) {
            firstPresaleMint(_amount);
        } else if (
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
        require(isBurnEnabled, "TheMetaStars: burning disabled");
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "TheMetaStars: burn caller is not owner nor approved"
        );
        _burn(tokenId);
        totalNFT = totalNFT - 1;
    }

    function getWorkflowStatus() public view returns (uint256) {
        uint256 _status;
        if (workflow == WorkflowStatus.FirstPresale) {
            _status = 1;
        }
        if (workflow == WorkflowStatus.CheckOnPresale) {
            _status = 2;
        }
        if (workflow == WorkflowStatus.Presale) {
            _status = 3;
        }
        if (workflow == WorkflowStatus.Sale) {
            _status = 4;
        }
        if (workflow == WorkflowStatus.SoldOut) {
            _status = 5;
        }
        return _status;
    }
}