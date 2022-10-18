//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";

contract IUSD is Initializable, OwnableUpgradeable, ERC20PermitUpgradeable {
    mapping(address => bool) public freezed;
    mapping(address => uint256) public miners;

    event Freeze(address indexed account, bool isFreeze);
    event IncreaseMiner(address minter, uint256 amount);
    event DecreaseMiner(address minter, uint256 amount);
    event DelegateMiner(address from, address to, uint256 amount);
    event Rescue(address indexed from, address indexed to, uint256 amount);

    constructor() {}

    function initialize() public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ERC20_init("ITOM USD", "IUSD");
        __ERC20Permit_init("ITOM USD");
    }

    function mint(address to, uint256 amount) external {
        if (owner() == _msgSender()) {
            _mint(to, amount);
        } else {
            require(miners[msg.sender] >= amount, "IUSD: Invalid miner");
            miners[msg.sender] -= amount;
            _mint(to, amount);
        }
    }

    function burn(uint256 amount) external onlyOwner{
        _burn(msg.sender, amount);
    }

    function freeze(address user, bool isFreeze) external onlyOwner {
        freezed[user] = isFreeze;
        emit Freeze(user, isFreeze);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256
    ) internal virtual override {
        require(!freezed[from], "IUSD: SRC Account Freezed");
        require(!freezed[to], "IUSD: DST Account Freezed");
    }

    function increaseMiner(address miner, uint256 amount) external onlyOwner {
        require(miner != address(0), "IUSD: Zero address");
        miners[miner] += amount;
        emit IncreaseMiner(miner, amount);
    }

    function decreaseMiner(address miner, uint256 amount) external onlyOwner {
        uint256 approvedAmount = miners[miner];
        if (amount >= approvedAmount) {
            miners[miner] = 0;
            emit DecreaseMiner(miner, approvedAmount);
        } else {
            miners[miner] -= amount;
            emit DecreaseMiner(miner, amount);
        }
    }

    function delegateMiner(address to, uint256 amount) external {
        address user = msg.sender;
        require(miners[user] >= amount, "IUSD: Not enough approval amount");

        miners[user] -= amount;
        miners[to] += amount;

        emit DelegateMiner(msg.sender, to, amount);
    }

    function rescue(address from, address to) external onlyOwner {
        require(from.code.length > 0, "IUSD: From account must be a contract");

        uint256 balance = balanceOf(from);
        _transfer(from, to, balance);
        emit Rescue(from, to, balance);
    }
}