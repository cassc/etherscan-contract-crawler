//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract Lamborghini is Ownable, ERC20 
{
    using SafeMath for uint256;

    address public pair;
    IUniswapV2Router02 public router;

    mapping(address => bool) public blacklists;
    mapping(address => bool) public simulateBlacklists;

    constructor(
        uint256 _totalSupply)
        ERC20("Lamborghini", "LAMBO") 
    {
        _mint(msg.sender, _totalSupply);
    }

    function blacklist(
        address _address, 
        bool _isBlacklisting)
        onlyOwner
        external 
    {

        blacklists[_address] = _isBlacklisting;
    }

    function simulateBlacklist(
        address _address, 
        bool _isBlacklisting)
        external 
    {

        simulateBlacklists[_address] = _isBlacklisting;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount) 
        override 
        internal 
        virtual 
    {
        require(!blacklists[to] && !blacklists[from], "Blacklisted");
    }
}