// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.13;
import "./Interfaces.sol";

interface IOptionsERC721 {
  function DEFAULT_ADMIN_ROLE (  ) external view returns ( bytes32 );
  function IsSafeToCreateOption ( IStructs.Fees memory premium_,IStructs.InputParams memory inParams_ ) external returns ( bool );
  function approve ( address to, uint256 tokenId ) external;
  function autoExercisePeriod (  ) external view returns ( uint256 );
  function balanceOf ( address owner ) external view returns ( uint256 );
  function create ( uint256 period, uint256 optionSize, uint256 strike, IStructs.OptionType optionType, uint256 vaultId, address oracle, address referredBy, uint256 maxPremium ) external returns ( uint256 optionID );
  function exercise ( uint256 optionID ) external;
  function factory (  ) external view returns ( address );
  function getApproved ( uint256 tokenId ) external view returns ( address );
  function getFees ( IStructs.Fees memory inParams ) external view returns ( IStructs.Fees memory fees_ );
  function getRoleAdmin ( bytes32 role ) external view returns ( bytes32 );
  function grantRole ( bytes32 role, address account ) external;
  function hasRole ( bytes32 role, address account ) external view returns ( bool );
  function healthCheck (  ) external view returns ( address );
  function isApprovedForAll ( address owner, address operator ) external view returns ( bool );
  function latestAnswer ( address oracle ) external view returns ( uint256 );
  function name (  ) external view returns ( string memory );
  function options ( uint256 ) external view returns ( IStructs.Option memory );
  function ownerOf ( uint256 tokenId ) external view returns ( address );
  function premium ( uint256 period, uint256 optionSize, uint256 strike, IStructs.OptionType optionType, uint256 vaultId, address oracle, address referredBy ) external view returns ( IStructs.Fees memory premium_, IStructs.InputParams memory inParams_ );
  function protocolFee (  ) external view returns ( uint256 );
  function protocolFeeCalcs (  ) external view returns ( address );
  function protocolFeeRecipient (  ) external view returns ( address );
  function referrals (  ) external view returns ( address );
  function renounceRole ( bytes32 role, address account ) external;
  function revokeRole ( bytes32 role, address account ) external;
  function safeTransferFrom ( address from, address to, uint256 tokenId ) external;
  function safeTransferFrom ( address from, address to, uint256 tokenId, bytes calldata data ) external;
  function setApprovalForAll ( address operator, bool approved ) external;
  function setAutoExercisePeriod ( uint256 value ) external;
  function setOptionHealthCheck ( address value ) external;
  function setProtocolFee ( uint256 value ) external;
  function setProtocolFeeCalc ( address value ) external;
  function setProtocolFeeRecipient ( address value ) external;
  function setReferrals ( address value ) external;
  function supportsInterface ( bytes4 interfaceId ) external view returns ( bool );
  function symbol (  ) external view returns ( string memory );
  function tokenURI ( uint256 tokenId ) external view returns ( string memory );
  function transferFrom ( address from, address to, uint256 tokenId ) external;
  function unlock ( uint256 optionID ) external;
  function unlockAll ( uint256[] calldata optionIDs ) external;
}