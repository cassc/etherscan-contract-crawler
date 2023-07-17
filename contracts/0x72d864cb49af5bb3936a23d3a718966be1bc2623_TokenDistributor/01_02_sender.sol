pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenDistributor {
    IERC20 public token = IERC20(0xb2fd1E0478Dbf61772996bcCE8A2F1151EEeda37);

    function distributeTokens(address[] memory recipients) public {
        for (uint i = 0; i < recipients.length; i++) {
            require(token.transferFrom(msg.sender, recipients[i], 1 * 10**18), "Transfer failed.");
        }
    }
}