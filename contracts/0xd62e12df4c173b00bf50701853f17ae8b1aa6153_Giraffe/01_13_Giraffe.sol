// bep20 token
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Giraffe is ERC20, ERC20Burnable, ERC20Snapshot, Ownable {
    
    using SafeMath for uint;

    uint256 private totalTokens;

    constructor() ERC20("Giraffe Club", "GIRA") {
        totalTokens = 1000000 * 10 ** 6 * 10 ** uint256(decimals()); // 1000B
        _mint(owner(), totalTokens);  
    }

    function snapshot() external onlyOwner {
        _snapshot();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Snapshot)
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function getBurnedAmountTotal() external view returns (uint256 _amount) {
        return totalTokens.sub(totalSupply());
    }
}