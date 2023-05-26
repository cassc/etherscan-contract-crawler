// Be name Khoda
// Bime Abolfazl

// SPDX-License-Identifier: GPL-2.0-or-later

interface IDEUSToken {
    function setDEIAddress(address dei_contract_address) external;
    function mint(address to, uint256 amount) external;

    // This function is what other dei pools will call to mint new DEUS (similar to the DEI mint)
    function pool_mint(address m_address, uint256 m_amount) external;

    // This function is what other dei pools will call to burn DEUS
    function pool_burn_from(address b_address, uint256 b_amount) external;

    function toggleVotes() external;

    /* ========== OVERRIDDEN PUBLIC FUNCTIONS ========== */

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /* ========== PUBLIC FUNCTIONS ========== */

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint96);

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint256 blockNumber)
        external
        view
        returns (uint96);
}

//Dar panah khoda