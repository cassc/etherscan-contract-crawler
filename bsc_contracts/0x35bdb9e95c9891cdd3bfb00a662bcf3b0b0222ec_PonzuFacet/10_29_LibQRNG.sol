// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IAirnodeRrpV0} from "@api3/airnode-protocol/contracts/rrp/interfaces/IAirnodeRrpV0.sol";

import {QRNGStorage} from "../types/qrng/QRNGStorage.sol";
import {IQRNGReceiver} from "@src/interfaces/IQRNGReceiver.sol";

import {LibPonzu} from "./LibPonzu.sol";
import {PonzuStorage} from "../types/ponzu/PonzuStorage.sol";

abstract contract WithAirnodeRrp {
  modifier onlyAirnodeRrp() {
    require(msg.sender == LibQRNG.DS().airnodeRrp, "Only AirnodeRrp");
    _;
  }
}

library LibQRNG {
  using LibPonzu for PonzuStorage;

  bytes32 internal constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.qrng.storage");

  function DS() internal pure returns (QRNGStorage storage ds) {
    bytes32 position = DIAMOND_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }

  /// @notice Requests a `uint256`
  /// @dev This request will be fulfilled by the contract's sponsor wallet,
  /// which means spamming it may drain the sponsor wallet. Implement
  /// necessary requirements to prevent this, e.g., you can require the user
  /// to pitch in by sending some ETH to the sponsor wallet, you can have
  /// the user use their own sponsor wallet, you can rate-limit users.
  function makeRequestUint256(QRNGStorage storage ds) internal returns (bytes32 requestId) {
    PonzuStorage storage ps = LibPonzu.DS();

    // If there are no valid deposits, then just end the round;
    uint256 totalValidDeposits = ps.totalDeposited;
    if (totalValidDeposits == 0) ps.endRoundWithoutWinner();
    else {
      // otherwise, request a random number
      requestId = IAirnodeRrpV0(ds.airnodeRrp).makeFullRequest(
        ds.airnode,
        ds.endpointIdUint256,
        address(this),
        ds.sponsorWallet,
        address(this),
        IQRNGReceiver.fulfillUint256.selector,
        ""
      );
      ds.expectingRequestWithIdToBeFulfilled[requestId] = true;
    }
  }

  /// @notice Sets parameters used in requesting QRNG services
  /// @dev No access control is implemented here for convenience. This is not
  /// secure because it allows the contract to be pointed to an arbitrary
  /// Airnode. Normally, this function should only be callable by the "owner"
  /// or not exist in the first place.
  /// @param _airnode Airnode address
  /// @param _endpointIdUint256 Endpoint ID used to request a `uint256`
  /// @param _sponsorWallet Sponsor wallet address
  function setRequestParameters(
    QRNGStorage storage ds,
    address _airnode,
    bytes32 _endpointIdUint256,
    address _sponsorWallet
  ) internal {
    // Normally, this function should be protected, as in:
    // require(msg.sender == owner, "Sender not owner");
    ds.airnode = _airnode;
    ds.endpointIdUint256 = _endpointIdUint256;
    ds.sponsorWallet = _sponsorWallet;
  }
}