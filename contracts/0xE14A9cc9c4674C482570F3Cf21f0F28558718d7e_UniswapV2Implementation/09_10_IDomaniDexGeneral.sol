// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;
pragma experimental "ABIEncoderV2";

interface IDomaniDexGeneral {
  struct ReturnValues {
    address inputToken;
    address outputToken;
    uint256 inputAmount;
    uint256 outputAmount;
  }

  struct SwapParams {
    uint256 exactAmount;
    uint256 minOutOrMaxIn;
    bytes extraData;
    bool isNative;
    uint256 expiration;
    address recipient;
  }

  struct Implementation {
    // Address of the implementation of a dex
    address dexAddr;
    // General info (like a router) to be used for the execution of the swaps
    bytes dexInfo;
  }

  event ImplementationRegistered(
    string indexed id,
    address implementationAddr,
    bytes implementationInfo
  );

  event ImplementationRemoved(string indexed id);

  function getImplementation(string calldata identifier)
    external
    view
    returns (Implementation memory);
}