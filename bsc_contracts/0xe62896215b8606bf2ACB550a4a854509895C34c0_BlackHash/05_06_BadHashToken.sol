// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BlackHash is ERC20, Ownable {
    uint256 public maxSupply = 100_000_000 * 10 ** 6;

    constructor() ERC20("BlackHash", "BLH") Ownable() { }
    
    function mint(address to, uint256 amount) external onlyOwner {
        require(totalSupply()+amount<=maxSupply,"Max total supply exceeds");
        _mint(to, amount);
    }
    function burn(uint256 amount) external {
        require(balanceOf(msg.sender)>= amount,"insufficient balance");
        _burn(msg.sender, amount);
    }
}