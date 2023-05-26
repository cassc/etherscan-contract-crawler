// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../libraries/ERC20Base.sol";
import "../libraries/Recoverable.sol";
import "../services/FeeProcessor.sol";

/**
 * @dev ERC20Token implementation with Recover capabilities
 */
contract ERC20Token is ERC20Base, Ownable, Recoverable, FeeProcessor {
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 initialSupply_,
        address payable feeReceiver_
    )
        payable
        ERC20Base(name_, symbol_, decimals_)
        FeeProcessor(feeReceiver_, 0x7835d75a511237f20e961ff42e7d4fa653cfdf61f0f1546f6b045a64df4d0017)
    {
        require(initialSupply_ > 0, "ERC20Token: initial supply cannot be zero");
        _mint(_msgSender(), initialSupply_);
    }

    /**
     * @dev Recover ETH stored in the contract
     * @param to The destination address
     * @param amount Amount to be sent
     * only callable by `owner()`
     */
    function recoverEth(address payable to, uint256 amount) external override onlyOwner {
        _recoverEth(to, amount);
    }

    /**
     * @dev Recover tokens stored in the contract
     * @param tokenAddress The token contract address
     * @param to The destination address
     * @param tokenAmount Number of tokens to be sent
     * only callable by `owner()`
     */
    function recoverTokens(address tokenAddress, address to, uint256 tokenAmount) external override onlyOwner {
        _recoverTokens(tokenAddress, to, tokenAmount);
    }
}