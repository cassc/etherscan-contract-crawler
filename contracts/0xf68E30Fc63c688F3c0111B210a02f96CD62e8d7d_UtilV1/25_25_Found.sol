// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Found is Ownable, ERC20 {
    address private _delegate;
    uint private _start;
    uint private _bonus;
    uint private _claim;

    uint public constant PRESALE = 7 days;
    uint public constant VESTING = 45 days;

    event Mint(
        address indexed to,
        uint amount,
        uint timestamp
    );

    event Swap(
        address indexed from,
        address indexed to,
        uint foundAmount,
        uint etherAmount,
        uint timestamp
    );

    event Claim(
        address indexed to,
        uint amount,
        uint timestamp
    );

    function totalBonus() external view returns (uint) {
        return _bonus;
    }

    function totalClaim() external view returns (uint) {
        return _claim;
    }

    function startTime() external view returns (uint) {
        return _start;
    }

    function delegate() external view returns (address) {
        return _delegate;
    }

    function balance() external view returns (uint) {
        return address(this).balance;
    }

    function mint(address to) external payable {
        _mintFound(to, msg.value * 1000);
    }

    function mintAndApprove(address to, address spender, uint256 amount) external payable {
        _mintFound(to, msg.value * 1000);
        _approve(msg.sender, spender, amount);
    }

    function premint(address to) external payable {
        _premint(to, msg.value);
    }

    function premintAndApprove(address to, address spender, uint256 amount) external payable {
        _premint(to, msg.value);
        _approve(msg.sender, spender, amount);
    }

    function swap(address from, address to, uint amount) external {
        require(
            block.timestamp > _start + VESTING,
            "Please wait to swap FOUND"
        );

        require(amount > 0, "Please burn more than 0");
        uint value = foundtoEther(amount);

        _burn(from, amount);
        (bool success, ) = to.call{value:value}("");
        require(success, "Transfer failed");

        emit Swap(from, to, amount, value, block.timestamp);
    }

    function foundtoEther(uint amount) public view returns (uint) {
        uint total = totalSupply();
        if (total == 0) return 0;

        require(total >= amount, "Swap exceeds total supply");

        uint limit = _claim + _bonus;
        uint found = total - limit;
        uint value = address(this).balance;

        if (total - amount > limit) {
            return value * amount / found;
        }

        return value * amount / total; 
    }

    function _premint(address to, uint value) internal {
        require(
            block.timestamp < _start + PRESALE, 
            "Premint is not open"
        );

        _bonus += value * 1023;
        _mintFound(to, value * 2023);
    }

    function _mintFound(address to, uint amount) internal {
        require(amount > 0, "Please mint more than 0");
        _mint(to, amount);
        
        emit Mint(
            to, 
            amount, 
            block.timestamp
        );
    }

    modifier onlyOwnerOrDelegate {
        require(
            msg.sender == owner()
            || msg.sender == _delegate,
            "Caller is not the owner or delegate"
        );
        _;
    }

    function claim(address to, uint amount) external onlyOwnerOrDelegate {    
        uint totalMint = totalSupply() - _claim;
        require(
            totalMint / 10 >= amount + _claim, 
            "Claim is too large"
        );

        _claim += amount;
        _mintFound(to, amount);

        emit Claim(to, amount, block.timestamp);
    }

    function setDelegate(address delegate_) external onlyOwnerOrDelegate {
        _delegate = delegate_;
    }

    constructor(address delegate_) ERC20("FOUND", "FOUND") {
        _delegate = delegate_;
        _start = block.timestamp;
    }
}