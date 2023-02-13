// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import {IERC1155Upgradeable as IERC1155} from "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

/// @title IReceiptV1
/// @notice IReceiptV1 is an extension to IERC1155 that requires implementers to
/// provide an interface to allow an owner to UNILATERALLY (e.g. without access
/// or allowance restrictions):
///
/// - mint
/// - burn
/// - transfer
/// - emit data
///
/// The owner MUST implement `IReceiptOwnerV1` to authorize transfers and receipt
/// information. The `IReceiptV1` MUST call the relevant authorization function
/// on the owner for receipt information and standard ERC1155 transfers.
///
/// Earlier versions of `ReceiptVault` implemented the vault as BOTH an ERC1155
/// AND ERC20/4626 vault, which technically worked fine onchain but offchain
/// tooling such as MetaMask seems to only understand a contract implementing one
/// token interface. The combination of `IReceiptV1` and `IReceiptOwnerV1`
/// attempts to emulate the hybrid token model through paired interfaces.
interface IReceiptV1 is IERC1155 {
    /// Emitted when new information is provided for a receipt.
    /// @param sender `msg.sender` emitting the information for the receipt.
    /// @param id Receipt the information is for.
    /// @param information Information for the receipt. MAY reference offchain
    /// data where the payload is large.
    event ReceiptInformation(address sender, uint256 id, bytes information);

    /// The address of the `IReceiptOwnerV1`. This mimics the Open Zeppelin
    /// `Ownable.owner` function signature as it is a very common and popular
    /// implementation. `IReceiptV1` has no opinion on how ownership is
    /// implemented and managed, it only cares that there is some owner.
    /// @return account The owner account.
    function owner() external view returns (address account);

    /// The owner MAY directly mint receipts for any account, ID and amount
    /// without restriction. The data MUST be treated as both ERC1155 data and
    /// receipt information. Overflow MUST revert as usual for ERC1155.
    /// MUST REVERT if the `msg.sender` is NOT the owner. Receipt information
    /// MUST be emitted under the sender not the receiver account.
    /// @param sender The sender to emit receipt information under.
    /// @param account The account to mint a receipt for.
    /// @param id The receipt ID to mint.
    /// @param amount The amount to mint for the `id`.
    /// @param data The ERC1155 data. MUST be emitted as receipt information.
    function ownerMint(
        address sender,
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    /// The owner MAY directly burn receipts for any account, ID and amount
    /// without restriction. Underflow MUST revert as usual for ERC1155.
    /// MUST REVERT if the `msg.sender` is NOT the owner. Receipt information
    /// MUST be emitted under the sender not the receipt owner account.
    /// @param sender The sender to emit receipt information under.
    /// @param account The account to burn a receipt for.
    /// @param id The receipt ID to burn.
    /// @param amount The amount to mint for the `id`.
    /// @param data MUST be emitted as receipt information.
    function ownerBurn(
        address sender,
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    /// The owner MAY directly transfer receipts from and to any account for any
    /// id and amount without restriction. Overflow and underflow MUST revert as
    /// usual for ERC1155.
    /// MUST REVERT if the `msg.sender` is NOT the owner.
    /// @param from The account to transfer from.
    /// @param to The account to transfer to.
    /// @param id The receipt ID
    /// @param amount The amount to transfer between accounts.
    /// @param data The data associated with the transfer as per ERC1155.
    /// MUST NOT be emitted as receipt information.
    function ownerTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    /// Emit a `ReceiptInformation` event for some receipt ID with `data` as the
    /// receipt information. ANY `msg.sender` MAY call this, it is up to offchain
    /// processes/indexers to filter unwanted receipt information before display
    /// and consumption.
    /// @param id The receipt ID this information is for.
    /// @param data The data of the receipt information. MAY be ANY data format
    /// or even malicious/garbage data. The indexer is responsible for filtering
    /// unwanted data.
    function receiptInformation(uint256 id, bytes memory data) external;
}