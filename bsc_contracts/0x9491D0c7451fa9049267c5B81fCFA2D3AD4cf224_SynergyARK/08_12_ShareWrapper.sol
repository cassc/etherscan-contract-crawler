// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract ShareWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public diamond;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _account) public view returns (uint256) {
        return _balances[_account];
    }

    function stake(uint256 _amount) public virtual {
        _totalSupply = _totalSupply.add(_amount);
        _balances[msg.sender] = _balances[msg.sender].add(_amount);
        diamond.safeTransferFrom(msg.sender, address(this), _amount);
    }

    function withdraw(uint256 _amount) public virtual {
        uint256 memberShare = _balances[msg.sender];
        require(memberShare >= _amount, "ARK: withdraw request greater than staked amount");
        _totalSupply = _totalSupply.sub(_amount);
        _balances[msg.sender] = memberShare.sub(_amount);
        diamond.safeTransfer(msg.sender, _amount);
    }
}