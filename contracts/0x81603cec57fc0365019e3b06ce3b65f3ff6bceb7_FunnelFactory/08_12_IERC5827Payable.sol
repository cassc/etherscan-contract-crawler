// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "openzeppelin-contracts/interfaces/IERC165.sol";

/// @title IERC5827Payable interface
/// @author Zac (zlace0x), zhongfu (zhongfu), Edison (edison0xyz)
interface IERC5827Payable is IERC165 {
    /// Note: the ERC-165 identifier for this interface is 0x3717806a
    /// 0x3717806a ===
    ///   bytes4(keccak256('transferFromAndCall(address,address,uint256,bytes)')) ^
    ///   bytes4(keccak256('approveRenewableAndCall(address,uint256,uint256,bytes)')) ^

    /// @dev Transfer tokens from one address to another and then call IERC1363Receiver `onTransferReceived` on receiver
    /// @param from address The address which you want to send tokens from
    /// @param to address The address which you want to transfer to
    /// @param value uint256 The amount of tokens to be transferred
    /// @param data bytes Additional data with no specified format, sent in call to `to`
    /// @return success true unless throwing
    function transferFromAndCall(
        address from,
        address to,
        uint256 value,
        bytes memory data
    ) external returns (bool success);

    /// @notice Approve renewable allowance for spender and then call `onRenewableApprovalReceived` on IERC5827Spender
    /// @param _spender address The address which will spend the funds
    /// @param _value uint256 The amount of tokens to be spent
    /// @param _recoveryRate period duration in minutes
    /// @param data bytes Additional data with no specified format, sent in call to `spender`
    /// @return true unless throwing
    function approveRenewableAndCall(
        address _spender,
        uint256 _value,
        uint256 _recoveryRate,
        bytes calldata data
    ) external returns (bool);
}