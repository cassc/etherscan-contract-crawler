// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Dregn is ERC20, Ownable {
    uint256 public immutable MAX_TOKEN;

    constructor() ERC20("DREGN", "DREGN") {
        MAX_TOKEN = 100_000_000 * (10 ** uint256(decimals()));
    }

    function mint(address _to, uint256 _amount) public onlyOwner {
        require(
            MAX_TOKEN >= (totalSupply() + _amount),
            "ERC20: Max Token limit exceeds"
        );
        _mint(_to, _amount);
    }
}