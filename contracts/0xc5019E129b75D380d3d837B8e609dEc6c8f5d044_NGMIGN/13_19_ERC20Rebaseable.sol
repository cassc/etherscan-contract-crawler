// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "../libraries/Address.sol";
import "./Recoverable.sol";

abstract contract ERC20Rebaseable is ERC20, Recoverable {

    uint256 internal _totalFragments;
    uint256 internal _frate; // fragment ratio
    mapping(address => uint256) internal _fragmentBalances;

    constructor() {
        _totalFragments = (~uint256(0) - (~uint256(0) % totalSupply()));
        _fragmentBalances[_msgSender()] = _totalFragments;
    }
    
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _fragmentBalances[account] / fragmentsPerToken();
    }

    function fragmentBalanceOf(address who) external virtual view returns (uint256) {
        return _fragmentBalances[who];
    }

    function fragmentTotalSupply() external view returns (uint256) {
        return _totalFragments;
    }
    
    function fragmentsPerToken() public view virtual returns(uint256) {
        return _totalFragments / _totalSupply;
    }
    
    function _rTransfer(address sender, address recipient, uint256 amount) internal virtual returns(bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "can't transfer 0");
        _frate = fragmentsPerToken();
        uint256 amt = amount * _frate;
        _fragmentBalances[sender] -= amt;
        _fragmentBalances[recipient] += amt;
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _rTransfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _rTransfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

}