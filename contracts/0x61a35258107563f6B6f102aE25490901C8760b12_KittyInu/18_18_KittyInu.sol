// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";


error blockedAddress();
contract KittyInu is
    ERC20, 
    ERC20Burnable, 
    ERC20Snapshot, 
    Ownable,
    Pausable,
    ERC20Permit 
{
        
    string public constant NAME = "Kitty Inu";
    string public constant SYMBOL = "kitty";

    uint256 public tSupply = 731_738_978_480;

    bool public transferProtection = false;
    mapping(address => bool) private blockedTransfers;

    constructor() ERC20(NAME, SYMBOL) ERC20Permit(NAME) {
        _mint(msg.sender, tSupply * 10 ** decimals());
    }

    function snapshot() public onlyOwner {
        _snapshot();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setBlockedAddresses(address account, bool blocked) public onlyOwner {
        blockedTransfers[account] = blocked;
    }

    function setProtectionSettingsTransfer(bool transferProtect) external onlyOwner {
        transferProtection  = transferProtect;
    }

    function isBlocked(address account) public view returns (bool) {
        return blockedTransfers[account];
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override(ERC20, ERC20Snapshot)
    {
        if(transferProtection){
            if(blockedTransfers[from] || blockedTransfers[to]) revert blockedAddress();
        }
        super._beforeTokenTransfer(from, to, amount);
    }
}