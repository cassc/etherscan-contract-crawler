//SPDX-License-Identifier: MIT
pragma solidity >=0.6.11 <=0.6.12;
pragma experimental ABIEncoderV2;

/**
 *   @title Track addresses to be used in liquidity deployment
 *   Any controller used, asset deployed, or pool tracked within the
 *   system should be registered here
 */
interface IAddressRegistry {
    enum AddressTypes {
        Token,
        Controller,
        Pool
    }

    event RegisteredAddressAdded(address added);
    event RegisteredAddressRemoved(address removed);
    event AddedToRegistry(address[] addresses, AddressTypes);
    event RemovedFromRegistry(address[] addresses, AddressTypes);

    /// @notice Allows address with REGISTERED_ROLE to add a registered address
    /// @param _addr address to be added
    function addRegistrar(address _addr) external;

    /// @notice Allows address with REGISTERED_ROLE to remove a registered address
    /// @param _addr address to be removed
    function removeRegistrar(address _addr) external;

    /// @notice Allows array of addresses to be added to registry for certain index
    /// @param _addresses calldata array of addresses to be added to registry
    /// @param _index AddressTypes enum of index to add addresses to
    function addToRegistry(address[] calldata _addresses, AddressTypes _index) external;

    /// @notice Allows array of addresses to be removed from registry for certain index
    /// @param _addresses calldata array of addresses to be removed from registry
    /// @param _index AddressTypes enum of index to remove addresses from
    function removeFromRegistry(address[] calldata _addresses, AddressTypes _index) external;

    /// @notice Allows array of all addresses for certain index to be returned
    /// @param _index AddressTypes enum of index to be returned
    /// @return address[] memory of addresses from index
    function getAddressForType(AddressTypes _index) external view returns (address[] memory);

    /// @notice Allows checking that one address exists in certain index
    /// @param _addr address to be checked
    /// @param _index AddressTypes index to check address against
    /// @return bool tells whether address exists or not
    function checkAddress(address _addr, uint256 _index) external view returns (bool);

    /// @notice Returns weth address
    /// @return address weth address
    function weth() external view returns (address);

}