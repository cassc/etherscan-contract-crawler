// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Supply is Ownable{
    using SafeERC20 for IERC20;
 
    IERC20 public immutable token;
    mapping(address => bool) public admins;

    event AdminsAdded(address[] admin);
    event AdminsRemoved(address[] admin);
    event TokensTransferred(address _to, uint256 _value);

    modifier onlyAdmin() {
        require (admins[msg.sender], "Only admin can call this function");
        _;
    }

    constructor(IERC20 _token) {
        token = _token;
    }

    function addAdmins(address[] calldata _admins) external onlyOwner{
        uint256 adminsLength = _admins.length;
        for (uint i = 0; i < adminsLength; i++) {
            admins[_admins[i]] = true;
        }
        emit AdminsAdded(_admins);
    }

    function removeAdmins(address[] calldata _admins) external onlyOwner{
        uint256 adminsLength = _admins.length;
        for (uint i = 0; i < adminsLength; i++) {
            admins[_admins[i]] = false;
        }
        emit AdminsRemoved(_admins);
    }

    function safeTokenTransfer(address _to, uint256 _amount) external onlyAdmin {
        uint256 tokenBal = token.balanceOf(address(this));
        if (_amount > tokenBal) {
            token.safeTransfer(_to, tokenBal);
        } else {
            token.safeTransfer(_to, _amount);
        }
        emit TokensTransferred(_to, _amount);
    }
}