// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

// It's an interface which for a standard ERC20 token
abstract contract StandardToken is ERC20 {}

// It's an interface which is a bridge between deprecated contract and a new one
abstract contract UpgradedToken is StandardToken {
    // those methods are called by the legacy contract
    // and they must ensure msg.sender to be the contract address
    function transferByLegacy(
        address from,
        address to,
        uint256 value
    ) public virtual returns (bool);

    function transferFromByLegacy(
        address sender,
        address from,
        address spender,
        uint256 value
    ) public virtual returns (bool);

    function approveByLegacy(
        address from,
        address spender,
        uint256 value
    ) public virtual returns (bool);

    function increaseAllowanceByLegacy(
        address spender, 
        uint256 addedValue
    ) public virtual returns (bool);

    function decreaseAllowanceByLegacy(
        address spender, 
        uint256 addedValue
    ) public virtual returns (bool);
}

// It's a main contract for the token
contract ERC20071122 is StandardToken, Ownable {
    uint256 private _totalSupplyInitial = 100000000000;

    address public upgradedAddress;
    bool public deprecated = false;

    mapping(address => bool) public blockedAccounts;

    event AddedBlocked(address _user);
    event RemovedBlocked(address _user);
    event Deprecate(address newAddress);

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
        require(!blockedAccounts[msg.sender]);

        if (deprecated) {
            // Forward user ERC20 methods to upgraded contract if this one is deprecated
            return UpgradedToken(upgradedAddress).transferByLegacy(msg.sender, to, amount);
        } else {
            return super.transfer(to, amount);
        }
    }

    // Overiding the transferFrom method to check if an account is blocked upon the transaction
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        require(!blockedAccounts[from]);
        require(!blockedAccounts[msg.sender]);

        if (deprecated) {
            // Forward user ERC20 methods to upgraded contract if this one is deprecated
            return UpgradedToken(upgradedAddress).transferFromByLegacy(
                    msg.sender,
                    from,
                    to,
                    amount
                );
        } else {
            return super.transferFrom(from, to, amount);
        }
    }

    // Forward user ERC20 methods to upgraded contract if this one is deprecated
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        require(!blockedAccounts[spender]);
        require(!blockedAccounts[msg.sender]);
        
        if (deprecated) {
            // Forward user ERC20 methods to upgraded contract if this one is deprecated
            return UpgradedToken(upgradedAddress).approveByLegacy(msg.sender, spender, amount);
        } else {
            return super.approve(spender, amount);
        }
    }

    function increaseAllowance(address spender, uint256 addedValue) public override virtual returns (bool) {
        require(!blockedAccounts[spender]);
        require(!blockedAccounts[msg.sender]);
        
        if (deprecated) {
            // Forward user ERC20 methods to upgraded contract if this one is deprecated
            return UpgradedToken(upgradedAddress).increaseAllowanceByLegacy(spender, addedValue);
        } else {
            return super.approve(spender, addedValue);
        }
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public override virtual returns (bool) {
        require(!blockedAccounts[spender]);
        require(!blockedAccounts[msg.sender]);
        
        if (deprecated) {
            // Forward user ERC20 methods to upgraded contract if this one is deprecated
            return UpgradedToken(upgradedAddress).decreaseAllowanceByLegacy(spender, subtractedValue);
        } else {
            return super.approve(spender, subtractedValue);
        }
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        if (deprecated) {
            // Forward user ERC20 methods to upgraded contract if this one is deprecated
            return UpgradedToken(upgradedAddress).allowance(owner, spender);
        } else {
            return super.allowance(owner, spender);
        }
    }

    function totalSupply() public view virtual override returns (uint256) {
        if (deprecated) {
            // Forward user ERC20 methods to upgraded contract if this one is deprecated
            return UpgradedToken(upgradedAddress).totalSupply();
        } else {
            return super.totalSupply();
        }
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        if (deprecated) {
            // Forward user ERC20 methods to upgraded contract if this one is deprecated
            return UpgradedToken(upgradedAddress).balanceOf(account);
        } else {
            return super.balanceOf(account);
        }
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

    // Deprecate current contract in favour of a new one
    function deprecate(address _upgradedAddress) public onlyOwner {
        deprecated = true;
        upgradedAddress = _upgradedAddress;
        emit Deprecate(_upgradedAddress);
    }
}