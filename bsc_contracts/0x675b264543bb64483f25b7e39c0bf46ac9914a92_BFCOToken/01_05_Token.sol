// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract BFCOToken is ERC20 {
    
    address payable public owner;
    bool public paused;

    uint256 constant INITIAL_SUPPLY = 70000000 * 10**18;

    constructor() ERC20("Block Farm Club Origins", "BFCO") {
        _mint(msg.sender, INITIAL_SUPPLY);
        owner = payable(msg.sender);
        paused = false;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "The contract is paused");
        _;
    }

    function mint(uint256 amount) external whenNotPaused onlyOwner {
        _mint(msg.sender, amount);
    }

    function burn(uint256 amount) external whenNotPaused {
        _burn(msg.sender, amount);
    }

    function pause() public onlyOwner {
        paused = true;
    }

    function unpause() public onlyOwner {
        paused = false;
    }
}
