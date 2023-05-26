// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./KRoles.sol";

contract CanReclaimTokens is KRoles {
    using SafeERC20 for IERC20;

    mapping(address => bool) private recoverableTokensBlacklist;

    function blacklistRecoverableToken(address _token) public onlyOperator {
        recoverableTokensBlacklist[_token] = true;
    }

    /// @notice Allow the owner of the contract to recover funds accidentally
    /// sent to the contract. To withdraw ETH, the token should be set to `0x0`.
    function recoverTokens(address _token) external onlyOperator {
        require(
            !recoverableTokensBlacklist[_token],
            "CanReclaimTokens: token is not recoverable"
        );

        if (_token == address(0x0)) {
           (bool success,) = msg.sender.call{ value: address(this).balance }("");
            require(success, "Transfer Failed");
        } else {
            IERC20(_token).safeTransfer(
                msg.sender,
                IERC20(_token).balanceOf(address(this))
            );
        }
    }
}