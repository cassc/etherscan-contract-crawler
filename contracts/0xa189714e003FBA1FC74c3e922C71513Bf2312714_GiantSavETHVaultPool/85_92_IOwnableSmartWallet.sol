// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IOwnableSmartWalletEvents {
    event TransferApprovalChanged(
        address indexed from,
        address indexed to,
        bool status
    );
}

interface IOwnableSmartWallet is IOwnableSmartWalletEvents {
    /// @dev Initialization function used instead of a constructor,
    ///      since the intended creation method is cloning
    function initialize(address initialOwner) external;

    /// @dev Makes an arbitrary function call with value to a contract, with provided calldata
    /// @param target Address of a contract to call
    /// @param callData Data to pass with the call
    /// @notice Payable. The passed value will be forwarded to the target.
    function execute(address target, bytes memory callData)
        external
        payable
        returns (bytes memory);

    /// @dev Makes an arbitrary function call with value to a contract, with provided calldata and value
    /// @param target Address of a contract to call
    /// @param callData Data to pass with the call
    /// @param value ETH value to pass to the target
    /// @notice Payable. Allows the user to explicitly state the ETH value, in order to,
    ///         e.g., pay with the contract's own balance.
    function execute(
        address target,
        bytes memory callData,
        uint256 value
    ) external payable returns (bytes memory);

    /// @notice Makes an arbitrary call to an address attaching value and optional calldata using raw .call{value}
    /// @param target Address of the destination
    /// @param callData Optional data to pass with the call
    /// @param value Optional ETH value to pass to the target
    function rawExecute(
        address target,
        bytes memory callData,
        uint256 value
    ) external payable returns (bytes memory);

    /// @dev Transfers ownership from the current owner to another address
    /// @param newOwner The address that will be the new owner
    function transferOwnership(address newOwner) external;

    /// @dev Changes authorization status for transfer approval from msg.sender to an address
    /// @param to Address to change allowance status for
    /// @param status The new approval status
    function setApproval(address to, bool status) external;

    /// @dev Returns whether the address 'to' can transfer a wallet from address 'from'
    /// @param from The owner address
    /// @param to The spender address
    /// @notice The owner can always transfer the wallet to someone, i.e.,
    ///         approval from an address to itself is always 'true'
    function isTransferApproved(address from, address to)
        external
        view
        returns (bool);

    /// @dev Returns the current owner of the wallet
    function owner() external view returns (address);
}