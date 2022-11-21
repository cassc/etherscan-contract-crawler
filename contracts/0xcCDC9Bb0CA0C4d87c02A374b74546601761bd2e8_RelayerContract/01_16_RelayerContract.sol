//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./structs/ApprovalsStruct.sol";
import "./interfaces/IAssetStoreFactory.sol";
import "./interfaces/IAssetStore.sol";
import "./interfaces/IMember.sol";
import "./interfaces/IProtocolDirectory.sol";

// Errors
error RelayerOnly(); // Only Relayer is authorized to perform this function

/**
 * @title RelayerContract
 *
 * Logic for communicatiing with the relayer and contract state
 *
 */

contract RelayerContract is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    /// @dev address of the relayer account
    address public relayerAddress;

    /// @dev address ProtocolDirectory location
    address public directoryContract;

    /**
     * @notice onlyRelayer
     * modifier to ensure only the relayer account can make changes
     *
     */
    modifier onlyRelayer() {
        if (msg.sender != relayerAddress) {
            revert RelayerOnly();
        }
        _;
    }

    /**
     * @dev initialize - Initializes the function for Ownable and Reentrancy.
     * @param _directoryContract address of the directory contract
     *
     */
    function initialize(address _directoryContract) public initializer {
        __Context_init_unchained();
        __Ownable_init();
        __ReentrancyGuard_init();

        directoryContract = _directoryContract;
    }

    /**
     * @dev Set Approval Active for a Specific UID
     * @param _uid string identifier of a user on the dApp
     * This function is called by the predetermined relayer account
     * to trigger that a user's will claim period is now active
     *
     */
    function setApprovalActiveForUID(string memory _uid) external onlyRelayer {
        address IAssetStoreFactoryAddress = IProtocolDirectory(
            directoryContract
        ).getAssetStoreFactory();

        address usersAssetStoreAddress = IAssetStoreFactory(
            IAssetStoreFactoryAddress
        ).getAssetStoreAddress(_uid);
        IAssetStore(usersAssetStoreAddress).setApprovalActive(_uid);
    }

    /**
     * @dev transferUnclaimedAssets
     * @param _userUID string identifier of a user across the dApp
     * Triggered by the relayer once it is too late for the beneficiaries to claim
     *
     */
    function transferUnclaimedAssets(string memory _userUID)
        external
        onlyRelayer
    {
        address IAssetStoreFactoryAddress = IProtocolDirectory(
            directoryContract
        ).getAssetStoreFactory();

        address usersAssetStoreAddress = IAssetStoreFactory(
            IAssetStoreFactoryAddress
        ).getAssetStoreAddress(_userUID);

        IAssetStore(usersAssetStoreAddress).transferUnclaimedAssets(_userUID);
    }

    /**
     * @dev setRelayerAddress
     * @param _relayerAddress the new address of the relayerAccount
     * Update the relayerAccount by the owner as needed
     *
     */
    function setRelayerAddress(address _relayerAddress) external onlyOwner {
        relayerAddress = _relayerAddress;
    }

    /**
     * @dev triggerAssetsForCharity
     * since charities cannot claim assets, the relayer will
     * call this function which will allocate assets per the user's
     * will
     * @param _userUID of the user on the dApp
     *
     */
    function triggerAssetsForCharity(string memory _userUID)
        external
        onlyRelayer
    {
        address IAssetStoreFactoryAddress = IProtocolDirectory(
            directoryContract
        ).getAssetStoreFactory();

        address usersAssetStoreAddress = IAssetStoreFactory(
            IAssetStoreFactoryAddress
        ).getAssetStoreAddress(_userUID);

        Approvals[] memory userApprovals = IAssetStore(usersAssetStoreAddress)
            .getApprovals(_userUID);

        for (uint256 i = 0; i < userApprovals.length; i++) {
            if (userApprovals[i].beneficiary.isCharity) {
                IAssetStore(usersAssetStoreAddress).sendAssetsToCharity(
                    userApprovals[i].beneficiary.beneficiaryAddress,
                    _userUID
                );
            }
        }
    }
}