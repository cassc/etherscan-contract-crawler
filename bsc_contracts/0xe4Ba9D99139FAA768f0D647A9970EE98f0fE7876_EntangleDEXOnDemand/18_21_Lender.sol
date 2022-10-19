//SPDX-License-Identifier: BSL 1.1

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./PausableAccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract Lender is PausableAccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant BORROWER_ROLE = keccak256("BORROWER");

    function borrow(IERC20 token, uint256 amount, address to) onlyRole(BORROWER_ROLE) whenNotPaused public {
        token.safeTransfer(to, amount);
    }
}