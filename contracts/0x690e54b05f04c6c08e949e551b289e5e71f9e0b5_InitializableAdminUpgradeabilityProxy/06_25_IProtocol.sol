// SPDX-License-Identifier: No License

pragma solidity ^0.7.3;

/**
 * @dev Protocol contract interface. See {Protocol}.
 * @author crypto-pumpkin@github
 */
interface IProtocol {
  /// @notice emit when a claim against the protocol is accepted
  event ClaimAccepted(uint256 newClaimNonce);

  function getProtocolDetails()
    external view returns (
      bytes32 _name,
      bool _active,
      uint256 _claimNonce,
      uint256 _claimRedeemDelay,
      uint256 _noclaimRedeemDelay,
      address[] memory _collaterals,
      uint48[] memory _expirationTimestamps,
      address[] memory _allCovers,
      address[] memory _allActiveCovers
    );
  function active() external view returns (bool);
  function name() external view returns (bytes32);
  function claimNonce() external view returns (uint256);
  /// @notice delay # of seconds for redeem with accepted claim, redeemCollateral is not affected
  function claimRedeemDelay() external view returns (uint256);
  /// @notice delay # of seconds for redeem without accepted claim, redeemCollateral is not affected
  function noclaimRedeemDelay() external view returns (uint256);
  function activeCovers(uint256 _index) external view returns (address);
  function claimDetails(uint256 _claimNonce) external view returns (uint16 _payoutNumerator, uint16 _payoutDenominator, uint48 _incidentTimestamp, uint48 _timestamp);
  function collateralStatusMap(address _collateral) external view returns (uint8 _status);
  function expirationTimestampMap(uint48 _expirationTimestamp) external view returns (bytes32 _name, uint8 _status);
  function coverMap(address _collateral, uint48 _expirationTimestamp) external view returns (address);

  function collaterals(uint256 _index) external view returns (address);
  function collateralsLength() external view returns (uint256);
  function expirationTimestamps(uint256 _index) external view returns (uint48);
  function expirationTimestampsLength() external view returns (uint256);
  function activeCoversLength() external view returns (uint256);
  function claimsLength() external view returns (uint256);
  function addCover(address _collateral, uint48 _timestamp, uint256 _amount)
    external returns (bool);

  /// @notice access restriction - claimManager
  function enactClaim(uint16 _payoutNumerator, uint16 _payoutDenominator, uint48 _incidentTimestamp, uint256 _protocolNonce) external returns (bool);

  /// @notice access restriction - dev
  function setActive(bool _active) external returns (bool);
  function updateExpirationTimestamp(uint48 _expirationTimestamp, bytes32 _expirationTimestampName, uint8 _status) external returns (bool);
  function updateCollateral(address _collateral, uint8 _status) external returns (bool);

  /// @notice access restriction - governance
  function updateClaimRedeemDelay(uint256 _claimRedeemDelay) external returns (bool);
  function updateNoclaimRedeemDelay(uint256 _noclaimRedeemDelay) external returns (bool);
}