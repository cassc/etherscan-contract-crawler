// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveGovernanceV2, IExecutorWithTimelock} from 'aave-address-book/AaveGovernanceV2.sol';

library DeployMutliChainProposals {
  function _deployL1Proposal(
    address[] memory payloads,
    address[] memory targets,
    bytes32 ipfsHash
  ) internal returns (uint256 proposalId) {
    require(ipfsHash != bytes32(0), "ERROR: IPFS_HASH can't be 0");
    require(targets.length == payloads.length, 'ERROR: array length mismatch');

    uint256[] memory values = new uint256[](payloads.length);
    string[] memory signatures = new string[](payloads.length);
    bytes[] memory calldatas = new bytes[](payloads.length);
    bool[] memory withDelegatecalls = new bool[](payloads.length);

    for (uint256 i = 0; i < payloads.length; i++) {
      require(payloads[i] != address(0), "ERROR: PAYLOAD can't be address(0)");
      require(targets[i] != address(0), "ERROR: target can't be address(0)");
      values[i] = 0;
      signatures[i] = 'execute(address)';
      calldatas[i] = abi.encode(payloads[i]);
      withDelegatecalls[i] = true;
    }

    return
      AaveGovernanceV2.GOV.create(
        IExecutorWithTimelock(AaveGovernanceV2.SHORT_EXECUTOR),
        targets,
        values,
        signatures,
        calldatas,
        withDelegatecalls,
        ipfsHash
      );
  }
}

contract DeployAllCaps {
  function run() public {
    address[] memory payloads = new address[](5);
    address[] memory targets = new address[](5);

    // Avalanche stewards executed separately:
    // 0xC9df68EdcB0c8fb7Ced82e5836b75c002c723e17 - ava supply caps
    // 0x340a1932dA26E65384235a47fec6E5C86c27da4B - ava borrow caps

    //Borrow caps payloads:
    payloads[0] = 0x280e404338d9d8e50B11D6677B9C91BA86E0FD22; // opt borrow caps
    targets[0] = AaveGovernanceV2.CROSSCHAIN_FORWARDER_OPTIMISM;

    payloads[1] = 0x691B41805f7Ef2D7De6165bC42295b035a31600D; // arb borrow caps
    targets[1] = AaveGovernanceV2.CROSSCHAIN_FORWARDER_ARBITRUM;

    payloads[2] = 0x691B41805f7Ef2D7De6165bC42295b035a31600D; // poly borrow caps
    targets[2] = AaveGovernanceV2.CROSSCHAIN_FORWARDER_POLYGON;

    //Supply caps payloads:
    payloads[3] = 0x691B41805f7Ef2D7De6165bC42295b035a31600D; // opt supply caps
    targets[3] = AaveGovernanceV2.CROSSCHAIN_FORWARDER_OPTIMISM;

    payloads[4] = 0xC9df68EdcB0c8fb7Ced82e5836b75c002c723e17; // arb supply caps
    targets[4] = AaveGovernanceV2.CROSSCHAIN_FORWARDER_ARBITRUM;

    DeployMutliChainProposals._deployL1Proposal(
      payloads,
      targets,
      0x366f499db7fed9b542e614e587312e417b6d8add2fc83840745781f5a70567b1
    );
  }
}