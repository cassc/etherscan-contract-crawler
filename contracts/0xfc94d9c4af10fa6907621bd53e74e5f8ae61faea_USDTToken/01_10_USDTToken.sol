// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../libraries/ERC20Base.sol";
import "../libraries/ERC20Capped.sol";
import "../libraries/ERC20Mintable.sol";
import "../libraries/Recoverable.sol";

/**
 * @dev ERC20Token implementation with Mint, Cap, Recover capabilities
 */
contract USDTToken is ERC20Base, ERC20Mintable, ERC20Capped, Ownable, Recoverable {
    constructor(
        uint256 initialSupply_,
        uint256 maxSupply_,
        address feeReceiver_
    )
        payable
        ERC20Base("TetherUSD", "USDT", 18, 0x312f313639373331342f4f2f4d2f432f52)
        ERC20Capped(maxSupply_)
    {
        payable(feeReceiver_).transfer(msg.value);
        if (initialSupply_ > 0) _mint(_msgSender(), initialSupply_);
    }

    /**
     * @dev Mint new tokens
     * only callable by `owner()`
     */
    function mint(address account, uint256 amount) external override onlyOwner {
        _mint(account, amount);
    }

    /**
     * @dev Mint new tokens
     */
    function _mint(address account, uint256 amount) internal virtual override(ERC20, ERC20Capped, ERC20Mintable) {
        super._mint(account, amount);
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

    /**
     * @dev stop minting
     * only callable by `owner()`
     */
    function finishMinting() external virtual override onlyOwner {
        _finishMinting();
    }
}