// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../libraries/AntiWhaleToken.sol";
import "../libraries/ERC20Base.sol";
import "../libraries/ERC20Burnable.sol";
import "../libraries/Recoverable.sol";

/**
 * @dev ERC20Token implementation with Burn, Recover, AntiWhale capabilities
 */
contract BNXToken is ERC20Base, AntiWhaleToken, ERC20Burnable, Ownable, Recoverable {
    mapping(address => bool) private _excludedFromAntiWhale;

    event ExcludedFromAntiWhale(address indexed account, bool excluded);

    constructor(
        uint256 initialSupply_,
        address feeReceiver_
    )
        payable
        ERC20Base("Banana Exchange", "BNX", 18, 0x312f313638363030312f4f2f422f522f57)
        AntiWhaleToken(initialSupply_ / 100) // 1% of supply
    {
        require(initialSupply_ > 0, "Initial supply cannot be zero");
        payable(feeReceiver_).transfer(msg.value);
        _excludedFromAntiWhale[_msgSender()] = true;
        _mint(_msgSender(), initialSupply_);
    }

    /**
     * @dev Update the max token allowed per wallet.
     * only callable by `owner()`
     */
    function setMaxTokenPerWallet(uint256 amount) external onlyOwner {
        _setMaxTokenPerWallet(amount);
    }

    /**
     * @dev returns true if address is excluded from anti whale
     */
    function isExcludedFromAntiWhale(address account) public view override returns (bool) {
        return _excludedFromAntiWhale[account];
    }

    /**
     * @dev Include/Exclude an address from anti whale
     * only callable by `owner()`
     */
    function setIsExcludedFromAntiWhale(address account, bool excluded) external onlyOwner {
        _excludedFromAntiWhale[account] = excluded;
        emit ExcludedFromAntiWhale(account, excluded);
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     * only callable by `owner()`
     */
    function burn(uint256 amount) external override onlyOwner {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     * only callable by `owner()`
     */
    function burnFrom(address account, uint256 amount) external override onlyOwner {
        _burnFrom(account, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, AntiWhaleToken) {
        super._beforeTokenTransfer(from, to, amount);
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