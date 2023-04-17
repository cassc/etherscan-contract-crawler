// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../interfaces/IBabyWonderlandMintable.sol";

contract SmartMintableInitializable is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    // The address of the smart minter factory
    address public immutable SMART_MINTER_FACTORY;
    IBabyWonderlandMintable public babyWonderlandToken;
    IERC20 public payToken;
    bool public isInitialized;
    address payable public reserve;
    uint256 public price;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public supply;
    uint256 public remaning;
    uint256 public poolLimitPerUser;
    uint256 public plotsCapacity;
    bool public hasWhitelistLimit;
    mapping(address => uint256) public numberOfUsersMinted;

    event MintPlots(address account, uint256 startTokenId, uint256 number);
    event NewReserve(address oldReserve, address newReserve);

    constructor() {
        SMART_MINTER_FACTORY = msg.sender;
    }

    function initialize(
        address _babyWonderlandToken,
        address payable _reserve,
        address _payToken,
        uint256 _price,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _supply,
        uint256 _poolLimitPerUser,
        uint256 _plotsCapacity,
        bool _hasWhitelistLimit
    ) external {
        require(!isInitialized, "Already initialized the contract");
        require(msg.sender == SMART_MINTER_FACTORY, "Not factory");
        require(_reserve != address(0), "_reserve can not be address(0)");
        require(_price > 0, "price can not be 0");
        require(_startTime <= _endTime, "invalid time params");
        require(_poolLimitPerUser > 0, "_poolLimitPerUser can not be 0");
        require(_plotsCapacity > 0, "_plotsCapacity can not be 0");
        // Make this contract initialized
        isInitialized = true;
        babyWonderlandToken = IBabyWonderlandMintable(_babyWonderlandToken);
        reserve = _reserve;
        payToken = IERC20(_payToken);
        price = _price;
        startTime = _startTime;
        endTime = _endTime;
        supply = _supply;
        remaning = _supply;
        poolLimitPerUser = _poolLimitPerUser;
        hasWhitelistLimit = _hasWhitelistLimit;
        plotsCapacity = _plotsCapacity;
    }

    function mint() external payable nonReentrant onlyWhitelist {
        require(
            numberOfUsersMinted[msg.sender] < poolLimitPerUser,
            "purchase limit reached"
        );
        require(remaning > 0, "insufficient remaining");
        require(block.timestamp > startTime, "has not started");
        require(block.timestamp < endTime, "has expired");
        numberOfUsersMinted[msg.sender] += 1;
        if (address(payToken) == address(0)) {
            require(msg.value == price, "not enough tokens to pay");
            Address.sendValue(reserve, price);
        } else {
            payToken.safeTransferFrom(msg.sender, reserve, price);
        }
        remaning -= 1;
        babyWonderlandToken.batchMint(msg.sender, plotsCapacity);

        emit MintPlots(
            msg.sender,
            babyWonderlandToken.totalSupply() + 1,
            plotsCapacity
        );
    }

    function batchMint(uint256 number) external payable nonReentrant onlyWhitelist {
        require(block.timestamp > startTime, "has not started");
        require(block.timestamp < endTime, "has expired");
        require(
            numberOfUsersMinted[msg.sender].add(number) <= poolLimitPerUser,
            "purchase limit reached"
        );
        numberOfUsersMinted[msg.sender] += number;
        for (uint256 i = 0; i != number; i++) {
            require(remaning > 0, "insufficient remaining");
            if (address(payToken) == address(0)) {
                require(
                    msg.value == price.mul(number),
                    "not enough tokens to pay"
                );
                Address.sendValue(reserve, price);
            } else {
                payToken.safeTransferFrom(msg.sender, reserve, price);
            }
            remaning -= 1;
            babyWonderlandToken.batchMint(msg.sender, plotsCapacity);

            emit MintPlots(
                msg.sender,
                babyWonderlandToken.totalSupply() + 1,
                plotsCapacity
            );
        }
    }

    modifier onlyWhitelist() {
        require(
            !hasWhitelistLimit ||
                BabyWonderlandMakeFactory(SMART_MINTER_FACTORY).whitelist(
                    msg.sender
                ),
            "available only to whitelisted users"
        );

        _;
    }
}

contract BabyWonderlandMakeFactory is Ownable {
    uint256 private nonce;

    address immutable public babyWonderlandToken;

    mapping(address => bool) public isAdmin;
    mapping(address => bool) public whitelist;

    event NewSmartMintableContract(address indexed smartChef);
    event SetAdmin(address account, bool enable);
    event AddWhitelist(address account);
    event DelWhitelist(address account);

    constructor(address _babyWonderlandToken) {
        require(_babyWonderlandToken != address(0), "illegal token address");
        babyWonderlandToken = _babyWonderlandToken;
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
        require(
            admin != address(0),
            "BabyWonderlandMakeFactory: address is zero"
        );
        isAdmin[admin] = enable;
        emit SetAdmin(admin, enable);
    }

    modifier onlyAdmin() {
        require(
            isAdmin[msg.sender],
            "BabyWonderlandMakeFactory: caller is not the admin"
        );
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
        uint256 _plotsCapacity,
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
            babyWonderlandToken,
            _reserve,
            _payToken,
            _price,
            _startTime,
            _endTime,
            _supply,
            _poolLimitPerUser,
            _plotsCapacity,
            _hasWhitelistLimit
        );
        emit NewSmartMintableContract(smartMintableAddress);
    }
}