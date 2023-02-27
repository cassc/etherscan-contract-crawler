// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../interfaces/IBabyWealthyClubMintable.sol";

contract SmartMintableInitializable is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    // The address of the smart minner factory
    address immutable public SMART_MINNER_FACTORY;
    IBabyWealthyClubMintable public bwcToken;
    IERC20 public payToken;
    bool public isInitialized;
    address payable public reserve;
    uint256 public price;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public supply;
    uint256 public remaning;
    uint256 public poolLimitPerUser;
    bool public hasWhitelistLimit;
    mapping(address => uint256) public numberOfUsersMinted;

    event NewReserve(address oldReserve, address newReserve);

    constructor() {
        SMART_MINNER_FACTORY = msg.sender;
    }

    function initialize(
        address _bwcToken,
        address payable _reserve,
        address _payToken,
        uint256 _price,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _supply,
        uint256 _poolLimitPerUser,
        bool _hasWhitelistLimit
    ) external {
        require(!isInitialized, "Already initialized the contract");
        require(msg.sender == SMART_MINNER_FACTORY, "Not factory");
        require(_reserve != address(0), "_reserve can not be address(0)");
        require(_price > 0, "price can not be 0");
        require(_startTime <= _endTime, "invalid time params");
        require(_poolLimitPerUser > 0, "_poolLimitPerUser can not be 0");
        // Make this contract initialized
        isInitialized = true;
        bwcToken = IBabyWealthyClubMintable(_bwcToken);
        reserve = _reserve;
        payToken = IERC20(_payToken);
        price = _price;
        startTime = _startTime;
        endTime = _endTime;
        supply = _supply;
        remaning = _supply;
        poolLimitPerUser = _poolLimitPerUser;
        hasWhitelistLimit = _hasWhitelistLimit;
    }

    function mint() external payable nonReentrant onlyWhitelist {
        require(
            numberOfUsersMinted[msg.sender] < poolLimitPerUser,
            "Purchase limit reached"
        );
        require(remaning > 0, "Insufficient remaining");
        require(block.timestamp > startTime, "Has not started");
        require(block.timestamp < endTime, "Has expired");
        numberOfUsersMinted[msg.sender] += 1;
        if (address(payToken) == address(0)) {
            require(msg.value == price, "Not enough tokens to pay");
            Address.sendValue(reserve, price);
        } else {
            payToken.safeTransferFrom(msg.sender, reserve, price);
        }
        remaning -= 1;
        bwcToken.mint(msg.sender);
    }

    function batchMint(uint number) external payable nonReentrant onlyWhitelist {
        require(number > 0, "number can not be 0");
        require(
            numberOfUsersMinted[msg.sender] + number <= poolLimitPerUser,
            "Purchase limit reached"
        );
        require(remaning >= number, "Insufficient remaining");
        require(block.timestamp > startTime, "Has not started");
        require(block.timestamp < endTime, "Has expired");
        numberOfUsersMinted[msg.sender] += number;
        uint amount =  price * number;
        if (address(payToken) == address(0)) {
            require(msg.value == amount, "Not enough tokens to pay");
            Address.sendValue(reserve, amount);
        } else {
            payToken.safeTransferFrom(msg.sender, reserve, amount);
        }
        remaning -= number;
        address[] memory recipients = new address[](number);
        for(uint i = 0; i != recipients.length; i++ ) {
            recipients[i] = msg.sender;
        }
        bwcToken.batchMint(recipients);
    }

    modifier onlyWhitelist() {
        require(
            !hasWhitelistLimit ||
                BabyWealthyClubMakeFactory(SMART_MINNER_FACTORY).whitelist(
                    msg.sender
                ),
            "Available only to whitelisted users"
        );

        _;
    }
}

contract BabyWealthyClubMakeFactory is Ownable {
    uint256 private nonce;

    address public bwcToken;

    mapping(address => bool) public isAdmin;
    mapping(address => bool) public whitelist;

    event NewSmartMintableContract(address indexed smartChef);
    event SetAdmin(address account, bool enable);
    event AddWhitelist(address account);
    event DelWhitelist(address account);

    constructor(address _bwcToken) {
        bwcToken = _bwcToken;
    }

    function addWhitelist(address account) public onlyAdmin {
        whitelist[account] = true;
        emit AddWhitelist(account);
    }

    function batchAddWhitelist(address[] memory accounts) external onlyAdmin {
        for (uint256 i = 0; i != accounts.length; i++) {
            addWhitelist(accounts[i]);
        }
    }

    function delWhitelist(address account) public onlyAdmin {
        whitelist[account] = false;
        emit DelWhitelist(account);
    }

    function batchDelWhitelist(address[] memory accounts) external onlyAdmin {
        for (uint256 i = 0; i != accounts.length; i++) {
            delWhitelist(accounts[i]);
        }
    }

    function setAdmin(address admin, bool enable) external onlyOwner {
        require(admin != address(0), "BWC: address is zero");
        isAdmin[admin] = enable;
        emit SetAdmin(admin, enable);
    }

    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "BWC: caller is not the admin");
        _;
    }

    function deployMintable(
        address payable _reserve,
        address _payToken,
        uint256 _price,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _supply,
        uint256 _poolLimitPerUser,
        bool _hasWhitelistLimit
    ) external onlyAdmin {
        nonce = nonce + 1;
        bytes memory bytecode = type(SmartMintableInitializable).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(nonce));
        address smartMintableAddress;

        assembly {
            smartMintableAddress := create2(
                0,
                add(bytecode, 32),
                mload(bytecode),
                salt
            )
        }

        SmartMintableInitializable(smartMintableAddress).initialize(
            bwcToken,
            _reserve,
            _payToken,
            _price,
            _startTime,
            _endTime,
            _supply,
            _poolLimitPerUser,
            _hasWhitelistLimit
        );
        emit NewSmartMintableContract(smartMintableAddress);
    }
}