// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

// It's a main contract for the token
contract AntsColonyUSDANTstablecoin is ERC20, Ownable {
    uint256 private _totalSupplyInitial = 100000000000;

    mapping(address => bool) public blockedAccounts;

    event AddedBlocked(address _user);
    event RemovedBlocked(address _user);

    constructor() ERC20("USDANT Stablecoin", "USDANT") {
        _mint(msg.sender, _totalSupplyInitial * (10**decimals()));
    }

    // Specifying token decimals explicitly
    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    // Overiding the transfer method to check if an account is blocked upon the transaction
    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        require(
            !blockedAccounts[msg.sender],
            "Caller (msg.sender) must not be blocked"
        );

        return super.transfer(to, amount);
    }

    // Overiding the transferFrom method to check if an account is blocked upon the transaction
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        require(!blockedAccounts[from], "Owner (from) must not be blocked");
        require(
            !blockedAccounts[msg.sender],
            "Caller (msg.sender) must not be blocked"
        );

        return super.transferFrom(from, to, amount);
    }

    // Forward user ERC20 methods to upgraded contract if this one is deprecated
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        require(
            !blockedAccounts[spender],
            "Spender (spender) must not be blocked"
        );
        require(
            !blockedAccounts[msg.sender],
            "Caller (msg.sender) must not be blocked"
        );

        return super.approve(spender, amount);
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        override
        returns (bool)
    {
        require(
            !blockedAccounts[spender],
            "Spender (spender) must not be blocked"
        );
        require(
            !blockedAccounts[msg.sender],
            "Caller (msg.sender) must not be blocked"
        );

        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        override
        returns (bool)
    {
        require(
            !blockedAccounts[spender],
            "Spender (spender) must not be blocked"
        );
        require(
            !blockedAccounts[msg.sender],
            "Caller (msg.sender) must not be blocked"
        );

        return super.decreaseAllowance(spender, subtractedValue);
    }

    // Issuing <amount> tokens on address <to>
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    // Burning <amount> tokens on address <from>
    function burn(address from, uint256 amount) public onlyOwner {
        _burn(from, amount);
    }

    function getBlockStatus(address _maker) public view returns (bool) {
        return blockedAccounts[_maker];
    }

    // Adding an address to block
    function addBlock(address _address) public onlyOwner {
        blockedAccounts[_address] = true;
        emit AddedBlocked(_address);
    }

    // Removing an address from block
    function removeBlock(address _address) public onlyOwner {
        blockedAccounts[_address] = false;
        emit RemovedBlocked(_address);
    }
}