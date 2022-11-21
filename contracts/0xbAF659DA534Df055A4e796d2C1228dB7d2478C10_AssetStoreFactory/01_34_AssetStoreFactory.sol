//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

import "../interfaces/IBlacklist.sol";
import "../interfaces/IMembershipFactory.sol";
import "../interfaces/IProtocolDirectory.sol";
import "../structs/MembershipPlansStruct.sol";
import "../AssetsStore.sol";

// Errors

error UserHasAssetStore();
error UserHasNoMembershipContract();

/**
 * @title AssetStoreFactory
 * This contract will deploy AssetStore contracts for users.
 * Users will pass approvals to that contract and this
 * contract will update state with details and track who has
 * which contracts
 *
 *
 */
contract AssetStoreFactory is
    IAssetStoreFactory,
    Initializable,
    OwnableUpgradeable
{
    /// @dev Storing all AssetStore Contract Addresses
    address[] private AssetStoreContractAddresses;

    /// @dev ProtocolDirectory location
    address private directoryContract;

    /// @dev Mapping User to a Specific Contract Address
    mapping(string => address) private UserToAssetStoreContract;

    /**
     * @dev event AssetStoreCreated
     * @param user address the AssetStore was deployed on behalf of
     * @param assetStoreAddress address of the dpeloyed contract
     * @param uid string identifier for the user across the dApp
     *
     */
    event AssetStoreCreated(
        address user,
        address assetStoreAddress,
        string uid
    );

    address private assetStoreImplementation;

    /**
     * @dev initialize - Initializes the function for Ownable and Reentrancy.
     * @param _directoryContract - to the protocol directory contract
     *
     */
    function initialize(address _directoryContract) public initializer {
        __Context_init_unchained();
        __Ownable_init();
        directoryContract = _directoryContract;
        assetStoreImplementation = address(new AssetsStore());
    }

    /**
     * @dev Function to deployAssetStore for each user
     * @param _uid string identifier of the user across the dApp
     * @param _user address of the user deploying the AssetStore
     *
     */
    function deployAssetStore(string memory _uid, address _user) external {
        address IBlacklistUsersAddress = IProtocolDirectory(directoryContract)
            .getBlacklistContract();
        IBlacklist(IBlacklistUsersAddress).checkIfAddressIsBlacklisted(_user);
        address _userAddress = UserToAssetStoreContract[_uid];
        if (_userAddress != address(0)) {
            revert UserHasAssetStore();
        }

        IMember(IProtocolDirectory(directoryContract).getMemberContract())
            .checkUIDofSender(_uid, _user);
        address IMembershipFactoryAddress = IProtocolDirectory(
            directoryContract
        ).getMembershipFactory();
        IMembershipFactory _membershipFactory = IMembershipFactory(
            IMembershipFactoryAddress
        );
        if (_membershipFactory.getUserMembershipAddress(_uid) == address(0)) {
            revert UserHasNoMembershipContract();
        }
        address _membershipAddress = _membershipFactory
            .getUserMembershipAddress(_uid);
        address assetStoreClone = Clones.clone(assetStoreImplementation);
        AssetsStore(assetStoreClone).initialize(
            directoryContract,
            _membershipAddress
        );
        AssetStoreContractAddresses.push(assetStoreClone);
        UserToAssetStoreContract[_uid] = assetStoreClone;

        emit AssetStoreCreated(_user, assetStoreClone, _uid);
    }

    /**
     * @dev Function to return assetStore Address of a specific user
     * @param _uid string identifier for the user across the dApp
     * @return address of the AssetStore for given user
     */
    function getAssetStoreAddress(string memory _uid)
        external
        view
        returns (address)
    {
        return UserToAssetStoreContract[_uid];
    }
}