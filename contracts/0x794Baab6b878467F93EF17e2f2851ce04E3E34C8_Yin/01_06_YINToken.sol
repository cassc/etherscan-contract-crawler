// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract Yin is ERC20, Ownable {
    using SafeMath for uint256;

    uint256 public maximumTotalSupply;
    uint256 public trackedTotalySupply;

    constructor(uint256 _maximumTotalSupply) ERC20("YIN Finance", "YIN") {
        maximumTotalSupply = _maximumTotalSupply;
        trackedTotalySupply = 0;
    }

    function mint(address account, uint256 amount) external onlyOwner {
        require(trackedTotalySupply.add(amount) <= maximumTotalSupply, "maximum minted");
        trackedTotalySupply = trackedTotalySupply.add(amount);
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external onlyOwner {
        _burn(account, amount);
    }
}