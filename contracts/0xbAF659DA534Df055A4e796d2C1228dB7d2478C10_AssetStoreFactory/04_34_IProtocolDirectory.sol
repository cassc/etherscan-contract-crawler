//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Protocol Directory interface
 *
 * Use this interface in any contract that needs to find
 * the contract location for commonly used Webacy contracts
 *
 */

interface IProtocolDirectory {
    /**
     * @notice event for recording changes of contracts
     *
     */
    event AddressSet(bytes32 contractName, address indexed newContractAddress);

    /**
     * @notice get the address by a bytes32 location id
     * @param _contractName a bytes32 string
     *
     */
    function getAddress(bytes32 _contractName) external returns (address);

    /**
     * @notice setAddress
     * @param _contractName a bytes32 string
     * @param _contractLocation an address of to entrypoint of protocol contract
     *
     */
    function setAddress(bytes32 _contractName, address _contractLocation)
        external
        returns (address);

    /**
     * @notice ssetStoreFactory
     * @return address of protocol contract matching ASSET_STORE_FACTORY value
     *
     */
    function getAssetStoreFactory() external view returns (address);

    /**
     * @notice getMembershipFactory
     * @return address of protocol contract matching MEMBERSHIP_FACTORY value
     *
     */
    function getMembershipFactory() external view returns (address);

    /**
     * @notice getRelayerContract
     * @return address of protocol contract matching RELAYER_CONTRACT value
     *
     */
    function getRelayerContract() external view returns (address);

    /**
     * @notice getMemberContract
     * @return address of protocol contract matching MEMBER_CONTRACT value
     *
     */
    function getMemberContract() external view returns (address);

    /**
     * @notice getBlacklistContract
     * @return address of protocol contract matching BLACKLIST_CONTRACT value
     *
     */
    function getBlacklistContract() external view returns (address);

    /**
     * @notice getWhitelistContract
     * @return address of protocol contract matching WHITELIST_CONTRACT value
     *
     */
    function getWhitelistContract() external view returns (address);

    /**
     * @notice getTransferPool
     * @return address of protocol contract matching TRANSFER_POOL value
     *
     */
    function getTransferPool() external view returns (address);

    /**
     * @dev setAssetStoreFactory
     * @param _contractLocation address of the new contract location
     * @return address of the updated item as a confirmation
     */

    function setAssetStoreFactory(address _contractLocation)
        external
        returns (address);

    /**
     * @dev setMembershipFactory
     * @param _contractLocation address of the new contract location
     * @return address of the updated item as a confirmation
     */

    function setMembershipFactory(address _contractLocation)
        external
        returns (address);

    /**
     * @dev setRelayerContract
     * @param _contractLocation address of the new contract location
     * @return address of the updated item as a confirmation
     */

    function setRelayerContract(address _contractLocation)
        external
        returns (address);

    /**
     * @dev setMemberContract
     * @param _contractLocation address of the new contract location
     * @return address of the updated item as a confirmation
     */

    function setMemberContract(address _contractLocation)
        external
        returns (address);

    /**
     * @dev setBlacklistContract
     * @param _contractLocation address of the new contract location
     * @return address of the updated item as a confirmation
     */

    function setBlacklistContract(address _contractLocation)
        external
        returns (address);

    /**
     * @dev setWhitelistContract
     * @param _contractLocation address of the new contract location
     * @return address of the updated item as a confirmation
     */

    function setWhitelistContract(address _contractLocation)
        external
        returns (address);

    /**
     * @dev setTransferPool
     * @param _contractLocation address of the new contract location
     * @return address of the updated item as a confirmation
     */

    function setTransferPool(address _contractLocation)
        external
        returns (address);
}