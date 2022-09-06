// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../utils/IndexedMapping.sol";
import "./MembersInterface.sol";

/// @title AMKT Members
/// @author Alongside Finance
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details
contract Members is MembersInterface, Ownable {
    ///=============================================================================================
    /// Events
    ///=============================================================================================

    event FactoryAdminSet(address indexed factoryAdmin);
    event CustodianSet(address indexed custodian);
    event MerchantAdd(address indexed merchant);
    event MerchantRemove(address indexed merchant);

    ///=============================================================================================
    /// State Variables
    ///=============================================================================================

    using IndexedMapping for IndexedMapping.Data;

    address public factoryAdmin;

    address public custodian;

    IndexedMapping.Data internal merchants;

    ///=============================================================================================
    /// Constructor
    ///=============================================================================================

    constructor(address newOwner) {
        require(newOwner != address(0), "invalid newOnwer address");
        transferOwnership(newOwner);
    }

    ///=============================================================================================
    /// Setters
    ///=============================================================================================

    /// @notice Allows the owner of the contract to set the factoryAdmin
    /// @param _factoryAdmin address
    /// @return bool
    function setFactoryAdmin(address _factoryAdmin)
        external
        override
        onlyOwner
        returns (bool)
    {
        require(_factoryAdmin != address(0), "invalid custodian address");
        factoryAdmin = _factoryAdmin;

        emit FactoryAdminSet(_factoryAdmin);
        return true;
    }

    /// @notice Allows the owner of the contract to set the custodian
    /// @param _custodian address
    /// @return bool
    function setCustodian(address _custodian)
        external
        override
        onlyOwner
        returns (bool)
    {
        require(_custodian != address(0), "invalid custodian address");
        custodian = _custodian;

        emit CustodianSet(_custodian);
        return true;
    }

    /// @notice Allows the owner of the contract to add a merchant
    /// @param merchant address
    /// @return bool
    function addMerchant(address merchant)
        external
        override
        onlyOwner
        returns (bool)
    {
        require(merchant != address(0), "invalid merchant address");
        require(merchants.add(merchant), "merchant add failed");

        emit MerchantAdd(merchant);
        return true;
    }

    /// @notice Allows the owner of the contract to remove a merchant
    /// @param merchant address
    /// @return bool
    function removeMerchant(address merchant)
        external
        override
        onlyOwner
        returns (bool)
    {
        require(merchant != address(0), "invalid merchant address");
        require(merchants.remove(merchant), "merchant remove failed");

        emit MerchantRemove(merchant);
        return true;
    }

    ///=============================================================================================
    /// Non Mutable
    ///=============================================================================================

    function isFactoryAdmin(address addr)
        external
        view
        override
        returns (bool)
    {
        return (addr == factoryAdmin);
    }

    function isCustodian(address addr) external view override returns (bool) {
        return (addr == custodian);
    }

    function isMerchant(address addr) external view override returns (bool) {
        return merchants.exists(addr);
    }

    function getMerchant(uint256 index) external view returns (address) {
        return merchants.getValue(index);
    }

    function getMerchants() external view override returns (address[] memory) {
        return merchants.getValueList();
    }

    function merchantsLength() external view override returns (uint256) {
        return merchants.valueList.length;
    }
}