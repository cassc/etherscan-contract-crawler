// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

abstract contract Recoverable is Ownable {
    using SafeERC20 for IERC20;

    event NonFungibleTokenRecovery(address indexed token, uint256 tokenId);
    event TokenRecovery(address indexed token, uint256 amount);
    event EthRecovery(uint256 amount);

    /**
     * @notice Allows the owner to recover non-fungible tokens sent to the contract by mistake
     * @param token_: NFT token address
     * @param tokenId_: tokenId
     * @dev Callable by owner
     */
    function recoverNonFungibleToken(address token_, uint256 tokenId_) external virtual onlyOwner {
        IERC721(token_).transferFrom(address(this), address(msg.sender), tokenId_);
        emit NonFungibleTokenRecovery(token_, tokenId_);
    }

    /**
     * @notice Allows the owner to recover tokens sent to the contract by mistake
     * @param token_: token address
     * @dev Callable by owner
     */
    function recoverToken(address token_) external virtual onlyOwner {
        uint256 balance = IERC20(token_).balanceOf(address(this));
        require(balance != 0, "Operations: Cannot recover zero balance");

        IERC20(token_).safeTransfer(address(msg.sender), balance);
        emit TokenRecovery(token_, balance);
    }

    /**
     * @notice Allows the owner to recover ETH sent to the contract by mistake
     * @dev Callable by owner
     */
    function recoverEth() external virtual onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
        emit EthRecovery(balance);
    }
}