// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IJBDirectory } from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBDirectory.sol";

import { JB721GovernanceType } from "../enums/JB721GovernanceType.sol";
import { JBDeployTiered721DelegateData } from "../structs/JBDeployTiered721DelegateData.sol";
import { IJBTiered721Delegate } from "./IJBTiered721Delegate.sol";

interface IJBTiered721DelegateDeployer {
    event DelegateDeployed(
        uint256 indexed projectId,
        IJBTiered721Delegate newDelegate,
        JB721GovernanceType governanceType,
        IJBDirectory directory
    );

    function deployDelegateFor(
        uint256 projectId,
        JBDeployTiered721DelegateData memory deployTieredNFTRewardDelegateData,
        IJBDirectory directory
    ) external returns (IJBTiered721Delegate delegate);
}