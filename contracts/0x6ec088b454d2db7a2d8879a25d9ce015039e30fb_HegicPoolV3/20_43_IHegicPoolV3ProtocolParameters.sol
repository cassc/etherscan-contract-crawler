// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../../LotManager/V2/ILotManagerV2.sol';
import '../../IZHegic.sol';

interface IHegicPoolV3ProtocolParameters {
  event MinTokenReservesSet(uint256 minTokenReserves);
  event NAVPremiumSet(uint256 NAVPremium);
  event PremiumSharesSet(uint256 _poolShareOfPremium, uint256 _protocolShareOfPremium);
  event ProtocolNAVPremiumRecipientSet(address _protocolNAVPremiumRecipient);
  event TokenSet(address _token);
  event ZTokenSet(address _zToken);
  event LotManagerSet(address _lotManager);

  // Variable getters
  function NAV_PREMIUM_PRECISION() external returns (uint256);
  function MAX_NAV_PREMIUM() external returns (uint256);

  function minTokenReserves() external returns (uint256);
  function NAVPremium() external returns (uint256);
  function poolShareOfNAVPremium() external returns (uint256);
  function protocolShareOfNAVPremium() external returns (uint256);
  function protocolNAVPremiumRecipient() external returns (address);

  function token() external returns (IERC20);
  function zToken() external returns (IZHegic);
  function lotManager() external returns (ILotManagerV2);

  // Interfaces ot addreses getters
  function getToken() external view returns (address);
  function getZToken() external view returns (address);
  function getLotManager() external view returns (address);

  // Calculated variables
  function unusedUnderlyingBalance() external view returns (uint256);
  function totalUnderlying() external view returns (uint256);
  function getPricePerFullShare() external view returns (uint256);

  // Setters
  function setMinTokenReserves(uint256 _minTokenReserves) external;
  function setNAVPremium(uint256 _NAVPremium) external;
  function setNAVPremiumShares(uint256 _poolShareOfPremium, uint256 _protocolShareOfPremium) external;
  function setProtocolNAVPremiumRecipient(address _protocolNAVPremiumRecipient) external;
  function setToken(address _token) external;
  function setZToken(address _zToken) external;
  function setLotManager(address _lotManager) external;
}