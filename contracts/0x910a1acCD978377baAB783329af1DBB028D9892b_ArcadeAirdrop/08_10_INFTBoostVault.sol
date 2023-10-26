// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "../libraries/NFTBoostVaultStorage.sol";

interface INFTBoostVault {
    /**
     * @notice Events
     */
    event MultiplierSet(address tokenAddress, uint128 tokenId, uint128 multiplier, uint128 expiration);
    event WithdrawalsUnlocked();
    event AirdropContractUpdated(address newAirdropContract);

    /**
     * @notice View functions
     */
    function getIsLocked() external view returns (uint256);

    function getRegistration(address who) external view returns (NFTBoostVaultStorage.Registration memory);

    function getMultiplier(address tokenAddress, uint128 tokenId) external view returns (uint128);

    function getMultiplierExpiration(address tokenAddress, uint128 tokenId) external view returns (uint128);

    function getAirdropContract() external view returns (address);

    /**
     * @notice NFT boost vault functionality
     */
    function addNftAndDelegate(uint128 amount, uint128 tokenId, address tokenAddress, address delegatee) external;

    function airdropReceive(address user, uint128 amount, address delegatee) external;

    function delegate(address to) external;

    function withdraw(uint128 amount) external;

    function addTokens(uint128 amount) external;

    function withdrawNft() external;

    function updateNft(uint128 newTokenId, address newTokenAddress) external;

    function updateVotingPower(address[] memory userAddresses) external;

    /**
     * @notice Only Manager function
     */
    function setMultiplier(address tokenAddress, uint128 tokenId, uint128 multiplierValue, uint128 expiration) external;

    /**
     * @notice Only Timelock function
     */
    function unlock() external;

    /**
     * @notice Only Airdrop contract function
     */
    function setAirdropContract(address _newAirdropContract) external;
}