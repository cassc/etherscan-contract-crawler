// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

import "./interfaces/ITaggr.sol";
import "./interfaces/ITaggrSettings.sol";
import "./lib/BlackholePrevention.sol";


contract TaggrSettings is
  ITaggrSettings,
  Initializable,
  AccessControlEnumerableUpgradeable,
  BlackholePrevention
{
  bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

  address internal membershipFeeToken;
  address internal projectLaunchFeeToken;

  uint256 internal membershipFee;
  uint256 internal projectLaunchFee;

  mapping (uint256 => bool) internal _activePlanTypes;
  mapping (uint256 => uint256) internal _mintingFeesByPlanType;


  /***********************************|
  |          Initialization           |
  |__________________________________*/

  function initialize(address initiator) public initializer {
    __AccessControlEnumerable_init();

    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(OWNER_ROLE, _msgSender());

    emit ContractReady(initiator);
  }


  /***********************************|
  |         Public Functions          |
  |__________________________________*/

  function isActivePlanType(uint256 planType) external view override returns (bool) {
    return _activePlanTypes[planType];
  }

  function getMembershipFee() external view override returns (uint256) {
    return membershipFee;
  }

  function getProjectLaunchFee() external view override returns (uint256) {
    return projectLaunchFee;
  }

  function getMembershipFeeToken() external view override returns (address) {
    return membershipFeeToken;
  }

  function getProjectLaunchFeeToken() external view override returns (address) {
    return projectLaunchFeeToken;
  }

  function getMintingFeeByPlanType(uint256 planType) external view override returns (uint256) {
    return _mintingFeesByPlanType[planType];
  }


  /***********************************|
  |       Permissioned Controls       |
  |__________________________________*/

  function setMembershipFee(uint256 fee) external onlyRole(OWNER_ROLE) {
    membershipFee = fee;
    emit MembershipFeeSet(fee);
  }

  function setProjectLaunchFee(uint256 fee) external onlyRole(OWNER_ROLE) {
    projectLaunchFee = fee;
    emit ProjectLaunchFeeSet(fee);
  }

  function setMembershipFeeToken(address feeToken) external onlyRole(OWNER_ROLE) {
    require(feeToken != address(0), "TS:E-103");
    membershipFeeToken = feeToken;
    emit MembershipFeeTokenSet(feeToken);
  }

  function setProjectLaunchFeeToken(address feeToken) external onlyRole(OWNER_ROLE) {
    require(feeToken != address(0), "TS:E-103");
    projectLaunchFeeToken = feeToken;
    emit ProjectLaunchFeeTokenSet(feeToken);
  }

  function setMintingFeeByPlanType(uint256 planType, uint256 fee) external onlyRole(OWNER_ROLE) {
    _mintingFeesByPlanType[planType] = fee;
    _activePlanTypes[planType] = true;
    emit MintingFeesByPlanTypeSet(planType, fee);
  }

  function togglePlanType(uint256 planType, bool isActive) external onlyRole(OWNER_ROLE) {
    _activePlanTypes[planType] = isActive;
    emit PlanTypeToggle(planType, isActive);
  }


  /***********************************|
  |            Only Owner             |
  |      (blackhole prevention)       |
  |__________________________________*/

  function withdrawEther(address payable receiver, uint256 amount) external onlyRole(OWNER_ROLE) {
    _withdrawEther(receiver, amount);
  }

  function withdrawErc20(address payable receiver, address tokenAddress, uint256 amount) external onlyRole(OWNER_ROLE) {
    _withdrawERC20(receiver, tokenAddress, amount);
  }

  function withdrawERC721(address payable receiver, address tokenAddress, uint256 tokenId) external onlyRole(OWNER_ROLE) {
    _withdrawERC721(receiver, tokenAddress, tokenId);
  }

  function withdrawERC1155(address payable receiver, address tokenAddress, uint256 tokenId, uint256 amount) external onlyRole(OWNER_ROLE) {
    _withdrawERC1155(receiver, tokenAddress, tokenId, amount);
  }


  /***********************************|
  |         Private/Internal          |
  |__________________________________*/

}