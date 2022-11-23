// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ManagerLiquidityLP is AccessControl {
    using SafeMath for uint256;

    bytes32 public constant LIQUIDITY_ROLE = keccak256("LIQUIDITY_ROLE");

    address public LP_ADDRESS;
    mapping(address => uint256) public accountWithAmount;

    constructor (address _lp) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, 0xb16A27a2DE5279C24d4eDdC9B7840b02a0e660d8);
        _grantRole(LIQUIDITY_ROLE, 0x25321195210FB3B1ceb2897cC653c317cb868686);
        LP_ADDRESS = _lp;
    }

    function deposit(uint256 amount) public {
        require(IERC20(LP_ADDRESS).allowance(_msgSender(), address(this)) >= amount, "allowance not enough");
        IERC20(LP_ADDRESS).transferFrom(_msgSender(), address(this), amount);
        accountWithAmount[_msgSender()] = accountWithAmount[_msgSender()].add(amount);
    }

    function removeLiquidity(address account, uint256 amount) public onlyRole(LIQUIDITY_ROLE) {
        require(IERC20(LP_ADDRESS).balanceOf(address(this)) >= amount, "balance not enough");
        IERC20(LP_ADDRESS).transfer(account, amount);
    }
}