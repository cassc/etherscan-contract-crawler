// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../DABotCommon.sol";
import "../interfaces/IBotVault.sol";

interface IDABotGovernModuleEvent {
    event MintGToken(address indexed account, uint amountIn, uint fee, uint amountOut, uint updatedRate);
}

interface IDABotGovernModule is IDABotGovernModuleEvent {

    /**
    @dev Creates staking vaults for governance tokens. This method should be called
        internally only by the bot manager.
     */
    function createGovernVaults() external;

    /**
    @dev Gets the vaults of governance tokens.
    @param account - the account to query depsot/reward information
     */
    function governVaults(address account) external view returns(VaultInfo[] memory);

    /**
    @dev Claims all pending governance rewards in all vaults.
     */
    function harvestGovernanceReward() external;

    /**
    @dev Queries the total pending governance rewards in all vaults
    @param account - the account to query.
     */
    function governanceReward(address account) external view returns(uint);

    /**
    @dev Gets the maximum amount of gToken that an account could mint from a bot.
    @param account - the account to query.
    @return the total mintable amount of gToken.
     */
    function mintableShare(address account) external view returns(uint);

    /** 
    @dev Gets the details accounting for the amount of mintable shares.
    @param account the account to query
    @return an array of MintableShareDetail strucs.
     */
    function iboMintableShareDetail(address account) external view returns(MintableShareDetail[] memory); 

    /**
    @dev Calculates the output for an account who mints shares with the given VICS amount.
    @param account - the account to query
    @param vicsAmount - the amount of VICS used to mint shares.
    @return payment - the amount of VICS for minting shares.
            shares - the amount of shares mintied.
            fee - the amount of VICS for minting fee. 
     */
    function calcOutShare(address account, uint vicsAmount) external view returns(uint payment, uint shares, uint fee);

    /**
    @dev Get the total balance of shares owned by the specified account. The total includes
        shares within the account's wallet, and shares staked in bot's vaults.
    @param account - the account to query.
    @return the number of shares.
     */
    function shareOf(address account) external view returns(uint);

    /**
    @dev Mints shares for the given VICS amount. Minted shares will directly stakes to BotVault for rewards.
    @param vicsAmount - the amount of VICS used to mint shared.
    @notice
        Minted shares during IBO will be locked in separated pool, which onlly allow users to withdraw
        after 1 month after the IBO ends.

        VICS for payment will be kept inside the share contracts. Whereas, VICS for fee are transfered
        to the tax address, configured in the platform configurator.
     */
    function mintShare(uint vicsAmount) external;

    /**
    @dev Burns an amount of gToken and sends the corresponding VICS to caller's wallet.
    @param amount - the amount of gToken to burn.
     */
    function burnShare(uint amount) external;

    /**
    @dev Takes a snapshot of current vote powers (i.e. amount of gov)
     */
    function snapshot() external;
}