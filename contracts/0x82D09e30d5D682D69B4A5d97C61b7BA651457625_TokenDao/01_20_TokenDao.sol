// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../lib/openzeppelin-contracts/contracts/security/Pausable.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "./TokenRescuer.sol";
import "./Allocator.sol";

/// @custom:security-contact [email protected]
contract TokenDao is ERC20, Pausable, Ownable, ERC20Permit, ERC20Votes, TokenRescuer, Allocator {
    constructor(address owner) ERC20("TokenDao", "TKN") ERC20Permit("TokenDao") {
        // Transfer ownership immediately
        _transferOwnership(msg.sender);

        _mint(owner, 1000000000 * 10 ** decimals());

        _transferOwnership(owner);
        // Contract is paused by default
        // This has to be done after _mint, else minting will fail
        _pause();
    }

    function pause() public view onlyOwner {
        revert("TokenDao: TRANSFERS CAN'T BE DISABLED, ONCE ACTIVATED.");
        // _pause();
    }

    function unpause() public onlyOwner {
        require(paused(), "TokenDao: Token is not paused");
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        super._beforeTokenTransfer(from, to, amount);

        require(to != address(this), "TokenDao: Cannot transfer tokens to token contract");
        // Token transfers are only possible if the contract is not paused
        // OR if triggered by the owner of the contract
        require(!paused() || owner() == _msgSender() || allocatorRole() == _msgSender(), "TokenDao: Token transfers are paused");
    }

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}