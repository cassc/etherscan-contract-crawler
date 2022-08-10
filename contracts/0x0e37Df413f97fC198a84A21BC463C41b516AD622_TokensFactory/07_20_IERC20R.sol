// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @dev This interface stands for "ERC20 Reversed",
/// in the sense that the recipient of a transfer needs to approve the transfer amount first
interface IERC20R is IERC20 {
    /// @dev Emitted when the allowance of a `_receiver` for an `_owner` is set by
    /// a call to {changeReceiveApproval}. `value` is the new allowance.
    /// @param _owner previous owner of the debt
    /// @param _receiver wallet that received debt
    /// @param _value amount of token transferred
    event ReceiveApproval(address indexed _owner, address indexed _receiver, uint256 _value);

    /// @dev Atomically decreases the receive allowance granted to `owner` by the caller.
    /// This is an alternative to {receive approve} that can be used as a mitigation for problems
    /// described in {IERC20-approve}.
    /// Emits an {ReceiveApproval} event indicating the updated receive allowance.
    /// @param _owner owner of debt token that is being allowed sending it to the caller
    /// @param _subtractedValue amount of token to decrease allowance
    function decreaseReceiveAllowance(address _owner, uint256 _subtractedValue) external;

    /// @dev Atomically increases the receive allowance granted to `owner` by the caller.
    /// This is an alternative to {receive approve} that can be used as a mitigation for problems
    /// described in {IERC20-approve}.
    /// Emits an {ReceiveApproval} event indicating the updated receive allowance.
    /// @param _owner owner of debt token that is being allowed sending it to the caller
    /// @param _addedValue amount of token to increase allowance
    function increaseReceiveAllowance(address _owner, uint256 _addedValue) external;

    /// @dev Sets `_amount` as the allowance of `spender` over the caller's tokens.
    /// Returns a boolean value indicating whether the operation succeeded.
    /// IMPORTANT: Beware that changing an allowance with this method brings the risk
    /// that someone may use both the old and the new allowance by unfortunate
    /// transaction ordering. One possible solution to mitigate this race
    /// condition is to first reduce the spender's allowance to 0 and set the
    /// desired value afterwards:
    /// https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    /// OR use increase/decrease approval method instead.
    /// Emits an {ReceiveApproval} event.
    /// @param _owner owner of debt token that is being allowed sending it to the caller
    /// @param _amount amount of token allowance
    function setReceiveApproval(address _owner, uint256 _amount) external;

    /// @dev Returns the remaining number of tokens that `_owner` is allowed to send to `_receiver`
    /// through {transferFrom}. This is zero by default.
    /// @param _owner owner of debt token
    /// @param _receiver wallet that is receiving debt tokens
    /// @return current token allowance
    function receiveAllowance(address _owner, address _receiver) external view returns (uint256);
}