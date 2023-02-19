// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RoyaltyForwarder is Ownable {

    // to receive royalties
    receive() external payable { _refundRoyalties(); }
    fallback() external payable { _refundRoyalties(); }

    function _refundRoyalties() internal {
        payable(tx.origin).transfer(msg.value);
    }

    /**
     * @notice Rescue tokens that were sent to this contract without using safeTransferFrom. 
     *         Only callable by the contract owner.
     */
    function rescueToken(address tokenAddress, bool erc20, uint256 id) external onlyOwner {
        if (erc20) {
            IERC20(tokenAddress).transfer(msg.sender, IERC20(tokenAddress).balanceOf(address(this)));
        } else {
            IERC721(tokenAddress).transferFrom(address(this), msg.sender, id);
        }
    }

    /**
     * @notice Rescue ETH that has inadvertently been locked in the contract. 
     *         Only callable by the contract owner.
     */
    function rescueETH() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}