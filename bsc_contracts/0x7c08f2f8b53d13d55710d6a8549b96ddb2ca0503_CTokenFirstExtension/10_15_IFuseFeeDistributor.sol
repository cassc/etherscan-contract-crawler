// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

interface IFuseFeeDistributor {
  function minBorrowEth() external view returns (uint256);

  function maxSupplyEth() external view returns (uint256);

  function maxUtilizationRate() external view returns (uint256);

  function interestFeeRate() external view returns (uint256);

  function comptrollerImplementationWhitelist(address oldImplementation, address newImplementation)
    external
    view
    returns (bool);

  function pluginImplementationWhitelist(address oldImplementation, address newImplementation)
    external
    view
    returns (bool);

  function cErc20DelegateWhitelist(
    address oldImplementation,
    address newImplementation,
    bool allowResign
  ) external view returns (bool);

  function latestComptrollerImplementation(address oldImplementation) external view returns (address);

  function latestCErc20Delegate(address oldImplementation)
    external
    view
    returns (
      address cErc20Delegate,
      bool allowResign,
      bytes memory becomeImplementationData
    );

  function latestPluginImplementation(address oldImplementation) external view returns (address);

  function getComptrollerExtensions(address comptroller) external view returns (address[] memory);

  function getCErc20DelegateExtensions(address cErc20Delegate) external view returns (address[] memory);

  function deployCErc20(bytes calldata constructorData) external returns (address);

  fallback() external payable;

  receive() external payable;
}