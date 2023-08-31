// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";


contract Ticket is Ownable {
    using SafeMath for uint256;

    address private constant ZERO = 0x0000000000000000000000000000000000000000;

    IERC20 public token;
    IERC20 public usdt;

    enum TokenType {TOKEN, USDT}

    address public issuer;
    address public pool;

    mapping(bytes32 => bool) public signatures;

    event Deposit(address addr, uint256 amount, TokenType tokenType);
    event Withdraw(bytes32 hash, address addr, uint256 from, uint256 to, uint256 amount, TokenType tokenType);

    enum TicketType {Novice, Rising, Iconic, Master, GrandMaster}
    struct T {
        uint256 id;
        TicketType ticketType;
    }
    mapping(address => mapping(uint8 => bool)) public ticketMap;
    mapping(address => uint256[]) public userTickets;
    mapping(uint256 => T) public tickets;
    mapping(uint8 => uint256) public ticketPrices;
    event BuyTicket(address buyer, uint256 ticketId, TicketType ticketType);

    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _owners;
    uint256 private _totalSupply;

    receive() external payable { }

    constructor (address _token, address _usdt) Ownable() {
        token = IERC20(_token);
        usdt = IERC20(_usdt);
        ticketPrices[uint8(TicketType.Novice)] = 150000*10**18;
        ticketPrices[uint8(TicketType.Rising)] = 240000*10**18;
        ticketPrices[uint8(TicketType.Iconic)] = 330000*10**18;
        ticketPrices[uint8(TicketType.Master)] = 440000*10**18;
        ticketPrices[uint8(TicketType.GrandMaster)] = 550000*10**18;
        pool = msg.sender;
        issuer = msg.sender;
    }
    function setTicketPrices(uint256 novice, uint256 rising, uint256 iconic, uint256 master, uint256 gm) external onlyOwner {
        ticketPrices[uint8(TicketType.Novice)] = novice;
        ticketPrices[uint8(TicketType.Rising)] = rising;
        ticketPrices[uint8(TicketType.Iconic)] = iconic;
        ticketPrices[uint8(TicketType.Master)] = master;
        ticketPrices[uint8(TicketType.GrandMaster)] = gm;
    }
    function setPool(address _pool) external onlyOwner {
        pool = _pool;
    }
    function setIssuer(address _issuer) external onlyOwner {
        issuer = _issuer;
    }

    function poolStatus() view external returns (uint256, uint256) {
        uint256 tokenBalance = token.balanceOf(pool);
        uint256 usdtBalance = usdt.balanceOf(pool);
        return (tokenBalance, usdtBalance);
    }

    function deposit(uint256 amount, TokenType tokenType) external {
        if (tokenType == TokenType.TOKEN) {
            bool success = token.transferFrom(msg.sender, pool, amount);
            require(success, "token transfer failed");
            emit Deposit(msg.sender, amount, TokenType.TOKEN);
        } else if (tokenType == TokenType.USDT) {
            bool success = usdt.transferFrom(msg.sender, pool, amount);
            require(success, "token transfer failed");
            emit Deposit(msg.sender, amount, TokenType.USDT);
        }
    }
    function execSig(bytes memory signature, address addr, uint256 from, uint256 to, uint256 amount, TokenType tokenType) internal returns (bytes32) {
        // abi encode of [address, uint256, uint256, uint256, uint8] = 20+256/8*3+8/8 = 117 bytes
        bytes32 hash = keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n117", addr, from, to, amount, uint8(tokenType)
        ));
        require(!signatures[hash], "signature was executed");
        require(SignatureChecker.isValidSignatureNow(issuer, hash, signature), "invalid signature");
        signatures[hash] = true;
        return hash;
    }
    function withdraw(bytes memory signature, uint256 from, uint256 to, uint256 amount, TokenType tokenType) external {
        bytes32 hash = execSig(signature, msg.sender, from, to, amount, tokenType);
        if (tokenType == TokenType.TOKEN) {
            bool success = token.transferFrom(pool, msg.sender, amount);
            require(success, "token transfer failed");
            emit Withdraw(hash, msg.sender, from, to, amount, TokenType.TOKEN);
        } else if (tokenType == TokenType.USDT) {
            bool success = usdt.transferFrom(pool, msg.sender, amount);
            require(success, "token transfer failed");
            emit Withdraw(hash, msg.sender, from, to, amount, TokenType.USDT);
        }
    }

    function _mint(address to, uint256 tokenId) internal {
        _balances[to] += 1;
        _owners[tokenId] = to;
        _totalSupply += 1;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    // buy
    function buyTicket(TicketType ticketType) external {
        require(ticketMap[msg.sender][uint8(ticketType)] == false, "can not buy already owned ticket");
        uint256 price = ticketPrices[uint8(ticketType)];
        require(price > 0, "can not buy");
        uint256 ticketId = totalSupply();
        _mint(msg.sender, ticketId);
        tickets[ticketId] = T(
            ticketId, ticketType
        );
        userTickets[msg.sender].push(ticketId);
        bool success = token.transferFrom(msg.sender, pool, price);
        require(success, "token transfer failed");
        ticketMap[msg.sender][uint8(ticketType)] = true;
        emit BuyTicket(msg.sender, ticketId, ticketType);
    }

    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    function getTickets(address ownerAddress) view external returns (T[] memory ownerTickets) {
        uint256 length = balanceOf(ownerAddress);
        ownerTickets = new T[](length);
        for(uint256 i = 0; i < length; i++) {
            uint256 ticketId = userTickets[ownerAddress][i];
            ownerTickets[i] = tickets[ticketId];
        }
    }

    function statusTickets(address ownerAddress) view external returns (bool, bool, bool, bool, bool) {
        return (
            ticketMap[ownerAddress][uint8(TicketType.Novice)],
            ticketMap[ownerAddress][uint8(TicketType.Rising)],
            ticketMap[ownerAddress][uint8(TicketType.Iconic)],
            ticketMap[ownerAddress][uint8(TicketType.Master)],
            ticketMap[ownerAddress][uint8(TicketType.GrandMaster)]
        );
    }
}