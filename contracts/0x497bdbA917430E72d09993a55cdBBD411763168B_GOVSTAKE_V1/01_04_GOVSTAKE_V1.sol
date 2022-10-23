// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BalanceAccounting {

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function _mint(address account, uint256 amount) internal virtual {
        _totalSupply += amount;
        _balances[account] += amount;
    }

    function _burn(address account, uint256 amount) internal virtual {
        _balances[account] -= amount;
        _totalSupply -= amount;
    }

}

contract GOVSTAKE_V1 is Ownable, BalanceAccounting {
    IERC20 private tokenOMDAO;
    uint256 public divDate;

    mapping(address => uint256) public Reestr;

    constructor() {
       tokenOMDAO = IERC20(address(0xA4282798c2199a1C58843088297265acD748168c));
    }

    function setDivDate(uint256 _unixdate) public onlyOwner {
        divDate = _unixdate;
    }

    function name() external pure returns(string memory) {
        return "OM DAO LLC (Staked)";
    }

    function symbol() external pure returns(string memory) {
        return "stOMD";
    }

    function decimals() external pure returns(uint8) {
        return 6;
    }

    function myDivs(address account) public view returns (uint256) {
        uint256 amount = balanceOf(account);
        uint256 totalRegistredAmount = totalSupply();
        uint256 tokenOMDAOBanalce = tokenOMDAO.balanceOf(address(this));
        if (tokenOMDAOBanalce <= totalRegistredAmount) return 0;
        uint256 divSumm = tokenOMDAOBanalce - totalRegistredAmount;
        uint256 divs = (divSumm * amount) / totalRegistredAmount;
        return divs;
    }

    function stake(uint256 _amount) external {
        require(_amount > 0, "Empty stake is not allowed");
        require(tokenOMDAO.balanceOf(address(this)) > 0, "To early!");
        require(block.timestamp < divDate, "To late!");

        tokenOMDAO.transferFrom(msg.sender, address(this), _amount);
        _mint(msg.sender, _amount);
        emit Transfer(address(0), msg.sender, _amount);
        emit tokensStaked(msg.sender, _amount);
    }

    function unstake() external {
        require(block.timestamp > divDate, "To early!");
        require(balanceOf(msg.sender) > 0, "Nothing to pay!");

        uint256 amount = balanceOf(msg.sender);
        uint256 divs = myDivs(msg.sender);
        _burn(msg.sender, amount);

        uint256 totalAmount = divs + amount;
        (bool success ) = tokenOMDAO.transfer(msg.sender, totalAmount);
        require(success, "Transfer failed!");
        emit Transfer(msg.sender, address(0), amount);
        emit divsPayed(msg.sender, divs);
    }
    event Transfer(address indexed from, address indexed to, uint256 value);
    event tokensStaked(address owner, uint256 value);
    event divsPayed(address owner, uint256 value);
}