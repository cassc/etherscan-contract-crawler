// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {WithRoles} from "@lib-diamond/src/access/access-control/WithRoles.sol";
import {DEFAULT_ADMIN_ROLE} from "@lib-diamond/src/access/access-control/Roles.sol";
import {GAME_ADMIN_ROLE} from "../types/ponzu/PonzuRoles.sol";

import {PonzuStorage} from "../types/ponzu/PonzuStorage.sol";
import {LibPonzu} from "../libraries/LibPonzu.sol";

import {QRNGStorage} from "../types/qrng/QRNGStorage.sol";
import {IQRNGReceiver} from "@src/interfaces/IQRNGReceiver.sol";
import {LibQRNG} from "../libraries/LibQRNG.sol";
import {WithAirnodeRrp} from "@src/ponzu/libraries/WithAirnodeRrp.sol";

error RequestNotFound(bytes32 requestId);

contract QRNGFacet is WithRoles, IQRNGReceiver, WithAirnodeRrp {
  using Strings for uint256;
  using LibPonzu for PonzuStorage;
  using LibQRNG for QRNGStorage;

  event ReceivedUint256(bytes32 indexed requestId, uint256 response);

  /// @notice Called by the Airnode through the AirnodeRrp contract to
  /// fulfill the request
  /// @dev Note the `onlyAirnodeRrp` modifier. You should only accept RRP
  /// fulfillments from this protocol contract. Also note that only
  /// fulfillments for the requests made by this contract are accepted, and
  /// a request cannot be responded to multiple times.
  /// @param requestId Request ID
  /// @param data ABI-encoded response
  function fulfillUint256(bytes32 requestId, bytes calldata data) external onlyAirnodeRrp {
    QRNGStorage storage ds = LibQRNG.DS();
    PonzuStorage storage ps = LibPonzu.DS();
    if (!ds.expectingRequestWithIdToBeFulfilled[requestId]) revert RequestNotFound(requestId);
    ds.expectingRequestWithIdToBeFulfilled[requestId] = false;
    uint256 qrngUint256 = abi.decode(data, (uint256));

    ps.receiveRandomNumber(qrngUint256);
  }

  function selectWinner() external onlyRole(GAME_ADMIN_ROLE) {
    PonzuStorage storage ps = LibPonzu.DS();
    if (!ps.receivedRandomNumber) revert LibPonzu.NoRandomNumber();
    ps.selectWinner(ps.randomNumber);
  }

  /// @notice Called by the Airnode through the AirnodeRrp contract to
  /// fulfill the request
  /// @param requestId Request ID
  /// @param data ABI-encoded response
  function fulfillUint256Array(bytes32 requestId, bytes calldata data) external onlyAirnodeRrp {
    // NOT IMPLEMENTED
  }

  function closeRoundManually(uint256 randomNumber) external onlyRole(GAME_ADMIN_ROLE) {
    PonzuStorage storage ps = LibPonzu.DS();
    ps.selectWinner(randomNumber);
  }

  function closeRound() external onlyRole(GAME_ADMIN_ROLE) returns (bytes32) {
    QRNGStorage storage qs = LibQRNG.DS();
    return qs.makeRequestUint256();
  }

  function endRoundWithoutWinner() external onlyRole(GAME_ADMIN_ROLE) {
    PonzuStorage storage ps = LibPonzu.DS();
    ps.endRoundWithoutWinner();
  }

  function setRequestParameters(
    address _airnode,
    bytes32 _endpointIdUint256,
    address _sponsorWallet
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    QRNGStorage storage qs = LibQRNG.DS();
    qs.setRequestParameters(_airnode, _endpointIdUint256, _sponsorWallet);
  }

  function getRequestParameters()
    external
    view
    returns (address airnode, bytes32 endpointIdUint256, address sponsorWallet)
  {
    QRNGStorage storage qs = LibQRNG.DS();
    return (qs.airnode, qs.endpointIdUint256, qs.sponsorWallet);
  }

  function expectingRequestWithIdToBeFulfilled(bytes32 requestId) external view returns (bool) {
    QRNGStorage storage ds = LibQRNG.DS();
    return ds.expectingRequestWithIdToBeFulfilled[requestId];
  }
}