// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract MdxToken is ERC20Votes, Ownable {
    uint256 public constant maxSupply = 1060000000 * 1e18;

    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private _miners;

    constructor() ERC20("MDX Token", "MDX") ERC20Permit("MDX Token") {}

    modifier onlyMiner() {
        require(isMiner(msg.sender), "caller is not the miner");
        _;
    }

    function mint(address to, uint256 amount) external onlyMiner returns (bool) {
        if (totalSupply() + amount > maxSupply) {
            return false;
        }
        _mint(to, amount);
        return true;
    }

    function burn(uint256 amount) external {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) external {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    function addMiner(address miner) external onlyOwner returns (bool) {
        require(miner != address(0), "MdxToken: miner is the zero address");
        return EnumerableSet.add(_miners, miner);
    }

    function delMiner(address miner) external onlyOwner returns (bool) {
        require(miner != address(0), "MdxToken: miner is the zero address");
        return EnumerableSet.remove(_miners, miner);
    }

    function getMinerLength() public view returns (uint256) {
        return EnumerableSet.length(_miners);
    }

    function isMiner(address account) public view returns (bool) {
        return EnumerableSet.contains(_miners, account);
    }

    function getMiner(uint256 _index) external view onlyOwner returns (address) {
        require(_index <= getMinerLength() - 1, "MdxToken: index out of bounds");
        return EnumerableSet.at(_miners, _index);
    }
}