// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Allows the owner to retrieve ETH or tokens sent to this contract by mistake.
 */
contract RecoverableFunds {

    function _retrieveTokens(address recipient, address tokenAddress) internal {
        IERC20 token = IERC20(tokenAddress);
        token.transfer(recipient, token.balanceOf(address(this)));
    }

    function _retrieveETH(address payable recipient) internal {
        recipient.transfer(address(this).balance);
    }

}