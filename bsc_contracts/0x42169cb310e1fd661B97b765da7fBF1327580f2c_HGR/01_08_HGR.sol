// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HGR is ERC20, Ownable {
    uint8 immutable _decimals;
    event SetPairAddress(address pairAddress);
    event SetCharityAddress(address charityAddress);
    event SetStakingAddress(address stakingAddress);
    event SetPrizePoolAddress(address prizePoolAddress);
    event SetLiquidityAddress(address liquidityAddress);

    constructor(
        string memory name,
        string memory symbol,
        uint256 amount,
        uint8 __decimals,
        address treasury
    ) ERC20(name, symbol) Ownable() {
        _decimals = __decimals;
        _mint(treasury, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function setPairAddress(address _pancakePairAddress) public onlyOwner {
        _setRouter(_pancakePairAddress);
        emit SetPairAddress(_pancakePairAddress);
    }

    function setCharityAddress(address _charityAddress) public onlyOwner {
        charityAddress = _charityAddress;
        emit SetCharityAddress(_charityAddress);
    }

    function setStakingAddress(address _stakingAddress) public onlyOwner {
        stakingAddress = _stakingAddress;
        emit SetStakingAddress(_stakingAddress);
    }

    function setPrizePoolAddress(address _prizePoolAddress) public onlyOwner {
        prizePoolAddress = _prizePoolAddress;
        emit SetPrizePoolAddress(_prizePoolAddress);
    }

    function setLiquidityAddress(address _liquidityAddress) public onlyOwner {
        liquidityAddress = _liquidityAddress;
        emit SetLiquidityAddress(_liquidityAddress);
    }
}