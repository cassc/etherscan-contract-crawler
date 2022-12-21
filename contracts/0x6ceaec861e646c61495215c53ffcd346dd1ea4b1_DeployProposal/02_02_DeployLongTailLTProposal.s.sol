// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AaveGovernanceV2, IExecutorWithTimelock} from "@aave-address-book/AaveGovernanceV2.sol";

library DeployMainnetProposal {
    function _deployMainnetProposal(address payload, bytes32 ipfsHash) internal returns (uint256 proposalId) {
        require(payload != address(0), "ERROR: PAYLOAD can't be address(0)");
        require(ipfsHash != bytes32(0), "ERROR: IPFS_HASH can't be bytes32(0)");
        address[] memory targets = new address[](1);
        targets[0] = payload;
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        string[] memory signatures = new string[](1);
        signatures[0] = "execute()";
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = "";
        bool[] memory withDelegatecalls = new bool[](1);
        withDelegatecalls[0] = true;

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

contract DeployProposal {
    function run() public {
        DeployMainnetProposal._deployMainnetProposal(
            0x33d7385B2BF82b2183aFc66dC84EA5f3F2D240D5, // Long Tail LT
            0x31cc3826fed671c95f9522cdac3cb6b6b9bf75ba311c28e84327729586254eed
        );
    }
}