// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "./Pausable.sol";

contract Billionaire is ERC721Enumerable, Pausable, PaymentSplitter {
    using Counters for Counters.Counter;

    struct PresaleConfig {
        uint256 startTime;
        uint256 duration;
        uint256 maxCount;
    }
    struct SaleConfig {
        uint256 startTime;
        uint256 maxCount;
    }
    uint256 public maxTotalSupply = 10333;
    uint256 public maxGiftSupply = 333;
    uint256 public giftCount;
    uint256 public presaleCount;
    uint256 public totalNFT;
    bool public isBurnEnabled;
    string public baseURI;
    PresaleConfig public presaleConfig;
    SaleConfig public saleConfig;
    Counters.Counter private _tokenIds;
    uint256[] private _teamShares = [25, 25, 25, 25];
    address[] private _team = [
        0x8dD47E819c53138aA18F8651D797e7969f34d1F1,
        0xF536390c3A0bAFF71289975e45e1f647fc8C7304,
        0xFD6Ed83d8e47B1C808efE984cEF965B2CB3393De,
        0x03bb7A8226301C1cC0e82BFf029989E22a76F597
    ];
    mapping(address => bool) private _presaleList;
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
        uint256 _maxCount
    );
    event ChangeSaleConfig(uint256 _startTime, uint256 _maxCount);
    event ChangeIsBurnEnabled(bool _isBurnEnabled);
    event ChangeBaseURI(string _baseURI);
    event GiftMint(address indexed _recipient, uint256 _amount);
    event PresaleMint(address indexed _minter, uint256 _amount, uint256 _price);
    event SaleMint(address indexed _minter, uint256 _amount, uint256 _price);
    event WorkflowStatusChange(
        WorkflowStatus previousStatus,
        WorkflowStatus newStatus
    );

    constructor()
        ERC721("Party Ape Billionaire Club", "PABC")
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
                "Billionaire: Can't add a zero address"
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
                "Billionaire: Can't remove a zero address"
            );
            if (_presaleList[_addresses[ind]] == true) {
                _presaleList[_addresses[ind]] = false;
            }
        }
    }

    function setUpPresale(uint256 _duration) external onlyOwner {
        require(
            workflow == WorkflowStatus.CheckOnPresale,
            "Bilionaire: Unauthorized Transaction"
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
            "Bilionaire: Unauthorized Transaction"
        );
        PresaleConfig memory _presaleConfig = presaleConfig;
        uint256 _presaleEndTime = _presaleConfig.startTime +
            _presaleConfig.duration;
        require(
            block.timestamp > _presaleEndTime,
            "Bilionaire: Sale not started"
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
        PresaleConfig memory _presaleConfig = presaleConfig;
        SaleConfig memory _saleConfig = saleConfig;
        if (
            block.timestamp <=
            _presaleConfig.startTime + _presaleConfig.duration
        ) {
            _price = 100000000000000000; //0.1 ETH
        } else if (block.timestamp <= _saleConfig.startTime + 3 hours) {
            _price = 300000000000000000; //0.3 ETH
        } else if (
            (block.timestamp > _saleConfig.startTime + 3 hours) &&
            (block.timestamp <= _saleConfig.startTime + 6 hours)
        ) {
            _price = 200000000000000000; //0.2 ETH
        } else {
            _price = 100000000000000000; //0.1 ETH
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
            "Billionaire: max total supply exceeded"
        );

        require(
            giftCount + _addresses.length <= maxGiftSupply,
            "Bilionaire: max gift supply exceeded"
        );

        uint256 _newItemId;
        for (uint256 ind = 0; ind < _addresses.length; ind++) {
            require(
                _addresses[ind] != address(0),
                "Bilionaire: recepient is the null address"
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
            "Bilionaire: Presale must be active to mint Ape"
        );
        require(
            block.timestamp >= _presaleConfig.startTime,
            "Bilionaire: Presale not started"
        );
        require(
            block.timestamp <=
                _presaleConfig.startTime + _presaleConfig.duration,
            "Bilionaire: Presale is ended"
        );
        require(
            _presaleList[msg.sender] == true,
            " Caller is not on the presale list"
        );
        require(
            _presaleClaimed[msg.sender] + _amount <= _presaleConfig.maxCount,
            "Bilionaire: Can only mint 2 tokens"
        );
        require(
            totalNFT + _amount <= maxTotalSupply,
            "Bilionaire: max supply exceeded"
        );
        uint256 _price = getPrice();
        require(
            _price * _amount <= msg.value,
            "Bilionaire: Ether value sent is not correct"
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
        require(_amount > 0, "Bilionaire: zero amount");
        require(_saleConfig.startTime > 0, "Bilionaire: sale is not active");
        require(
            block.timestamp >= _saleConfig.startTime,
            "Bilionaire: sale not started"
        );
        require(
            _amount <= _saleConfig.maxCount,
            "Bilionaire:  Can only mint 10 tokens at a time"
        );
        require(
            totalNFT + _amount <= maxTotalSupply,
            "Bilionaire: max supply exceeded"
        );
        uint256 _price = getPrice();
        require(
            _price * _amount <= msg.value,
            "Bilionaire: Ether value sent is not correct"
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
            block.timestamp > presaleConfig.startTime,
            "Bilionaire: presale not started"
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
        require(isBurnEnabled, "Bilionaire: burning disabled");
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "Bilionaire: burn caller is not owner nor approved"
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