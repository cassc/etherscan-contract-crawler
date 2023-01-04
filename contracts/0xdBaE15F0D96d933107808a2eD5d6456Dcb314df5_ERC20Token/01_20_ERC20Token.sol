// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../libraries/AntiWhaleToken.sol";
import "../libraries/ERC20Base.sol";
import "../libraries/ERC20Burnable.sol";
import "../libraries/ERC20Mintable.sol";
import "../libraries/ERC20Pausable.sol";
import "../libraries/Recoverable.sol";
import "../services/FeeProcessor.sol";

/**
 * @dev ERC20Token implementation with AccessControl, Mint, Burn, Pause, Recover, AntiWhale capabilities
 */
contract ERC20Token is
    ERC20Base,
    AntiWhaleToken,
    ERC20Burnable,
    ERC20Mintable,
    ERC20Pausable,
    AccessControl,
    Recoverable,
    FeeProcessor
{
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant EXCLUDED_FROM_ANTIWHALE_ROLE = keccak256("EXCLUDED_FROM_ANTIWHALE_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant RECOVER_ROLE = keccak256("RECOVER_ROLE");

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 initialSupply_,
        address payable feeReceiver_
    )
        payable
        ERC20Base(name_, symbol_, decimals_)
        AntiWhaleToken(initialSupply_ / 100) // 1% of supply
        FeeProcessor(feeReceiver_, 0x8f8e069ef40543d5656651a7ecd8b619bde546533ea4c3c419ca54b9381aa2a6)
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(EXCLUDED_FROM_ANTIWHALE_ROLE, _msgSender());
        if (initialSupply_ > 0) _mint(_msgSender(), initialSupply_);
    }

    /**
     * @dev Update the max token allowed per wallet.
     * only callable by members of the `DEFAULT_ADMIN_ROLE`
     */
    function setMaxTokenPerWallet(uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setMaxTokenPerWallet(amount);
    }

    /**
     * @dev returns true if address is excluded from anti whale
     */
    function isExcludedFromAntiWhale(address account) public view override returns (bool) {
        return hasRole(EXCLUDED_FROM_ANTIWHALE_ROLE, account);
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     * only callable by members of the `BURNER_ROLE`
     */
    function burn(uint256 amount) external override onlyRole(BURNER_ROLE) {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     * only callable by members of the `BURNER_ROLE`
     */
    function burnFrom(address account, uint256 amount) external override onlyRole(BURNER_ROLE) {
        _burnFrom(account, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable, AntiWhaleToken) {
        super._beforeTokenTransfer(from, to, amount);
    }

    /**
     * @dev Mint new tokens
     * only callable by members of the `MINTER_ROLE`
     */
    function mint(address account, uint256 amount) external override onlyRole(MINTER_ROLE) {
        _mint(account, amount);
    }

    /**
     * @dev Mint new tokens
     */
    function _mint(address account, uint256 amount) internal virtual override(ERC20, ERC20Mintable) {
        super._mint(account, amount);
    }

    /**
     * @dev Pause the contract
     * only callable by members of the `PAUSER_ROLE`
     */
    function pause() external override onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @dev Resume the contract
     * only callable by members of the `PAUSER_ROLE`
     */
    function resume() external override onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev Recover ETH stored in the contract
     * @param to The destination address
     * @param amount Amount to be sent
     * only callable by members of the `RECOVER_ROLE`
     */
    function recoverEth(address payable to, uint256 amount) external override onlyRole(RECOVER_ROLE) {
        _recoverEth(to, amount);
    }

    /**
     * @dev Recover tokens stored in the contract
     * @param tokenAddress The token contract address
     * @param to The destination address
     * @param tokenAmount Number of tokens to be sent
     * only callable by members of the `RECOVER_ROLE`
     */
    function recoverTokens(
        address tokenAddress,
        address to,
        uint256 tokenAmount
    ) external override onlyRole(RECOVER_ROLE) {
        _recoverTokens(tokenAddress, to, tokenAmount);
    }

    /**
     * @dev stop minting
     * only callable by members of the `DEFAULT_ADMIN_ROLE`
     */
    function finishMinting() external virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
        _finishMinting();
    }
}