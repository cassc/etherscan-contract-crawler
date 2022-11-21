//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/IProtocolDirectory.sol";

/**
 * @title ProtocolDirectory
 *
 * This contract will serve as the global store of
 * addresses related to the Webacy smart contract suite.
 * With this Directory we can upgrade/change references to contracts
 * and ensure the rest of the suite will be upgraded at the same time.
 *
 *
 */

contract ProtocolDirectory is
    Initializable,
    OwnableUpgradeable,
    IProtocolDirectory
{
    mapping(bytes32 => address) private _addresses;

    bytes32 private constant ASSET_STORE_FACTORY = "ASSET_STORE_FACTORY";
    bytes32 private constant MEMBERSHIP_FACTORY = "MEMBERSHIP_FACTORY";
    bytes32 private constant RELAYER_CONTRACT = "RELAYER_CONTRACT";
    bytes32 private constant MEMBER_CONTRACT = "MEMBER_CONTRACT";
    bytes32 private constant BLACKLIST_CONTRACT = "BLACKLIST_CONTRACT";
    bytes32 private constant WHITELIST_CONTRACT = "WHITELIST_CONTRACT";
    bytes32 private constant TRANSFER_POOL = "TRANSFER_POOL";

    /**
     * @notice initialize function
     *
     * Keeping within the design pattern of the rest of the protocol
     * this contract will also be upgradable and initializable
     *
     */
    function initialize() public initializer {
        __Context_init_unchained();
        __Ownable_init();
    }

    /**
     * @notice getAddress
     * @param _contractName string representing the contract you are looking for
     *
     * Use this function to get the locations of the deployed addresses;
     */
    function getAddress(bytes32 _contractName) public view returns (address) {
        return _addresses[_contractName];
    }

    /**
     * @notice setAddress
     * @param _contractName bytes32 name to lookup the contract
     * @param _contractLocation address of the deployment being referenced
     *
     *
     */
    function setAddress(bytes32 _contractName, address _contractLocation)
        public
        onlyOwner
        returns (address)
    {
        _addresses[_contractName] = _contractLocation;
        return _contractLocation;
    }

    //////////////////////////
    //////Get Functions//////
    /////////////////////////

    /**
     * @notice AssetStoreFactory
     * @return address of protocol contract matching ASSET_STORE_FACTORY value
     *
     */
    function getAssetStoreFactory() external view returns (address) {
        return getAddress(ASSET_STORE_FACTORY);
    }

    /**
     * @notice getMembershipFactory
     * @return address of protocol contract matching MEMBERSHIP_FACTORY value
     *
     */
    function getMembershipFactory() external view returns (address) {
        return getAddress(MEMBERSHIP_FACTORY);
    }

    /**
     * @notice getRelayerContract
     * @return address of protocol contract matching RELAYER_CONTRACT value
     *
     */
    function getRelayerContract() external view returns (address) {
        return getAddress(RELAYER_CONTRACT);
    }

    /**
     * @notice getMemberContract
     * @return address of protocol contract matching MEMBER_CONTRACT value
     *
     */
    function getMemberContract() external view returns (address) {
        return getAddress(MEMBER_CONTRACT);
    }

    /**
     * @notice getBlacklistContract
     * @return address of protocol contract matching BLACKLIST_CONTRACT value
     *
     */
    function getBlacklistContract() external view returns (address) {
        return getAddress(BLACKLIST_CONTRACT);
    }

    /**
     * @notice getWhitelistContract
     * @return address of protocol contract matching WHITELIST_CONTRACT value
     *
     */
    function getWhitelistContract() external view returns (address) {
        return getAddress(WHITELIST_CONTRACT);
    }

    /**
     * @notice getTransferPool
     * @return address of protocol contract matching TRANSFER_POOL value
     *
     */
    function getTransferPool() external view returns (address) {
        return getAddress(TRANSFER_POOL);
    }

    //////////////////////////
    //////Set Functions//////
    /////////////////////////

    /**
     * @dev setAssetStoreFactory
     * @param _contractLocation address of the new contract location
     * @return address of the updated item as a confirmation
     */
    function setAssetStoreFactory(address _contractLocation)
        external
        onlyOwner
        returns (address)
    {
        return setAddress(ASSET_STORE_FACTORY, _contractLocation);
    }

    /**
     * @dev setMembershipFactory
     * @param _contractLocation address of the new contract location
     * @return address of the updated item as a confirmation
     */
    function setMembershipFactory(address _contractLocation)
        external
        onlyOwner
        returns (address)
    {
        return setAddress(MEMBERSHIP_FACTORY, _contractLocation);
    }

    /**
     * @dev setRelayerContract
     * @param _contractLocation address of the new contract location
     * @return address of the updated item as a confirmation
     */
    function setRelayerContract(address _contractLocation)
        external
        onlyOwner
        returns (address)
    {
        return setAddress(RELAYER_CONTRACT, _contractLocation);
    }

    /**
     * @dev setMemberContract
     * @param _contractLocation address of the new contract location
     * @return address of the updated item as a confirmation
     */
    function setMemberContract(address _contractLocation)
        external
        onlyOwner
        returns (address)
    {
        return setAddress(MEMBER_CONTRACT, _contractLocation);
    }

    /**
     * @dev setBlacklistContract
     * @param _contractLocation address of the new contract location
     * @return address of the updated item as a confirmation
     */
    function setBlacklistContract(address _contractLocation)
        external
        onlyOwner
        returns (address)
    {
        return setAddress(BLACKLIST_CONTRACT, _contractLocation);
    }

    /**
     * @dev setWhitelistContract
     * @param _contractLocation address of the new contract location
     * @return address of the updated item as a confirmation
     */
    function setWhitelistContract(address _contractLocation)
        external
        onlyOwner
        returns (address)
    {
        return setAddress(WHITELIST_CONTRACT, _contractLocation);
    }

    /**
     * @dev setTransferPool
     * @param _contractLocation address of the new contract location
     * @return address of the updated item as a confirmation
     */
    function setTransferPool(address _contractLocation)
        external
        onlyOwner
        returns (address)
    {
        return setAddress(TRANSFER_POOL, _contractLocation);
    }

}