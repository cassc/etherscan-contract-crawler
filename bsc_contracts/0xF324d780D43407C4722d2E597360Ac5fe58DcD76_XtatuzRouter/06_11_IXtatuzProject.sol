// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IProperty.sol";

interface IXtatuzProject {

    enum Status {
        AVAILABLE,
        FINISH,
        REFUND,
        UNAVAILABLE
    }

    struct ProjectData {
        uint256 projectId;
        address owner;
        uint256 count;
        uint256 countReserve;
        uint256 value;
        address[] members;
        uint256 startPresale;
        uint256 endPresale;
        Status status;
        address tokenAddress;
        address propertyAddress;
        address presaledAddress;
    }

    function addProjectMember(
        address member_,
        uint256 package_,
        uint256 amount_
    ) external returns(uint256);

    function finishProject() external;

    function claim(address member_) external returns(uint256);

    function refund(address member_) external returns (uint256);

    function setPresalePeriod(uint256 startPresale_, uint256 endPresale_) external;

    function projectStatus() external view returns(Status);

    function minPrice() external returns(uint256);

    function count() external view returns(uint256);

    function countReserve() external view returns(uint256);

    function startPresale() external view returns(uint256);

    function endPresale() external view returns(uint256);

    function tokenAddress() external view returns(address);

    function transferOwnership(address owner) external;

    function multiSigMint(uint256 projectId) external;

    function multiSigBurn(uint256 projectId) external;

    function getProjectData() external view returns(ProjectData memory);

    function checkCanClaim() external view returns(bool);

    function getMemberedPackBonus(address member_) external view returns(uint256);
    
    function getMemberedEarlyBonus(address member_) external view returns(uint256);

    function packageBonus(uint256 package_) external view returns (uint256);

    function earlyBonus() external view returns (uint256);
}