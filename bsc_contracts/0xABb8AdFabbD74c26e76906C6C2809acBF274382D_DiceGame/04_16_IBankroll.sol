// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IBankroll {
  function addPool ( address token ) external;
  function balanceOf ( address token, address user ) external view returns ( uint256 );
  function clearDebt ( address token, uint256 amount ) external;
  function debtPools ( address ) external view returns ( uint256 );
  function deposit ( address token, uint256 amount ) external;
  function emergencyWithdraw ( address token ) external;
  function getMaxWin ( address token ) external view returns ( uint256 );
  function hasPool ( address token ) external view returns ( bool );
  function isWhitelisted ( address check ) external view returns ( bool );
  function max_win (  ) external view returns ( uint256 );
  function owner (  ) external view returns ( address );
  function payDebt ( address recipient, address token, uint256 amount ) external;
  function pools ( address ) external view returns ( address );
  function removePool ( address token ) external;
  function renounceOwnership (  ) external;
  function reserveDebt ( address token, uint256 amount ) external;
  function reserves ( address token ) external view returns ( uint256 );
  function setMaxWin ( uint256 new_max ) external;
  function setWhitelist ( address a, bool to ) external;
  function transferOwnership ( address newOwner ) external;
  function whitelistContracts ( address ) external view returns ( bool );
  function whitelistedTokens ( address ) external view returns ( bool );
  function withdraw ( address token, uint256 shares ) external;
}