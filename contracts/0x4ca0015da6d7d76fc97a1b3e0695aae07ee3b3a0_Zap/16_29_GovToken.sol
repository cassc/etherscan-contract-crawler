pragma solidity ^0.8.0;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract GovToken is ERC20, Ownable {
    uint256 public constant MAX_SUPPLY = 58750000000000000000000;

    constructor() ERC20("Phission Token", "PHI") Ownable() {}

    function mint(address to, uint256 wad) public onlyOwner {
        require(totalSupply() + wad <= MAX_SUPPLY, "Amount exceeds max supply");
        _mint(to, wad);
    }

    // burn function not needed, transfer to treasury to burn
}