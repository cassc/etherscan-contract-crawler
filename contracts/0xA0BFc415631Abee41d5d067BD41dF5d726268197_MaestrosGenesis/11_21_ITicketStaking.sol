pragma solidity ^0.8.15;

interface ITicketStaking {
    struct StakeInfo {
        address depositor;
        uint8 tier;
        uint256 stakeTime;
    }

    /**
     * @notice  Stake a Maestro - Ticket NFT
     * @param   _token  Token ID of the ticket to stake
     */
    function stake(uint256 _token) external;

    /**
     * @notice  Unstake a Maestro - Ticket NFT
     * @param   _token  Token ID of the ticket to unstake
     */
    function unstake(uint256 _token) external;

    /**
     * @notice  View the time a ticket has been staking
     * @param   _token  Token ID of the ticket
     */
    function timeStaking(uint256 _token) external view returns (uint256);

    /**
     * @notice  View if a ticket is currently staked
     * @param   _token  Token ID of the ticket
     */
    function isStaked(uint256 _token) external view returns (bool);

    /**
     * @notice  View all staking information for a ticket
     * @param   _token  Token ID of the ticket
     */
    function getStakeInfo(uint256 _token)
        external
        view
        returns (StakeInfo memory);
}