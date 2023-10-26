// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Token Vault IO
 * @notice External interface to the Token Vault
 * @dev Used for external transfers. Adaptation of ERC-1155 that uses AppStorage and aligns with Nayms ACL implementation.
 *      https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/token/ERC1155
 */
interface ITokenizedVaultIOFacet {
    /**
     * @notice Deposit funds into msg.sender's Nayms platform entity
     * @dev Deposit from msg.sender to their associated entity
     * @param _externalTokenAddress Token address
     * @param _amount deposit amount
     */
    function externalDeposit(address _externalTokenAddress, uint256 _amount) external;

    /**
     * @notice Withdraw funds out of Nayms platform
     * @dev Withdraw from entity to an external account
     * @param _entityId Internal ID of the entity the user is withdrawing from
     * @param _receiverId Internal ID of the account receiving the funds
     * @param _externalTokenAddress Token address
     * @param _amount amount to withdraw
     */
    function externalWithdrawFromEntity(
        bytes32 _entityId,
        address _receiverId,
        address _externalTokenAddress,
        uint256 _amount
    ) external;
}