// SPDX-License-Identifier: Unlisenced
// Developed by: dxsoftware.net

import "@openzeppelin/contracts/access/Ownable.sol";
import "../structs/KickstarterInfo.sol";
import "./SummitKickstarter.sol";

pragma solidity ^0.8.6;

contract SummitKickstarterFactory is Ownable {
  mapping(address => bool) public isAdmin;
  mapping(address => address[]) public userProjects;

  address[] public projects;

  uint256 public serviceFee;

  event ProjectCreated(address kickstarterAddress, Kickstarter kickstarter);

  constructor(uint256 _serviceFee) {
    serviceFee = _serviceFee;
  }

  receive() external payable {}

  modifier onlyAdminOrOwner() {
    require(isAdmin[msg.sender] || msg.sender == owner(), "Only admin or owner can call this function");
    _;
  }

  function createProject(Kickstarter calldata _kickstarter) external payable {
    require(msg.value >= serviceFee, "Service Fee is not enough");
    refundExcessiveFee();

    SummitKickstarter project = new SummitKickstarter(msg.sender, _kickstarter);

    address projectAddress = address(project);

    projects.push(projectAddress);
    userProjects[_msgSender()].push(projectAddress);

    emit ProjectCreated(projectAddress, _kickstarter);
  }

  function getProjects() external view returns (address[] memory) {
    return projects;
  }

  function getProjectsOf(address _walletAddress) external view returns (address[] memory) {
    return userProjects[_walletAddress];
  }

  function refundExcessiveFee() internal virtual {
    uint256 refund = msg.value - serviceFee;
    if (refund > 0) {
      (bool success, ) = address(_msgSender()).call{value: refund}("");
      require(success, "Unable to refund excess Ether");
    }
  }

  // ** OWNER FUNCTIONS **

  function setAdmins(address[] calldata _walletAddress, bool _isAdmin) external onlyOwner {
    for (uint256 i = 0; i < _walletAddress.length; i++) {
      isAdmin[_walletAddress[i]] = _isAdmin;
    }
  }

  function withdraw(address _receiver) external onlyOwner {
    (bool success, ) = address(_receiver).call{value: address(this).balance}("");
    require(success, "Unable to withdraw Ether");
  }

  // ** OWNER AND ADMIN FUNCTIONS **

  function setServiceFee(uint256 _serviceFee) external onlyAdminOrOwner {
    serviceFee = _serviceFee;
  }
}