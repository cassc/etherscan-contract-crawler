// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.13;
import "./Interfaces.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IOptionsVaultERC20.sol";

interface IOptionsVaultFactory {
  function COLLATERAL_RATIO_ROLE (  ) external view returns ( bytes32 );
  function CREATE_VAULT_ROLE (  ) external view returns ( bytes32 );
  function DEFAULT_ADMIN_ROLE (  ) external view returns ( bytes32 );
  function collateralTokenIsPermissionless (  ) external view returns ( IStructs.BoolState );
  function collateralTokenWhitelisted ( IERC20 ) external view returns ( bool );
  function collateralizationRatio ( address ) external view returns ( uint256 );
  function createVault ( IOracle _oracle, IERC20 _collateralToken, IFeeCalcs _vaultFeeCalc ) external returns ( address );
  function createVaultIsPermissionless (  ) external view returns ( IStructs.BoolState );
  function getCollateralizationRatio ( IOptionsVaultERC20 _address ) external view returns ( uint256 );
  function getRoleAdmin ( bytes32 role ) external view returns ( bytes32 );
  function grantRole ( bytes32 role, address account ) external;
  function hasRole ( bytes32 role, address account ) external view returns ( bool );
  function initialize ( address _optionsContract ) external;
  function optionVaultERC20Implementation (  ) external view returns ( address );
  function optionsContract (  ) external view returns ( address );
  function oracleIsPermissionless (  ) external view returns ( IStructs.BoolState );
  function oracleWhitelisted ( IOracle ) external view returns ( bool );
  function renounceRole ( bytes32 role, address account ) external;
  function revokeRole ( bytes32 role, address account ) external;
  function setCollateralTokenIsPermissionlessImmutable ( uint8 _value ) external;
  function setCollateralTokenWhitelisted ( IERC20 _collateralToken, bool _value ) external;
  function setCollateralizationRatio ( IOptionsVaultERC20 _address, uint256 _ratio ) external;
  function setCollateralizationRatioBulk ( IOptionsVaultERC20[] calldata _address, uint256[] calldata _ratio ) external;
  function setCreateVaultIsPermissionlessImmutable (  ) external;
  function setOracleIsPermissionlessImmutable ( uint8 _value ) external;
  function setOracleWhitelisted ( IOracle _oracle, bool _value ) external;
  function supportsInterface ( bytes4 interfaceId ) external view returns ( bool );
  function vaultId ( address ) external view returns ( uint256 );
  function vaults ( uint256 ) external view returns ( IOptionsVaultERC20 );
  function vaultsLength (  ) external view returns ( uint256 );
}