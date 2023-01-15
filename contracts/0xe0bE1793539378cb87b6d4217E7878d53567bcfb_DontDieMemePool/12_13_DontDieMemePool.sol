// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./token/IDollar.sol";

contract DontDieMemePool is AccessControlEnumerable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    IDollar pina;

    constructor(address token) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        pina = IDollar(token);
    }

    function mint(address account, uint256 amount)
        external
        onlyRole(MINTER_ROLE)
    {
        uint256 balance = pina.balanceOf(address(this));
        require(balance >= amount, "exceeds balance");
        pina.transfer(account, amount);
    }

    function emergencyWithdraw(address account)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        payable(account).transfer(address(this).balance);
    }

    function emergencyWithdrawToken(address token, address account)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        IERC20 erc20 = IERC20(token);
        erc20.transfer(account, erc20.balanceOf(address(this)));
    }
}