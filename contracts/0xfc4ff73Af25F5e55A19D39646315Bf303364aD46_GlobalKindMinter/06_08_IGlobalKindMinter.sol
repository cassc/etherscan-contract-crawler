// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/// @title An interface to split mint fees between the NiftyKit and the WETH recipient and act as proxy owner of the
///  NiftyKit contract.
/// @author skymagic
/// @custom:security-contact [email protected]
interface IGlobalKindMinter {

    /// @notice Public mint function targeting an address.
    /// @dev Mint to an address. Send Weth from the `to` address.
    /// @param to address and quantity to mint
    function mintTo(address to, uint64 quantity) external payable;

    /// @notice Public mint function
    /// @dev Mint to message sender. Send Weth from the sender address.
    /// @param quantity to mint
    function mint(uint64 quantity) external payable;

    /// @notice Admin function to transfer ownership of the underlying NiftyKit contract.
    /// @dev Use `transferOwnership` to transfer ownership of this contract instead.
    function transferOwnershipProxy(address newOwner) external;

    /// @notice Admin function to change mint price of underlying NiftyKit contract.
    function startSaleProxy(
        uint256 newMaxAmount,
        uint256 newMaxPerMint,
        uint256 newMaxPerWallet,
        uint256 newPrice,
        bool presale
    ) external;

    /// @notice Admin function to change the underlying NiftyKit contract address.
    /// @dev Must be owner to call.
    function setNiftyKit(address _niftykit) external;
    /// @notice Admin function to change the weth recipient address.
    /// @dev Must be owner to call.
    function setWethRecipient(address _wethRecipient) external;
    /// @notice Change the basis points of the mint fee that goes to the WETH recipient.
    /// @dev Must be owner to call.
    function setBasisPointsWeth(uint128 _basisPointsWeth) external;
    /// @notice Withdraw ether from the contract.
    /// @dev Must be owner to call.
    function withdraw(address payable _ethRecipient) external;
}