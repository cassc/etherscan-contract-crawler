// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract SoToken is ERC20Burnable, Pausable, Ownable, ReentrancyGuard {
    uint256 private constant MAX_SUPPLY = 100 * (10**9) * (10**18);
    mapping(address => bool) public transferWhitelist;

    constructor() ERC20('SomniLife', 'SO') {
        setTransferWhitelist(address(0), true);
        pause();
    }

    function mint(address account, uint256 amount) public virtual onlyOwner {
        require(totalSupply() + amount <= MAX_SUPPLY, 'Exceed max supply');
        _mint(account, amount);
    }

    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    function setTransferWhitelist(address member, bool enable) public onlyOwner {
        transferWhitelist[member] = enable;
    }

    function setTransferWhitelist(address[] calldata members, bool enable) public onlyOwner {
        for (uint256 i; i < members.length; i++) {
            setTransferWhitelist(members[i], enable);
        }
    }

    function setTransferWhitelist(address[] calldata members, bool[] calldata enables) public onlyOwner {
        require(members.length == enables.length, 'length error');
        for (uint256 i; i < members.length; i++) {
            setTransferWhitelist(members[i], enables[i]);
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        require(!paused() || transferWhitelist[from], 'Token transfer while paused');
    }
}