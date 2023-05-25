// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";


abstract contract StandardToken is Context, AccessControl, Pausable {
    using SafeMath for uint256;
    uint256 private _totalSupply = 0;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    bytes32 public constant PAUSE_MANAGER_ROLE = keccak256("PAUSE_MANAGER_ROLE");


    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }


    function name() public view returns(string memory) {
        return _name;
    }


    function symbol() public view returns(string memory) {
        return _symbol;
    }


    function decimals() public view returns(uint8) {
        return _decimals;
    }


    function totalSupply() public view returns(uint256) {
        return _totalSupply;
    }


    function balanceOf(address account) public virtual view returns(uint256);


    function transfer(address recipient, uint256 amount) public virtual returns(bool);


    function pause() public {
        require(hasRole(PAUSE_MANAGER_ROLE, msg.sender), "StandardToken: must have pauser manager role to pause");
        _pause();
    }


    function unpause() public {
        require(hasRole(PAUSE_MANAGER_ROLE, msg.sender), "StandardToken: must have pauser manager role to unpause");
        _unpause();
    }


    function _beforeTokenTransfer(address from, address to, uint256 amount) internal view {
        require(!paused(), "StandardToken: token transfer while paused");
        require(from != address(0), "StandardToken: transfer from the zero address");
        require(to != address(0), "StandardToken: transfer to the zero address");
    }


    function setTotalSupply(uint256 amount) internal {
        _totalSupply = amount;
    }


    function increaseTotalSupply(uint256 amount) internal {
        _totalSupply = _totalSupply.add(amount);
    }


    function decreaseTotalSupply(uint256 amount) internal {
        _totalSupply = _totalSupply.sub(amount);
    }
}