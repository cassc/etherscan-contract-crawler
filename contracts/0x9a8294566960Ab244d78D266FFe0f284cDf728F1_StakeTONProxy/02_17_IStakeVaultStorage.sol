//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;
pragma abicoder v2;

interface IStakeVaultStorage {
    /// @dev reward token : TOS
    function tos() external view returns (address);

    /// @dev paytoken is the token that the user stakes.
    function paytoken() external view returns (address);

    /// @dev allocated amount of TOS
    function cap() external view returns (uint256);

    /// @dev Operation type of staking amount
    function stakeType() external view returns (uint256);

    /// @dev External contract address used when operating the staking amount
    function defiAddr() external view returns (address);

    /// @dev the start block for sale.
    function saleStartBlock() external view returns (uint256);

    /// @dev the staking start block
    function stakeStartBlock() external view returns (uint256);

    /// @dev the staking end block.
    function stakeEndBlock() external view returns (uint256);

    /// @dev the staking real end block.
    function realEndBlock() external view returns (uint256);

    /// @dev reward amount per block
    function blockTotalReward() external view returns (uint256);

    /// @dev sale closed flag
    function saleClosed() external view returns (bool);

    /// @dev the total staked amount stored at orderedEndBlock’s end block time
    function stakeEndBlockTotal(uint256 endblock)
        external
        view
        returns (uint256 totalStakedAmount);
}