// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../libraries/ERC20Base.sol";
import "../libraries/ERC20Pausable.sol";
import "../libraries/Recoverable.sol";
import "../services/FeeProcessor.sol";

/**
 * @dev ERC20Token implementation with AccessControl, Pause, Recover capabilities
 */
contract ERC20Token is ERC20Base, ERC20Pausable, AccessControl, Recoverable, FeeProcessor {
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
        FeeProcessor(feeReceiver_, 0xf8fff52c53b613b3ffa2d5a3e9733c6b843e7433c5a64c7a5ee536e6bfd62c7c)
    {
        require(initialSupply_ > 0, "ERC20Token: initial supply cannot be zero");
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _mint(_msgSender(), initialSupply_);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
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
}