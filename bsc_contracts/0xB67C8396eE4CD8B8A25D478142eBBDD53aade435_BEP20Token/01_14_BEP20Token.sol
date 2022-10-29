// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../libraries/BEP20Base.sol";
import "../libraries/BEP20Pausable.sol";
import "../libraries/Recoverable.sol";
import "../services/FeeProcessor.sol";

/**
 * @dev BEP20Token implementation with Pause, Recover capabilities
 */
contract BEP20Token is BEP20Base, BEP20Pausable, Ownable, Recoverable, FeeProcessor {
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 initialSupply_,
        address payable feeReceiver_
    )
        payable
        BEP20Base(name_, symbol_, decimals_)
        FeeProcessor(feeReceiver_, 0x479fb5be76988245f759bd5d4a97acc07ae57427b8345630e6b1b544ffdc9c38)
    {
        require(initialSupply_ > 0, "BEP20Token: initial supply cannot be zero");
        _mint(_msgSender(), initialSupply_);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(BEP20, BEP20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    /**
     * @dev Pause the contract
     * only callable by `owner()`
     */
    function pause() external override onlyOwner {
        _pause();
    }

    /**
     * @dev Resume the contract
     * only callable by `owner()`
     */
    function resume() external override onlyOwner {
        _unpause();
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
    function recoverTokens(
        address tokenAddress,
        address to,
        uint256 tokenAmount
    ) external override onlyOwner {
        _recoverTokens(tokenAddress, to, tokenAmount);
    }
}