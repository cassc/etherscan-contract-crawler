// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract CarbonProject is Ownable {
    struct ProjectInfo {
        uint256 projectId;
        string projectName;
        string orgName;
        string location;
        string documentUrl;
    }
    mapping (uint256 => ProjectInfo) public projectInfos;

    function saveProjectInfo(uint256 projectId, string calldata projectName, string calldata orgName, string calldata location, string calldata documentUrl) external onlyOwner {
        require(projectInfos[projectId].projectId == 0, "The projectId is existed.");

        ProjectInfo memory projectInfo = ProjectInfo(
            projectId,
            projectName,
            orgName,
            location,
            documentUrl
        );
        projectInfos[projectId] = projectInfo;
    }
}