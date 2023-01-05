// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/access/Ownable.sol";
pragma solidity ^0.8.0;

contract IncreaseAmount is Ownable {
    mapping(uint256 => uint256) private prices;

    constructor() {
        prices[1] = 3e17;
        prices[2] = 5e17;
        prices[3] = 2e18;
        prices[4] = 5e18;
    }

    modifier checkLevel(uint16 _level) {
        require(_level > 0, "wrong level");
        _;
    }

    function incrementUnit(uint16 level, uint256 unit)
        external
        onlyOwner
        checkLevel(level)
    {
        prices[level] = unit;
    }

    function increaseAmountBy(uint16 level)
        public
        view
        checkLevel(level)
        returns (uint256)
    {
        return prices[level];
    }
}