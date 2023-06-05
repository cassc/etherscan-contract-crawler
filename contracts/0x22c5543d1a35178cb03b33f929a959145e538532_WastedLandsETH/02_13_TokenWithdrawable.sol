//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenWithdrawable is Ownable {
    using SafeERC20 for IERC20;

    mapping(address => bool) internal tokenBlacklist;
    uint256 public swapFund;
    uint256 public burnFund;

    event TokenWithdrawn(address token, uint256 amount, address to);

    /**
     * @notice Blacklists a token to be withdrawn from the contract.
     */
    function blacklistToken(address _token) public onlyOwner {
        tokenBlacklist[_token] = true;
    }

    /**
     * @notice Withdraws any tokens in the contract.
     */
    function withdrawToken(
        IERC20 token,
        uint256 amount,
        address to
    ) external onlyOwner {
        require(
            !tokenBlacklist[address(token)],
            "TokenWithdrawable: blacklisted token"
        );
        if (address(token) == address(this)) {
            require(
                token.balanceOf(address(this)) - amount >= swapFund + burnFund,
                "sufficient funds"
            );
        }
        token.safeTransfer(to, amount);
        emit TokenWithdrawn(address(token), amount, to);
    }
}