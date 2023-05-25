// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract ApeXToken is ERC20Votes, Ownable {
    event AddMinter(address minter);
    event RemoveMinter(address minter);

    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private minters;
    uint256 public constant initTotalSupply = 1_000_000_000e18; // 1 billion

    // modifier for mint function
    modifier onlyMinter() {
        require(isMinter(msg.sender), "ApeXToken: CALLER_IS_NOT_THE_MINTER");
        _;
    }

    constructor() ERC20Permit("") ERC20("ApeX Token", "APEX") {
        _mint(msg.sender, initTotalSupply);
    }

    function mint(address to, uint256 amount) external onlyMinter returns (bool) {
        _mint(to, amount);
        return true;
    }

    function addMinter(address minter) external onlyOwner returns (bool) {
        require(minter != address(0), "ApeXToken.addMinter: ZERO_ADDRESS");
        emit AddMinter(minter);
        return EnumerableSet.add(minters, minter);
    }

    function removeMinter(address minter) external onlyOwner returns (bool) {
        require(minter != address(0), "ApeXToken.delMinter: ZERO_ADDRESS");
        emit RemoveMinter(minter);
        return EnumerableSet.remove(minters, minter);
    }

    function isMinter(address account) public view returns (bool) {
        return EnumerableSet.contains(minters, account);
    }

    function getMinterLength() external view returns (uint256) {
        return EnumerableSet.length(minters);
    }

    function getMinter(uint256 index) external view onlyOwner returns (address) {
        require(index <= EnumerableSet.length(minters) - 1, "ApeXToken.getMinter: OUT_OF_BOUNDS");
        return EnumerableSet.at(minters, index);
    }
}