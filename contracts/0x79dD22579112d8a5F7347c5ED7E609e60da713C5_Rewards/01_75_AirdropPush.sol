//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.11;
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AirdropPush {
    using SafeERC20 for IERC20;

    function distribute(
        IERC20 token,
        address[] calldata accounts,
        uint256[] calldata amounts
    ) external {
        require(accounts.length == amounts.length, "LENGTH_MISMATCH");
        for (uint256 i = 0; i < accounts.length; i++) {
            token.safeTransferFrom(msg.sender, accounts[i], amounts[i]);
        }
    }
}