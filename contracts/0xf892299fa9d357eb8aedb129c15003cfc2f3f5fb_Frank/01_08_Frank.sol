// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/[email protected]/security/Pausable.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract Frank is ERC20, ERC20Burnable, Pausable, Ownable 
{
    uint256 private constant TOTAL_SUPPLY = 500_000_000_000 ether;
    uint256 private constant MAX_BUY = 100_000_000 ether;

    bool private _unrestricted;
    bool private _limitBuys;
    bool private _blockSandwich;

    mapping(address => uint) private _lastBlockTransfer;

    address public uniswapV2Pair;

    constructor() ERC20("Frank", "FRANK") 
    {
        _mint(msg.sender, TOTAL_SUPPLY);
        _unrestricted = false;
        _limitBuys = true;
        _blockSandwich = true;
        _pause();
    }

    function pause() public onlyOwner 
    {
        _pause();
    }

    function unpause() public onlyOwner 
    {
        _unpause();
    }

    function setBlockSandwich(bool _value) external onlyOwner 
    {
        _blockSandwich = _value;
    }

    function setLimitBuys(bool _value) external onlyOwner 
    {
        _limitBuys = _value;
    }

    function setUnrestricted(bool _value) external onlyOwner 
    {
        _unrestricted = _value;
    }

    function setPool(address _address) external onlyOwner 
    {       
        uniswapV2Pair = _address;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal whenNotPaused override
    {
        require(amount > 0, "No zero transfer");

        super._beforeTokenTransfer(from, to, amount);

        if (_unrestricted) { return; }

        if (uniswapV2Pair == address(0)) {
            require(from == owner() || to == owner(), "Trading not started");
        }

        bool isBuy = (from == uniswapV2Pair);
        bool isSell = (to == uniswapV2Pair);

        if (_limitBuys)
        {
            if (isBuy && amount > MAX_BUY) { revert ("Limit exceeded"); }
        }

        if (_blockSandwich)
        {
            if (block.number == _lastBlockTransfer[from] || block.number == _lastBlockTransfer[to])
            {
                revert("Not allowed");
            }

            if (isBuy) 
            {
                _lastBlockTransfer[to] = block.number;
            }
            else if (isSell) 
            {
                _lastBlockTransfer[from] = block.number;
            }
        }
    }
}