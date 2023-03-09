// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract RVUSD is Initializable, OwnableUpgradeable,  ERC20Upgradeable {
    mapping(address => bool) public blacklist;

    event AddedToBlacklist(address indexed account);
    event RemovedFromBlacklist(address indexed account);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(string calldata name_, string calldata symbol_)
        public
        initializer
    {
        __Ownable_init();
        __ERC20_init(name_, symbol_);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public onlyOwner {
        _burn(from, amount);
    }

    /***************************/
    /* Blacklisting Functions */
    /***************************/

    modifier notBlacklisted(address account) {
        require(!blacklist[account], "Account is blacklisted");
        _;
    }

    function addToBlacklist(address account) external onlyOwner {
        require(!blacklist[account], "Account is already blacklisted");
        blacklist[account] = true;
        emit AddedToBlacklist(account);
    }

    function removeFromBlacklist(address account) external onlyOwner {
        require(blacklist[account], "Account is not yet blacklisted");
        blacklist[account] = false;
        emit RemovedFromBlacklist(account);
    }

    /***************************/
    /* Blacklisting overrides */
    /***************************/

    function transfer(address recipient, uint256 amount)
        public
        override
        notBlacklisted(msg.sender)
        notBlacklisted(recipient)
        returns (bool)
    {
        return super.transfer(recipient, amount);
    }

    function approve(address spender, uint256 amount)
        public
        override
        notBlacklisted(msg.sender)
        notBlacklisted(spender)
        returns (bool)
    {
        return super.approve(spender, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    )
        public
        override
        notBlacklisted(msg.sender)
        notBlacklisted(sender)
        notBlacklisted(recipient)
        returns (bool)
    {
        return super.transferFrom(sender, recipient, amount);
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        override
        notBlacklisted(msg.sender)
        notBlacklisted(spender)
        returns (bool)
    {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        override
        notBlacklisted(msg.sender)
        notBlacklisted(spender)
        returns (bool)
    {
        return super.decreaseAllowance(spender, subtractedValue);
    }
}