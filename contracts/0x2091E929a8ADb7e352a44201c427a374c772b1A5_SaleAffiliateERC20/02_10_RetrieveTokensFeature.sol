// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

/**
 * Contract that provides ETH and  ERC20 token retriever authorised by the owner
 */
contract RetrieveTokensFeature is Context, Ownable {
    using SafeERC20 for IERC20;

    /**
     * @dev Allows to transfer the whole amount of the given token to a receiver
     */
    function retrieveTokens(address to, address anotherToken) public virtual onlyOwner {
        IERC20 alienToken = IERC20(anotherToken);
        alienToken.safeTransfer(to, alienToken.balanceOf(address(this)));
    }

    /**
     * @dev Allows to transfer contract's ETH to a receiver
     */
    function retrieveETH(address payable to) public virtual onlyOwner {
        to.transfer(address(this).balance);
    }
}