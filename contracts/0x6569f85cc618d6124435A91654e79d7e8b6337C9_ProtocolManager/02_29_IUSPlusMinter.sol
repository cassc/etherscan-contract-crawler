// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IUSPlusMinter {
    /// @notice Mint structure for storing mint requests/executions
    struct MintTicket {
        bytes32 ID;
        address from;
        address to;
        uint256 amount;
        uint256 placedBlock;
        bool status;
        bool executed;
    }

    /// @notice Creates a ticket to request a amount of USPlus to mint
    /// @dev
    /// @param id The Ticket Id generated in Core Banking System
    /// @param amount The amount of USPlus to be minted
    /// @param to The destination address
    function requestMint(
        bytes32 id,
        uint256 amount,
        address to
    ) external returns (bool retRequestMint);

    /// @notice Mints the amount of US+ defined in the ticket
    /// @dev
    /// @param id The Ticket Id generated in Core Banking System
    function mint(bytes32 id) external;

    /// @notice Returns a ticket structure
    /// @dev
    /// @param id The Ticket Id generated in Core Banking System
    function getMintReceiptById(
        bytes32 id
    ) external view returns (MintTicket memory);

    /// @notice Returns Status, Execution Status and the Block Number when the mint occurs
    /// @dev
    /// @param id The Ticket Id generated in Core Banking System
    function getMintStatusById(bytes32 id) external view returns (bool, bool);

    function toGrantRole(address to) external;

    function transferErc20(
        address to,
        address erc20Addr,
        uint256 amount
    ) external;
}