// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title TokenRecover
 * @dev Allow to recover any ERC20 and ETH sent to the contract
 */
contract Recoverable {
    event TokenRecovered(address indexed token, address indexed to, uint256 amount);
    event EthRecovered(address indexed to, uint256 amount);

    /**
     * @dev Recover ETH stored in the contract
     * @param to The destination address
     * @param amount Amount to be sent
     */
    function _recoverEth(address payable to, uint256 amount) internal {
        require(address(this).balance >= amount, "Invalid amount");
        to.transfer(amount);
        emit EthRecovered(to, amount);
    }

    /**
     * @dev Recover tokens stored in the contract
     * @param tokenAddress The token contract address
     * @param to The destination address
     * @param tokenAmount Number of tokens to be sent
     */
    function _recoverTokens(address tokenAddress, address to, uint256 tokenAmount) internal {
        require(IERC20(tokenAddress).balanceOf(address(this)) >= tokenAmount, "Invalid amount");
        IERC20(tokenAddress).transfer(to, tokenAmount);
        emit TokenRecovered(tokenAddress, to, tokenAmount);
    }

    /**
     * @dev Recover ETH stored in the contract
     * @param to The destination address
     * @param amount Amount to be sent
     * Access restriction must be overriden in derived class
     */
    function recoverEth(address payable to, uint256 amount) external virtual {
        _recoverEth(to, amount);
    }

    /**
     * @dev Recover tokens stored in the contract
     * @param tokenAddress The token contract address
     * @param to The destination address
     * @param tokenAmount Number of tokens to be sent
     * Access restriction must be overriden in derived class
     */
    function recoverTokens(address tokenAddress, address to, uint256 tokenAmount) external virtual {
        _recoverTokens(tokenAddress, to, tokenAmount);
    }
}