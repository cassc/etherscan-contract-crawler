// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "@forge-std/Script.sol";
import {AaveGovernanceV2, IExecutorWithTimelock} from "@aave-address-book/AaveGovernanceV2.sol";

library DeployMainnetProposal {
    function _deployMainnetMultiProposals(address[] memory payloads, bytes32 ipfsHash)
        internal
        returns (uint256 proposalId)
    {
        require(ipfsHash != bytes32(0), "ERROR: IPFS_HASH can't be bytes32(0)");

        address[] memory targets = new address[](payloads.length);
        uint256[] memory values = new uint256[](payloads.length);
        string[] memory signatures = new string[](payloads.length);
        bytes[] memory calldatas = new bytes[](payloads.length);
        bool[] memory withDelegatecalls = new bool[](payloads.length);

        for (uint256 i = 0; i < payloads.length; i++) {
            require(payloads[i] != address(0), "ERROR: PAYLOAD can't be address(0)");
            targets[i] = payloads[i];
            values[i] = 0;
            signatures[i] = "execute()";
            calldatas[i] = "";
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

contract DeployProposal {
    function run() public {
        address[] memory payloads = new address[](2);
        payloads[0] = 0xeca5bdf0C2b352cBE2D9A19b555E1EC269d4765C; //USDC
        payloads[1] = 0x60bCd1CaF97c3fCbC35Bf92A8852728420C34FB5; //DAI
        DeployMainnetProposal._deployMainnetMultiProposals(
            payloads,
            0x92596c371b9f45caf0389154f37aa9ab679acdf2763c4ece366615345ba14cbf
        );
    }
}