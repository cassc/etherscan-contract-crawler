// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;
import "solady/src/auth/OwnableRoles.sol";
import "./roji-roles.sol";

/// @custom:security-contact [email protected]
abstract contract RojiWithdrawableOwnableRoles is OwnableRoles {
    uint256 public constant ROLE_WITHDRAWER = ROJI_ROLE_WITHDRAWER;

    /// @notice Fund withdrawal for anyone in the WITHDRAWER_ROLE.
    function withdraw() public onlyRoles(ROLE_WITHDRAWER) {
      payable(msg.sender).transfer(address(this).balance); 
    }
}