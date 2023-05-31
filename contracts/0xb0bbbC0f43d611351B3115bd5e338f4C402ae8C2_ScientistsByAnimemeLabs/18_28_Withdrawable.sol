// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @custom:security-contact [email protected]
abstract contract RojiWithdrawableAccessControl is AccessControl {
    bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");

    /// @notice Fund withdrawal for anyone in the WITHDRAWER_ROLE.
    function withdraw() public onlyRole(WITHDRAWER_ROLE) {
      payable(msg.sender).transfer(address(this).balance); 
    }
}


/// @custom:security-contact [email protected]
abstract contract RojiWithdrawableOwnable is Ownable {

    /// @notice Fund withdrawal for the owner of the contract
    function withdraw() public onlyOwner {
      payable(msg.sender).transfer(address(this).balance); 
    }
}