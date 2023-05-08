// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "lib/openzeppelin-contracts/contracts/proxy/Clones.sol";
import "./Memecoin.sol";

error FailedToInitialize();
error TeamAllocationTooHIgh();
error MustProvideLiquidity();

contract MemeFactory {
  address public immutable implementation;

  constructor() {
    Memecoin memecoin = new Memecoin();
    memecoin.initialize("quit","quit",0,msg.sender, 100, 0);
    implementation = address(memecoin);
  }

  function deployMeme(
    string calldata name,
    string calldata sym,
    uint256 totalSupply,
    uint256 teamPercentage,
    uint256 liquidityLockPeriodInSeconds
  ) external payable returns (address tokenAddress) {
    if (teamPercentage > 100) revert TeamAllocationTooHIgh();
    if (teamPercentage != 100 && msg.value == 0) revert MustProvideLiquidity();
    bytes32 salt = keccak256(abi.encodePacked(name));
    tokenAddress = Clones.cloneDeterministic(implementation, salt);
    (bool success, ) = tokenAddress.call{value: msg.value}(
                                                            abi.encodeWithSelector(
                                                              0x0da953bd,
                                                              name,
                                                              sym,
                                                              totalSupply,
                                                              msg.sender,
                                                              teamPercentage,
                                                              liquidityLockPeriodInSeconds
                                                            )
                                                          );

    if (!success) revert FailedToInitialize();
  }
}