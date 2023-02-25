// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../ManageableUpgradeable.sol";
import "./StudioDeployerStorage.sol";
import "./interfaces/ICollection.sol";
import "./interfaces/IRoles.sol";
import "./interfaces/ITargetInitializer.sol";
import "./libs/Errors.sol";

contract StudioDeployer is
    OwnableUpgradeable,
    ManageableUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    using Clones for address;
    using StudioDeployerStorage for StudioDeployerStorage.Layout;

    event DeployedContract(
        uint256 voucherId,
        address indexed contractAddress,
        address creator
    );

    /// >>>>>>>>>>>>>>>>>>>>>  INITIALIZER  <<<<<<<<<<<<<<<<<<<<<< ///

    function initialize(address admin, address blacklist) public initializer {
        __StudioDeployer_init(admin, blacklist);
    }

    function __StudioDeployer_init(address admin, address blacklist)
        internal
        onlyInitializing
    {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __StudioDeployer_init_unchained(admin, blacklist);
    }

    function __StudioDeployer_init_unchained(address admin, address blacklist)
        internal
        onlyInitializing
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MANAGER_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(MANAGER_ROLE, admin);
        setBlacklist(blacklist);
    }

    /// >>>>>>>>>>>>>>>>>>>>>  PERMISSIONS  <<<<<<<<<<<<<<<<<<<<<< ///

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    /// @notice set address of the minter
    /// @param owner The address of the new owner
    function setOwner(address owner) public onlyOwner {
        transferOwnership(owner);
    }

    /// @notice add a contract manager
    /// @param manager The address of the maanger
    function setManager(address manager) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MANAGER_ROLE, manager);
    }

    /// @notice add a contract manager
    /// @param manager The address of the maanger
    function unsetManager(address manager) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(MANAGER_ROLE, manager);
    }

    /// @notice update the blacklist contract
    /// @param blacklist The address of the blacklist contract
    function setBlacklist(address blacklist)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
        whenNotPaused
    {
        StudioDeployerStorage.Layout storage m = StudioDeployerStorage.layout();
        m.blacklist = IQuantumBlackList(blacklist);
    }

    /// >>>>>>>>>>>>>>>>>>>>>  CONTRACT MANAGEMENT  <<<<<<<<<<<<<<<<<<<<<< ///

    /// @notice Pause contract
    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /// @notice Unpause contract
    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /// >>>>>>>>>>>>>>>>>>>>>  VOUCHER VALIDATION  <<<<<<<<<<<<<<<<<<<<<< ///

    /// @notice internal util to validate authorization vouchers
    /// @param signer signer's address
    /// @param voucherId the voucher id (voucher id)
    /// @param voucherId the voucher id (voucher id)
    /// @param validFrom signature validity period start
    /// @param validPeriod signature validity period duration
    function validateVoucher(
        address signer,
        uint256 voucherId,
        uint256 validFrom,
        uint256 validPeriod
    ) internal view {
        if (signer == address(0) || !hasRole(MANAGER_ROLE, signer))
            revert InvalidAuthorizationSignature();

        if (StudioDeployerStorage.layout().vouchersUsed[voucherId])
            revert VoucherUsed();

        if (block.timestamp <= validFrom)
            revert VoucherNotValidYet(validFrom, block.timestamp);

        if (validPeriod > 0 && block.timestamp > (validFrom + validPeriod))
            revert AuthorizationExpired(
                validFrom + validPeriod,
                block.timestamp
            );
    }

    /// @notice internal util to validate a deployment request
    /// @param deploymentAuth deployment authorization voucher struct:
    /// @param deploymentAuth.id voucher id
    /// @param deploymentAuth.r signature
    /// @param deploymentAuth.s signature
    /// @param deploymentAuth.v signature
    /// @param deploymentAuth.validFrom - signature validity period start
    /// @param deploymentAuth.validPeriod - signature validity period duration
    /// @param deploymentAuth.implementation - The address of the target implementation.
    /// @param deploymentAuth.admin - address to set up as initial admin
    /// @param deploymentAuth.manager - address set up as initial manager
    /// @param deploymentAuth.minter - address authorized to call the mint function
    /// @param deploymentAuth.creator - address set up with creator role
    /// @param deploymentAuth.royaltyFee - Initial setting for royalty fees
    /// @param deploymentAuth.primaryPayoutAddress - Initial setting for royalty payout address

    /// @param data extra calldata encoded as bytes to be passed to the implementation contract (Is included in the hash though)
    modifier validateDeploymentAuth(
        DeploymentAuth calldata deploymentAuth,
        bytes calldata data
    ) {
        bytes32 digest = ECDSA.toEthSignedMessageHash(
            keccak256(
                bytes.concat( //Split into chunks to avoid stack too deep error
                    abi.encodePacked(
                        deploymentAuth.id,
                        deploymentAuth.validFrom,
                        deploymentAuth.validPeriod,
                        deploymentAuth.name,
                        deploymentAuth.symbol,
                        deploymentAuth.implementation
                    ),
                    abi.encodePacked(
                        deploymentAuth.admin,
                        deploymentAuth.manager,
                        deploymentAuth.minter,
                        deploymentAuth.creator,
                        deploymentAuth.royaltyFee,
                        deploymentAuth.royaltySplits,
                        deploymentAuth.royaltyRecipients,
                        data
                    )
                )
            )
        );

        address signer = ECDSA.recover(
            digest,
            deploymentAuth.v,
            deploymentAuth.r,
            deploymentAuth.s
        );

        validateVoucher(
            signer,
            deploymentAuth.id,
            deploymentAuth.validFrom,
            deploymentAuth.validPeriod
        );

        _;
    }

    /// >>>>>>>>>>>>>>>>>>>>>  DEPLOYER  <<<<<<<<<<<<<<<<<<<<<< ///
    /// @notice deploy a new contract
    /// @param name - The metadata name of the contract
    /// @param symbol - The ERC721 symbol
    /// @param deploymentAuth deployment authorization voucher struct:
    /// @param deploymentAuth.id - voucher id
    /// @param deploymentAuth.r - signature
    /// @param deploymentAuth.s - signature
    /// @param deploymentAuth.v - signature
    /// @param deploymentAuth.validFrom - signature validity period start
    /// @param deploymentAuth.validPeriod - signature validity period duration
    /// @param deploymentAuth.implementation - The address of the target implementation.
    /// @param deploymentAuth.admin - address to set up as initial admin
    /// @param deploymentAuth.manager - address set up as initial manager
    /// @param deploymentAuth.minter - address authorized to call the mint function
    /// @param deploymentAuth.creator - address set up with creator role
    /// @param deploymentAuth.royaltyFee - Initial setting for royalty fees
    /// @param deploymentAuth.primaryPayoutAddress - Initial setting for royalty payout address
    /// @param data - extra calldata encoded as bytes to be passed to the implementation contract (Is included in the hash though)
    function deploy(
        string memory name,
        string memory symbol,
        DeploymentAuth calldata deploymentAuth,
        bytes calldata data
    )
        public
        whenNotPaused
        validateDeploymentAuth(deploymentAuth, data)
        returns (address)
    {
        // expire the nonce immediately to avoid re-entrancy
        StudioDeployerStorage.layout().vouchersUsed[deploymentAuth.id] = true;

        for (uint256 i = 0; i < deploymentAuth.royaltyRecipients.length; i++) {
            if (deploymentAuth.royaltyRecipients[i] == address(0))
                revert PayoutZeroAddress();
        }

        ITargetInitializer clone = ITargetInitializer(
            deploymentAuth.implementation.clone()
        );

        clone.initialize(
            name,
            symbol,
            TargetInit(
                deploymentAuth.admin,
                deploymentAuth.manager,
                deploymentAuth.minter,
                deploymentAuth.creator,
                deploymentAuth.royaltyFee,
                deploymentAuth.royaltySplits,
                deploymentAuth.royaltyRecipients
            ),
            data
        );
        emit DeployedContract(
            deploymentAuth.id,
            address(clone),
            deploymentAuth.creator
        );

        return address(clone);
    }

    /// >>>>>>>>>>>>>>>>>>>>>  MANAGE COLLECTION CONTRACTS  <<<<<<<<<<<<<<<<<<<<<< ///

    function batchGrantRole(
        bytes32 role,
        address[] calldata contracts,
        address[] calldata users
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint32 c_idx = 0; c_idx < contracts.length; c_idx++) {
            for (uint8 u_idx = 0; u_idx < users.length; u_idx++) {
                IGrantRole(contracts[c_idx]).grantRole(role, users[u_idx]);
            }
        }
    }

    function batchRevokeRole(
        bytes32 role,
        address[] calldata contracts,
        address[] calldata users
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint32 c_idx = 0; c_idx < contracts.length; c_idx++) {
            for (uint8 u_idx = 0; u_idx < users.length; u_idx++) {
                IRevokeRole(contracts[c_idx]).revokeRole(role, users[u_idx]);
            }
        }
    }

    /// @dev called to change mistaken recipient payout addresses on a single contract
    /// @param collection studio collection address
    /// @param royaltySplits array of arrays of royalty splits in bps
    /// @dev The bps in each array inside the array of royaltySplitsList must add up to total of 10000 (100%).
    /// @param royaltyRecipients array of arrays of addreses that will be the recipients
    function adminSetRecipients(
        address collection,
        uint16[] calldata royaltySplits,
        address payable[] calldata royaltyRecipients
    ) public onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        ISetUpRecipients(collection).setUpRecipients(
            royaltySplits,
            royaltyRecipients
        );
    }

    /// @dev called to change mistaken recipient payout addresses on multiple contracts
    /// @param collections array of studio collection addresses
    /// @param royaltySplitsList array of arrays of royalty splits in bps
    /// @dev The bps in each array inside the array of royaltySplitsList must add up to total of 10000 (100%).
    /// @param royaltyRecipientsList array of arrays of addreses that will be the recipients
    function adminBatchSetRecipients(
        address[] calldata collections,
        uint16[][] calldata royaltySplitsList,
        address payable[][] calldata royaltyRecipientsList
    ) public onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        for (uint32 c_idx = 0; c_idx < collections.length; c_idx++) {
            adminSetRecipients(
                collections[c_idx],
                royaltySplitsList[c_idx],
                royaltyRecipientsList[c_idx]
            );
        }
    }

    /// @notice changes token uri for a given token id on an ERC1155 collection
    /// @param collection The address of the target contract.
    /// @param tokenId Token id to change.
    /// @param newUri The new uri to set.
    function adminERC1155SetUri(
        address collection,
        uint256 tokenId,
        string memory newUri
    ) public onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        IMintEditions targetCollection = IMintEditions(collection);
        targetCollection.setUri(tokenId, newUri);
    }
}

struct DeploymentAuth {
    // basic voucher
    uint256 id;
    bytes32 r;
    bytes32 s;
    uint8 v;
    uint256 validFrom;
    uint256 validPeriod;
    // contract initialization
    bytes name;
    bytes symbol;
    address implementation;
    address admin;
    address manager;
    address minter;
    address creator;
    uint32 royaltyFee; // 0-10000 (in BPS)
    uint16[] royaltySplits; // totaling 10000 (in BPS)
    address payable[] royaltyRecipients;
}