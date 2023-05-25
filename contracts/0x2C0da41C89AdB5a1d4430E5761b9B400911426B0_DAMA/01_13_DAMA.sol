// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IDAMA.sol";

contract DAMA is IDAMA, ERC20Snapshot, Ownable, Pausable, ReentrancyGuard {
    address public constant KAMI = 0x001094B68DBAD2dce5E72d3F13A4ACE2184AE4B7;
    mapping(address => bool) minterRole;

    modifier onlyMinter() {
        require(minterRole[msg.sender], "You are not a minter");
        _;
    }

    constructor() ERC20("DAMA Token", "DAMA") {
        transferOwnership(KAMI);
        _mint(0x001094B68DBAD2dce5E72d3F13A4ACE2184AE4B7, 26790000 ether);
    }

    function snapshot() public onlyOwner {
        _snapshot();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function addMinterRole(address minter) public onlyOwner {
        minterRole[minter] = true;
        emit AddMinter(minter);
    }

    function removeMinterRole(address minter) public onlyOwner {
        minterRole[minter] = false;
        emit RemoveMinter(minter);
    }

    function mint(address to, uint256 amount)
        public
        override
        onlyMinter
        nonReentrant
        whenNotPaused
    {
        _mint(to, amount);
        emit MintDAMA(to, amount);
    }

    function burn(address from, uint256 amount)
        public
        override
        nonReentrant
        whenNotPaused
    {
        require(tx.origin == from, "You are not a owner");
        _burn(from, amount);
        emit BurnDAMA(from, amount);
    }
}