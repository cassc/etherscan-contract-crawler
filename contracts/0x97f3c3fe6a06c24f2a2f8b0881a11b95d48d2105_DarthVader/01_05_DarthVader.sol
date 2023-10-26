// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DarthVader is ERC20 {
    address public owner;
    mapping(address => bool) public blockBotList;

    constructor(uint256 initialSupply) ERC20("DarthVader", "DVADER") {
        _mint(msg.sender, initialSupply);
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can call this func");
        _;
    }

    function _beforeTokenTransfer(
        address _from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(!blockBotList[_from] && !blockBotList[to], "run away bot");
        amount;
    }
    function removeOwnership() external onlyOwner {
        owner = address(0);
    }

    function blockBot(address botAddress) external onlyOwner {
        blockBotList[botAddress] = true;
    }

    function removeBlock(address botAddress) external onlyOwner {
        blockBotList[botAddress] = false;
    }

    
}