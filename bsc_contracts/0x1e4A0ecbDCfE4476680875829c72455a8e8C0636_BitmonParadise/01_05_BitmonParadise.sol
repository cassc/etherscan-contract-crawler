// contracts/token/BitmonParadise.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BitmonParadise is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        address _owner
    ) ERC20(string(_name), string(_symbol)) {
        require(_totalSupply > 0, "TotalSupply is 0");
        require(_owner != address(0), "Owner is zero address");
        _mint(_owner, _totalSupply);
    }
}