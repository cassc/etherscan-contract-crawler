// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.13;
import "./Interfaces.sol";

interface IReferrals {
  function CONTRACT_CALLER_ROLE (  ) external view returns ( bytes32 );
  function DEFAULT_ADMIN_ROLE (  ) external view returns ( bytes32 );
  function addReferrer ( address value ) external;
  function blacklisted ( address ) external view returns ( bool );
  function captureReferral ( address holder, address referredByIn ) external returns ( address referredByOut );
  function getReferFee ( IStructs.InputParams memory inParams ) external view returns ( uint256 );
  function getRoleAdmin ( bytes32 role ) external view returns ( bytes32 );
  function grantRole ( bytes32 role, address account ) external;
  function hasRole ( bytes32 role, address account ) external view returns ( bool );
  function referFee (  ) external view returns ( uint256 );
  function referralFeeRecipient (  ) external view returns ( address );
  function referralPeriod (  ) external view returns ( uint256 );
  function referredBy ( address ) external view returns ( address );
  function referredDate ( address ) external view returns ( uint256 );
  function referrerId ( address ) external view returns ( uint256 );
  function referrers ( uint256 ) external view returns ( address );
  function renounceRole ( bytes32 role, address account ) external;
  function revokeRole ( bytes32 role, address account ) external;
  function setBlacklisted ( address value, bool isBlacklisted ) external;
  function setBlacklistedAll ( address[] calldata addresses, bool isBlacklisted ) external;
  function setReferralFeeRecipient ( address value ) external;
  function supportsInterface ( bytes4 interfaceId ) external view returns ( bool );
}