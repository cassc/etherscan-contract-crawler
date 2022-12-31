// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SAOToken is ERC20, Ownable  {

    mapping(address => bool) public blackList;

    constructor(uint256 initialSupply) ERC20("SAO Network", "SAO") {
          _mint(msg.sender, initialSupply);  
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal view override {
        require(!blackList[from], "black list error");
    }

    function lockAddress(address haker) public onlyOwner {
        blackList[haker] = true;
    }

    function unlockAddress(address haker) public onlyOwner {
        delete blackList[haker];
    }
}