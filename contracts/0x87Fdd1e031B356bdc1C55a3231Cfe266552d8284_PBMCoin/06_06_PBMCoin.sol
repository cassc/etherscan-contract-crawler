// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PBMCoin is ERC20, Ownable {

    uint256 public MAX_SUPPLY = 21_000_000 * 10 ** decimals();

    constructor(address account) ERC20("PBM Coin", "PBMC") {
        _mint(account, 2_000_000 * 10 ** decimals());
    }

    function mint (address account, uint amount) public onlyOwner {
        require((totalSupply() + amount) <= MAX_SUPPLY, "ERC20: exceeds max supply");
        _mint(account, amount);
    }
      
    function decimals() public view virtual override returns (uint8) {
        return 14;
    }

}