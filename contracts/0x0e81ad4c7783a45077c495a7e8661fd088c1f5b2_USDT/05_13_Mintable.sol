// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

abstract contract Mintable is ERC20, Ownable {

    uint256 public maxSupply;

    constructor(uint256 _maxSupply) {
        maxSupply = _maxSupply * (10 ** decimals()) / 10;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        require(totalSupply() + amount <= maxSupply, "Mintable: Cannot mint more than max supply");

        _mint(to, amount);
    }
}