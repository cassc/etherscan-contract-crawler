// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@oz/token/ERC20/ERC20.sol";
import "@oz/token/ERC20/extensions/ERC20Votes.sol";

/**
 * @title AUXO Active Reward Vault Token (ARV)
 * @notice ARV has the following key properties:
 *    1) Implements the full ERC20 standard, including optional fields name, symbol and decimals
 *    2) Is non-transferrable
 *    3) Can only be minted via staking AUXO tokens for a lock period
 *    4) Can only be burned via unstaking AUXO tokens at the end of the lock period.
 *       Note that, after a grace period, it is possible for users other than the original staker to force a user's exit.
 *    5) Each ARV token represents 1 unit of voting power in the Auxo DAO Governor contract.
 *    6) Implements the OpenZeppelin IVotes interface, including EIP-712 for gasless vote delegation.
 */
contract ARV is ERC20, ERC20Votes {
    /// @notice contract that handles locks of staked AUXO tokens, in exchange for ARV
    address public immutable tokenLocker;

    modifier onlyTokenLocker() {
        require(tokenLocker == msg.sender, "ARV: caller is not the TokenLocker");
        _;
    }

    constructor(address _tokenLocker)
        ERC20("Auxo Active Reward Vault", "ARV")
        ERC20Permit("Auxo Active Reward Vault")
    {
        tokenLocker = _tokenLocker;
    }

    /**
     * @notice supply of ARV (minting and burning) is entirely controlled
     *         by the tokenLocker contract and therefore the staking mechanism
     */
    function mint(address to, uint256 amount) external onlyTokenLocker {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyTokenLocker {
        _burn(from, amount);
    }

    /**
     * @dev Disables all transfer related functions
     */
    function _transfer(address, address, uint256) internal virtual override {
        revert("ERC20NonTransferable: Transfer not supported");
    }

    /**
     * @dev Disables all approval related functions
     */
    function _approve(address, address, uint256) internal virtual override {
        revert("ERC20NonTransferable: Approval not supported");
    }

    /// @dev the below overrides are required by Solidity

    function _afterTokenTransfer(address from, address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._burn(account, amount);
    }
}