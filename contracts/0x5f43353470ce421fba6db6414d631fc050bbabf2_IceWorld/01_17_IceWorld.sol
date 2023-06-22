// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "./Pausable.sol";

contract IceWorld is ERC721Enumerable, Pausable, PaymentSplitter {
    using Counters for Counters.Counter;

    struct PresaleConfig {
        uint256 startTime;
        uint256 duration;
        uint256 maxCount;
    }
    struct SaleConfig {
        uint256 startTime;
        uint256 duration;
        uint256 maxCount;
    }
    uint256 public maxTotalSupply = 10000;
    uint256 public maxGiftSupply = 200;
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
        0x578F00a9C9a42A070c4E5992455cF4EEC951d274,
        0x1ba6e659Fd38b196fcA07399287Ddb4D6edEB839,
        0xE8d0dB3DFc3255871AbBF0b5032795d40b1cA172,
        0xff6f1e6A9A98349d2dc074Bd97a83E87908D97dB
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
    event ChangeSaleConfig(
        uint256 _startTime,
        uint256 _duration,
        uint256 _maxCount
    );
    event ChangeIsBurnEnabled(bool _isBurnEnabled);
    event ChangeBaseURI(string _baseURI);
    event PresaleMint(address indexed _minter, uint256 _amount, uint256 _price);
    event SaleMint(address indexed _minter, uint256 _amount, uint256 _price);
    event WorkflowStatusChange(
        WorkflowStatus previousStatus,
        WorkflowStatus newStatus
    );

    constructor()
        ERC721("Ice World", "ICE")
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
                "Ice World: Can't add a zero address"
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
                "Ice World: Can't remove a zero address"
            );
            if (_presaleList[_addresses[ind]] == true) {
                _presaleList[_addresses[ind]] = false;
            }
        }
    }

    function setUpPresale(uint256 _duration) external onlyOwner {
        require(
            workflow == WorkflowStatus.CheckOnPresale,
            "Ice World: Unauthorized Transaction"
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

    function setUpSale(uint256 _duration) external onlyOwner {
        require(workflow == WorkflowStatus.Presale, "Ice World: Unauthorized Transaction");
        PresaleConfig memory _presaleConfig = presaleConfig;
        uint256 _presaleEndTime = _presaleConfig.startTime +
            _presaleConfig.duration;
        require(block.timestamp > _presaleEndTime, "Ice World: Sale not started");
        uint256 _startTime = block.timestamp;
        uint256 _maxCount = 10;
        saleConfig = SaleConfig(_startTime, _duration, _maxCount);
        emit ChangeSaleConfig(_startTime, _duration, _maxCount);
        workflow = WorkflowStatus.Sale;
        emit WorkflowStatusChange(WorkflowStatus.Presale, WorkflowStatus.Sale);
    }

    function getPrice() public view returns (uint256) {
        uint256 _price;
        PresaleConfig memory _presaleConfig = presaleConfig;
        if (
            block.timestamp <=
            _presaleConfig.startTime + _presaleConfig.duration
        ) {
            _price = 100000000000000000; //0.1 ETH
        } else if (block.timestamp > _presaleConfig.startTime + _presaleConfig.duration) {
            _price = 150000000000000000; //0.15 ETH
        }
        return _price;
    }

    function setIsBurnEnabled(bool _isBurnEnabled) external onlyOwner {
        isBurnEnabled = _isBurnEnabled;
        emit ChangeIsBurnEnabled(_isBurnEnabled);
    }

    function giftMint(address[] memory _address, uint256[] memory _id)
        external
        onlyOwner
        whenNotPaused
    {
         require(_address.length ==_id.length,
            "Ice World: address andid dont'have the same size"
        );
        require(
            totalNFT + _address.length <= maxTotalSupply,
            "Ice World: max total supply exceeded"
        );

        require(
            giftCount + _address.length <= maxGiftSupply,
            "Ice World: max gift supply exceeded"
        );

        for (uint256 ind = 0; ind < _address.length; ind++) {
            require(
                _address[ind] != address(0),
                "Ice World: recepient is the null address"
            );
            _safeMint(_address[ind], _id[ind]);
            _giftClaimed[_address[ind]] = _giftClaimed[_address[ind]] + 1;
            _totalClaimed[_address[ind]] = _totalClaimed[_address[ind]] + 1;
            totalNFT = totalNFT + 1;
            giftCount = giftCount + 1;
        }
    }
 function freeMint(address[] calldata _address)
        external
        onlyOwner
        whenNotPaused
    {

        require(
            totalNFT + _address.length <= maxTotalSupply,
            "Ice World: max total supply exceeded"
        );

        uint256 _newItemId;
        for (uint256 ind = 0; ind < _address.length; ind++) {
            _tokenIds.increment();
            _newItemId = _tokenIds.current();
            _newItemId = generateId(_newItemId);
            _safeMint(_address[ind], _newItemId);
            _saleClaimed[_address[ind]] = _saleClaimed[_address[ind]] + 1;
            _totalClaimed[_address[ind]] = _totalClaimed[_address[ind]] + 1;
            totalNFT = totalNFT + 1;
        }
    }

    function presaleMint(uint256 _amount) internal {
        PresaleConfig memory _presaleConfig = presaleConfig;
        require(
            _presaleConfig.startTime > 0,
            "Ice World: Presale must be active to mint Ape"
        );
        require(
            block.timestamp >= _presaleConfig.startTime,
            "Ice World: Presale not started"
        );
        require(
            block.timestamp <=
                _presaleConfig.startTime + _presaleConfig.duration,
            "Ice World: Presale is ended"
        );
        require(
            _presaleList[msg.sender] == true,
            "Ice World: Caller is not on the presale list"
        );
        require(
            _presaleClaimed[msg.sender] + _amount <= _presaleConfig.maxCount,
            "Ice World: Can only mint 2 tokens"
        );
        require(totalNFT + _amount <= maxTotalSupply, "Ice World: max supply exceeded");
        uint256 _price = getPrice();
        require(
            _price * _amount <= msg.value,
            "Ice World: Ether value sent is not correct"
        );
        uint256 _newItemId;
        for (uint256 ind = 0; ind < _amount; ind++) {
            _tokenIds.increment();
            _newItemId = _tokenIds.current();
            _newItemId = generateId(_newItemId);
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
        require(_amount > 0, "Ice World: zero amount");
        require(_saleConfig.startTime > 0, "Ice World: sale is not active");
        require(block.timestamp >= _saleConfig.startTime, "Ice World: sale not started");
        require(
            block.timestamp <= _saleConfig.startTime + _saleConfig.duration,
            "Ice World: sale is finished"
        );
        require(
            _amount <= _saleConfig.maxCount,
            "Ice World: Can only mint 10 tokens at a time"
        );

        require(totalNFT + _amount <= maxTotalSupply, "Ice World: max supply exceeded");
        uint256 _price = getPrice();
        require(
            _price * _amount <= msg.value,
            "Ice World: ether value sent is not correct"
        );
        uint256 _newItemId;
        for (uint256 ind = 0; ind < _amount; ind++) {
            _tokenIds.increment();
            _newItemId = _tokenIds.current();
            _newItemId = generateId(_newItemId);
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
            "Ice World: presale not started"
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
        require(isBurnEnabled, "Ice World: burning disabled");
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "Ice World: burn caller is not owner nor approved"
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

    function generateId(uint256 _id) internal view returns (uint256) {
            while (_exists(_id) == true){
                _id = _id + 1;
            }    
        return (_id);
    }
}