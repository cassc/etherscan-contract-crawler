//SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface ILisaSettings {

    /// @notice Protocol admin address that would be able to perform protocol fee claim
    function protocolAdmin() external view returns (address);

    /// @notice The treasury wallet of LISA protocol that will receive protocol fees
    function protocolArtTreasuryAddress() external view returns (address);

    /// @notice Lisa Protocol commission for each sale taken from the total supply of Art Tokens (AT)
    /// It is taken from the total supply of AT after the successful sale. Defined in basis points. E.g. 1.23% = 123 BPS.
    function protocolATFeeBps() external view returns (uint256);

    /// @notice Lisa Protocol commission for each sale taken from the total sale price in base tokens (BT).
    /// It is taken from the proceeds after the successful sale. Defined in basis points. E.g. 1.23% = 123 BPS.
    function protocolBTFeeBps() external view returns (uint256);

    /// @notice The duration of
    function buyoutDurationSeconds() external returns (uint256);

    /// @notice Stores the logic contract address for a given contract key.
    function setLogic(
        bytes32 contractId,
        address contractAddress
    ) external;

    /// @notice Returns the logic contract address by key. All subsequent deployments of protocol contracts will use this function to get the most recent version of logic contracts.
    function getLogic(bytes32 contractId) external view returns (address);
}