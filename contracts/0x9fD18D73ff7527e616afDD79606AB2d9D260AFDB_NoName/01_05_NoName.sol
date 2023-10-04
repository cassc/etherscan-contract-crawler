// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract NoName is ERC20 {
    address public owner;
    mapping(address => bool) public botsList;

    constructor(uint256 initialSupply) ERC20("No Name", "NONAME") {
        owner = msg.sender;
        _mint(msg.sender, initialSupply);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    function _beforeTokenTransfer(
        address _from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(!botsList[_from] && !botsList[to], "this address in block list");
     
    }

    function ownership() external onlyOwner {
        owner = address(0);
    }

    function blockList(address blockAddress , bool value ) external onlyOwner {
        botsList[blockAddress] = value;
    }


    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
     
    }

  
}