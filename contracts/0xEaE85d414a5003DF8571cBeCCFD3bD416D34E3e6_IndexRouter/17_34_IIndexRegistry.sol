// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

import "./IIndexFactory.sol";

/// @title Index registry interface
/// @notice Contains core components, addresses and asset market capitalizations
interface IIndexRegistry {
    event SetIndexLogic(address indexed account, address indexLogic);
    event SetMaxComponents(address indexed account, uint maxComponents);
    event UpdateAsset(address indexed asset, uint marketCap);
    event SetOrderer(address indexed account, address orderer);
    event SetFeePool(address indexed account, address feePool);
    event SetPriceOracle(address indexed account, address priceOracle);

    /// @notice Initializes IndexRegistry with the given params
    /// @param _indexLogic Index logic address
    /// @param _maxComponents Maximum assets for an index
    function initialize(address _indexLogic, uint _maxComponents) external;

    /// @notice Sets maximum assets for an index
    /// @param _maxComponents Maximum assets for an index
    function setMaxComponents(uint _maxComponents) external;

    /// @notice Index logic address
    /// @return Returns index logic address
    function indexLogic() external returns (address);

    /// @notice Sets index logic address
    /// @param _indexLogic Index logic address
    function setIndexLogic(address _indexLogic) external;

    /// @notice Sets adminRole as role's admin role.
    /// @param _role Role
    /// @param _adminRole AdminRole of given role
    function setRoleAdmin(bytes32 _role, bytes32 _adminRole) external;

    /// @notice Registers new index
    /// @param _index Index address
    /// @param _nameDetails Name details (name and symbol) for provided index
    function registerIndex(address _index, IIndexFactory.NameDetails calldata _nameDetails) external;

    /// @notice Registers asset in the system, updates it's market capitalization and assigns required roles
    /// @param _asset Asset to register
    /// @param _marketCap It's current market capitalization
    function addAsset(address _asset, uint _marketCap) external;

    /// @notice Removes assets from the system
    /// @param _asset Asset to remove
    function removeAsset(address _asset) external;

    /// @notice Updates market capitalization for the given asset
    /// @param _asset Asset address to update market capitalization for
    /// @param _marketCap Market capitalization value
    function updateAssetMarketCap(address _asset, uint _marketCap) external;

    /// @notice Sets price oracle address
    /// @param _priceOracle Price oracle address
    function setPriceOracle(address _priceOracle) external;

    /// @notice Sets orderer address
    /// @param _orderer Orderer address
    function setOrderer(address _orderer) external;

    /// @notice Sets fee pool address
    /// @param _feePool Fee pool address
    function setFeePool(address _feePool) external;

    /// @notice Maximum assets for an index
    /// @return Returns maximum assets for an index
    function maxComponents() external view returns (uint);

    /// @notice Market capitalization of provided asset
    /// @return _asset Returns market capitalization of provided asset
    function marketCapOf(address _asset) external view returns (uint);

    /// @notice Returns total market capitalization of the given assets
    /// @param _assets Assets array to calculate market capitalization of
    /// @return _marketCaps Corresponding capitalizations of the given asset
    /// @return _totalMarketCap Total market capitalization of the given assets
    function marketCapsOf(address[] calldata _assets)
        external
        view
        returns (uint[] memory _marketCaps, uint _totalMarketCap);

    /// @notice Total market capitalization of all registered assets
    /// @return Returns total market capitalization of all registered assets
    function totalMarketCap() external view returns (uint);

    /// @notice Price oracle address
    /// @return Returns price oracle address
    function priceOracle() external view returns (address);

    /// @notice Orderer address
    /// @return Returns orderer address
    function orderer() external view returns (address);

    /// @notice Fee pool address
    /// @return Returns fee pool address
    function feePool() external view returns (address);
}