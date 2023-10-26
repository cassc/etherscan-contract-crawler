// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155MetadataURI.sol";

interface IContributionBoard is IERC1155MetadataURI {
    event ManagerUpdated(address indexed manager, bool active);
    event ProjectPosted(uint256 projId);
    event ProjectClosed(uint256 projId);
    event Grant(uint256 projId, uint256 amount);
    event Payed(uint256 projId, address to, uint256 amount);
    event PayedInStream(
        uint256 projId,
        address to,
        uint256 amount,
        uint256 streamId
    );
    event ProjectFunded(uint256 indexed projId, uint256 amount);
    event NewMaxContribution(uint256 _id, uint256 _maxContribution);

    function finalize(uint256 id) external;

    function addProjectFund(uint256 projId, uint256 amount) external;

    function startInitialContributorShareProgram(
        uint256 projectId,
        uint256 _minimumShare,
        uint256 _maxContribution
    ) external;

    function setMaxContribution(uint256 projectId, uint256 maxContribution)
        external;

    function pauseFunding(uint256 projectId) external;

    function resumeFunding(uint256 projectId) external;

    function compensate(
        uint256 projectId,
        address to,
        uint256 amount
    ) external;

    function compensateInStream(
        uint256 projectId,
        address to,
        uint256 amount,
        uint256 period
    ) external;

    function cancelStream(uint256 projectId, uint256 streamId) external;

    function recordContribution(
        address to,
        uint256 id,
        uint256 amount
    ) external;

    function sablier() external view returns (address);

    function project() external view returns (address);

    function projectFund(uint256 projId) external view returns (uint256);

    function totalSupplyOf(uint256 projId) external view returns (uint256);

    function maxSupplyOf(uint256 projId) external view returns (uint256);

    function initialContributorShareProgram(uint256 projId)
        external
        view
        returns (bool);

    function minimumShare(uint256 projId) external view returns (uint256);

    function fundingPaused(uint256 projId) external view returns (bool);

    function finalized(uint256 projId) external view returns (bool);

    function projectOf(uint256 streamId) external view returns (uint256 id);

    function getStreams(uint256 projId)
        external
        view
        returns (uint256[] memory);

    function getContributors(uint256 projId)
        external
        view
        returns (address[] memory);

    function uri(uint256 id) external view override returns (string memory);
}