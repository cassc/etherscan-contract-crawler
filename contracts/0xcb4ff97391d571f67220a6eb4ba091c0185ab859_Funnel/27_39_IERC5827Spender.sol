// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title IERC5827Spender defines a callback function that is called when renewable allowance is approved
/// @author Zlace
/// @notice This interface must be implemented if the spender contract wants to react to an renewable approval
/// @dev Allow transfer/approval call chaining inspired by https://eips.ethereum.org/EIPS/eip-1363
interface IERC5827Spender {
    /// Note: the ERC-165 identifier for this interface is 0xb868618d.
    /// 0xb868618d === bytes4(keccak256("onRenewableApprovalReceived(address,uint256,uint256,bytes)"))

    /// @notice Handle the approval of IERC5827Payable tokens
    /// @dev IERC5827Payable calls this function on the recipient
    /// after an `approve`. This function MAY throw to revert and reject the
    /// approval. Return of other than the magic value MUST result in the
    /// transaction being reverted.
    /// Note: the token contract address is always the message sender.
    /// @param owner address owner of the funds
    /// @param amount uint256 The initial and maximum amount of tokens to be spent
    /// @param recoveryRate uint256 amount recovered per second
    /// @param data bytes Additional data with no specified format
    /// @return `bytes4(keccak256("onRenewableApprovalReceived(address,uint256,uint256,bytes)"))`
    ///  unless throwing
    function onRenewableApprovalReceived(
        address owner,
        uint256 amount,
        uint256 recoveryRate,
        bytes memory data
    ) external returns (bytes4);
}