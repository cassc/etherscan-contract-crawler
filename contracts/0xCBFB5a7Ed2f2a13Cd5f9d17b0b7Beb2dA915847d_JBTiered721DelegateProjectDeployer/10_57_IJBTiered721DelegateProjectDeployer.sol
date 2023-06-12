// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IJBDirectory } from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBDirectory.sol";
import { IJBProjects } from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBProjects.sol";
import { IJBController3_1 } from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBController3_1.sol";
import { JBProjectMetadata } from "@jbx-protocol/juice-contracts-v3/contracts/structs/JBProjectMetadata.sol";

import { JBDeployTiered721DelegateData } from "../structs/JBDeployTiered721DelegateData.sol";
import { JBLaunchProjectData } from "../structs/JBLaunchProjectData.sol";
import { JBLaunchFundingCyclesData } from "../structs/JBLaunchFundingCyclesData.sol";
import { JBReconfigureFundingCyclesData } from "../structs/JBReconfigureFundingCyclesData.sol";
import { IJBTiered721DelegateDeployer } from "./IJBTiered721DelegateDeployer.sol";

interface IJBTiered721DelegateProjectDeployer {
    function directory() external view returns (IJBDirectory);

    function delegateDeployer() external view returns (IJBTiered721DelegateDeployer);

    function launchProjectFor(
        address owner,
        JBDeployTiered721DelegateData memory deployTiered721DelegateData,
        JBLaunchProjectData memory launchProjectData,
        IJBController3_1 controller
    ) external returns (uint256 projectId);

    function launchFundingCyclesFor(
        uint256 projectId,
        JBDeployTiered721DelegateData memory deployTiered721DelegateData,
        JBLaunchFundingCyclesData memory launchFundingCyclesData,
        IJBController3_1 controller
    ) external returns (uint256 configuration);

    function reconfigureFundingCyclesOf(
        uint256 projectId,
        JBDeployTiered721DelegateData memory deployTiered721DelegateData,
        JBReconfigureFundingCyclesData memory reconfigureFundingCyclesData,
        IJBController3_1 controller
    ) external returns (uint256 configuration);
}