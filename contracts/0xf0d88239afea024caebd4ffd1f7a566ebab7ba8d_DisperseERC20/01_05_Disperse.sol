pragma solidity ^0.8;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract DisperseERC20 {
    using SafeERC20 for IERC20;

    function disperseToken(
        IERC20 token,
        address[] memory recipients,
        uint256[] memory values
    ) external {
        require(
            recipients.length == values.length,
            "disperse: bad arguments length"
        );
        for (uint256 i = 0; i < recipients.length; i++) {
            token.safeTransferFrom(msg.sender, recipients[i], values[i]);
        }
    }
}