// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";

import "./interfaces/IBlurPool.sol";

/**
 * @title BlurPool
 * @dev ETH pool; funds can only be transferred by Exchange or Swap or Blend
 */
contract BlurPool is IBlurPool, OwnableUpgradeable, UUPSUpgradeable {
    address private constant EXCHANGE = 0x000000000000Ad05Ccc4F10045630fb830B95127;
    address private constant SWAP = 0x39da41747a83aeE658334415666f3EF92DD0D541;
    address private constant BLEND = 0x29469395eAf6f95920E59F858042f0e28D98a20B;

    mapping(address => uint256) private _balances;

    string public constant name = 'Blur Pool';
    string constant symbol = '';

    // required by the OZ UUPS module
    function _authorizeUpgrade(address) internal override onlyOwner {}

    constructor() {
        _disableInitializers();
    }

    /* Constructor (for ERC1967) */
    function initialize() external initializer {
        __Ownable_init();
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function totalSupply() external view returns (uint256) {
        return address(this).balance;
    }

    function balanceOf(address user) external view returns (uint256) {
        return _balances[user];
    }

    /**
     * @dev receive deposit function
     */
    receive() external payable {
        deposit();
    }

    /**
     * @dev deposit ETH into pool
     */
    function deposit() public payable {
        _balances[msg.sender] += msg.value;
        emit Transfer(address(0), msg.sender, msg.value);
    }

    /**
     * @dev deposit ETH into pool on behalf of user
     * @param user Address to deposit to
     */
    function deposit(address user) public payable {
        if (msg.sender != BLEND) {
            revert('Unauthorized deposit');
        }
        _balances[user] += msg.value;
        emit Transfer(address(0), user, msg.value);
    }

    /**
     * @dev withdraw ETH from pool
     * @param amount Amount to withdraw
     */
    function withdraw(uint256 amount) external {
        uint256 balance = _balances[msg.sender];
        require(balance >= amount, "Insufficient funds");
        unchecked {
            _balances[msg.sender] = balance - amount;
        }
        (bool success,) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
        emit Transfer(msg.sender, address(0), amount);
    }

    /**
     * @dev withdraw ETH from pool on behalf of user; only callable by Blend
     * @param from Address to withdraw from
     * @param to Address to withdraw to
     * @param amount Amount to withdraw
     */
    function withdrawFrom(address from, address to, uint256 amount) external {
        if (msg.sender != BLEND) {
            revert('Unauthorized transfer');
        }
        uint256 balance = _balances[from];
        require(balance >= amount, "Insufficient balance");
        unchecked {
            _balances[from] = balance - amount;
        }
        (bool success,) = payable(to).call{value: amount}("");
        require(success, "Transfer failed");
        emit Transfer(from, address(0), amount);
    }

    /**
     * @dev transferFrom Transfer balances within pool; only callable by Swap, Exchange, and Blend
     * @param from Pool fund sender
     * @param to Pool fund recipient
     * @param amount Amount to transfer
     */
    function transferFrom(address from, address to, uint256 amount)
        external
        returns (bool)
    {
        if (msg.sender != EXCHANGE && msg.sender != SWAP && msg.sender != BLEND) {
            revert('Unauthorized transfer');
        }
        _transfer(from, to, amount);

        return true;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(to != address(0), "Cannot transfer to 0 address");
        uint256 balance = _balances[from];
        require(balance >= amount, "Insufficient balance");
        unchecked {
            _balances[from] = balance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }
}