// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Contract is ERC20, Ownable {
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        address _owner
    ) ERC20(_name, _symbol) {
        _mint(_owner, _maxSupply);
        transferOwnership(_owner);

    }
}