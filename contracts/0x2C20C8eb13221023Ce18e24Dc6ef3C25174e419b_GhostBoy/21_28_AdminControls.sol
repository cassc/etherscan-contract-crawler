// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Recoverable.sol";

abstract contract AdminControls is Recoverable, AccessControl {
  using Address for address payable;
  uint256 public mintStart;
  uint256 public ghostlistDuration = 1 days;
  bytes32 public ghostlistRoot = 0x0000000000000000000000000000000000000000000000000000000000000000;

  bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
  bytes32 public constant DOMAIN_SETTER_ROLE = keccak256("DOMAIN_SETTER_ROLE");
  bytes32 public constant LIST_SETTER_ROLE = keccak256("LIST_SETTER_ROLE");

  event UpdateGhostlistRoot(bytes32 root);
  event UpdateGhostlistDuration(uint256 durationSeconds);
  event UpdateMintStart(uint256 startTime);

  /**
   * set the ghostslist root
   * @param _ghostlistRoot the ghostlist root to check proofs against
   * @notice only available to owner of the contract
   */
  function setGhostlistRoot(bytes32 _ghostlistRoot) public onlyRole(LIST_SETTER_ROLE) {
    if (ghostlistRoot == _ghostlistRoot) {
      return;
    }
    ghostlistRoot = _ghostlistRoot;
    emit UpdateGhostlistRoot(_ghostlistRoot);
  }
  /**
   * set the duration of the ghostlist window
   * @param _ghostlistDuration the amount of time that the ghostlist should be open
   * @notice only available to owner of the contract
   */
  function setGhostlistDuration(uint256 _ghostlistDuration) public onlyRole(MANAGER_ROLE) {
    if (ghostlistDuration == _ghostlistDuration) {
      return;
    }
    ghostlistDuration = _ghostlistDuration;
    emit UpdateGhostlistDuration(_ghostlistDuration);
  }
  /**
   * set the mint start time
   * @param _mintStart the new mint start time in seconds
   * @notice only available to owner of the contract
   */
  function setMintStart(uint256 _mintStart) public onlyRole(MANAGER_ROLE) {
    if (mintStart == _mintStart) {
      return;
    }
    mintStart = _mintStart;
    emit UpdateMintStart(_mintStart);
  }
  /**
   * recovers any erc20 token that has accidentaly been sent to the contract
   * @param tokenId the token id to interact with
   * @param recipient the recipient of the tokens
   * @param amount the amount of tokens to send
   * @notice only available to owner of the contract
   */
  function recoverERC20(
    address tokenId,
    address recipient,
    uint256 amount
  ) public onlyRole(MANAGER_ROLE) {
    _recoverERC20(tokenId, recipient, amount);
  }
  /**
   * this method allows the owner to withdraw funds
   * paid to the contract during mint
   */
  function withdraw() external onlyRole(MANAGER_ROLE) {
    payable(msg.sender).sendValue(address(this).balance);
  }
  /**
   * looks for a method to check for compatability
   * @param interfaceId the method to look for
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl) returns(bool) {
    return super.supportsInterface(interfaceId);
  }
}