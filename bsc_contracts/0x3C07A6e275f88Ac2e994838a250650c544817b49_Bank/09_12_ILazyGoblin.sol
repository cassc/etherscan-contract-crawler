pragma solidity 0.5.16;

interface ILazyGoblin {
    /// @dev Deposit ETH into Goblin
    function deposit() external;

    /// @dev Re-invest whatever the goblin is working on.
    function withdraw() external;

    /// @dev Return the amount of ETH the goblin holds
    function balance() external view returns (uint256);
}