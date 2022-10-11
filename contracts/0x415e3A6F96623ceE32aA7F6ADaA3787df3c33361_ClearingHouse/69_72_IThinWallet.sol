// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IThinWallet {
    error InvalidPermissions(address _user);
    error InvalidAddress();

    struct TokenMovement {
        address token;
        address recipient;
        uint256 amount;
    }

    struct EtherPaymentTransfer {
        address recipient;
        uint256 amount;
    }

    /// ### Events
    event TransferERC20(TokenMovement[] transfers);
    event TransferEther(EtherPaymentTransfer[] transfers);

    /// ### Functions
    /// @notice Initializes the thin wallet clone with the accounts that can control it
    /// @param _admin  This is should be set as the default admin. This will be the donation router
    /// @param _owners  The accounts that can call the transfer functions
    function initialize(address _admin, address[] calldata _owners) external;

    /// @notice Transfers amounts of an ERC20 to one or more recipients
    /// @dev If the `setApprove` field is true, the contract should approve that recipient for type(uint256).max
    /// @param _transfers  An array of transfers. Each transfer object specifies the amount and recipient to send tokens to
    function transferERC20(TokenMovement[] calldata _transfers) external;

    /// @notice Transfers amounts of ether to one or more recipeints
    /// @dev This should use address(recipient).call to transfer the ether
    /// @param _transfers  The ether transfers
    function transferEther(EtherPaymentTransfer[] calldata _transfers) external;

    /// @notice Transfers the current balance of a token to a destination without processing a split
    /// @param _token  The token to transfer
    /// @param _destination  The acccount to send the tokens to
    function emergencyEjectERC20(address _token, address _destination) external;

    /// @notice Transfers the current balance of Ether to the destination without processing a split
    /// @param _destination  The account to send the ether to.
    function emergencyEjectEth(address _destination) external;
}