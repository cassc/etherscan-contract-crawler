pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./TonUtils.sol";


interface BridgeInterface is TonUtils {
  function voteForMinting(SwapData memory data, Signature[] memory signatures) external;
  function voteForNewOracleSet(int oracleSetHash, address[] memory newOracles, Signature[] memory signatures) external;
  function voteForSwitchBurn(bool newBurnStatus, int nonce, Signature[] memory signatures) external;
  event NewOracleSet(int oracleSetHash, address[] newOracles);
}