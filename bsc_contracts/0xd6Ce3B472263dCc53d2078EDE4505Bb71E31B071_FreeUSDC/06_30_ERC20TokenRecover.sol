// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IERC20TokenRecover.sol";

/**
 * @title ERC20TokenRecover
 * @dev Allows owner to recover any ERC20 or ETH sent into the contract
 * based on https://github.com/vittominacori/eth-token-recover by Vittorio Minacori
 */
contract ERC20TokenRecover is Ownable, IERC20TokenRecover {
    using SafeERC20 for IERC20;

    /**
     * @notice function that transfers an token amount from this contract to the owner when accidentally sent
     * @param tokenAddress The token contract address
     * @param tokenAmount Number of tokens to be sent
     */
    function recoverERC20(address tokenAddress, uint256 tokenAmount) public virtual override onlyOwner {
        IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
    }

    /**
     * @notice function that transfers an eth amount from this contract to the owner when accidentally sent
     * @param amount Number of eth to be sent
     */
    function recoverETH(uint256 amount) public virtual override onlyOwner {
        (bool sent, ) = owner().call{value: amount}("");
        require(sent, "ERC20TokenRecover: SENDING_ETHER_FAILED");
    }
}